module Main where

import Prelude

import Cache as Cache
import Control.Monad.Except (ExceptT(..), runExceptT)
import Control.Parallel (parTraverse, parTraverse_)
import Data.Array (catMaybes, filter, find, foldl, sortBy, take)
import Data.Array as Array
import Data.Either (Either(..))
import Data.Int (fromString)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (Pattern(..), Replacement(..), contains, joinWith, replaceAll, split)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff (Aff, Error, launchAff_, try)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Node.Buffer (Buffer)
import Node.ChildProcess (defaultExecSyncOptions, execSync)
import Node.Encoding (Encoding(..))
import Node.FS.Aff (readTextFile, readdir, writeTextFile)
import Prelude as Maybe
import RssGenerator as Rss
import Utils (FormattedMarkdownData, archiveTemplate, blogpostTemplate, createFolderIfNotPresent, formatDate, getCategoriesJson, homepageTemplate, htmlOutputFolder, md2FormattedData, rawContentsFolder, templatesFolder, tmpFolder)
import Utils as U

main :: Effect Unit
main =
    launchAff_
        $ do
              res <- runExceptT buildSite
              _ <- try $ liftEffect $ execSync ("rm -rf " <> tmpFolder) defaultExecSyncOptions
              case res of
                  Left err -> do
                      log $ show err
                  Right _ -> log "Done."

newtype Template = Template String

readFileToData :: String -> ExceptT Error Aff FormattedMarkdownData
readFileToData filePath = do
    contents <- ExceptT $ try $ readTextFile UTF8 filePath
    pure $ md2FormattedData contents

writeHTMLFile :: Template -> FormattedMarkdownData -> ExceptT Error Aff Unit
writeHTMLFile template pd@{ frontMatter } =
    ExceptT
        $ do
              res <- try $ writeTextFile UTF8 (tmpFolder <> "/" <> frontMatter.slug <> ".html") (replaceContentInTemplate template pd)
              _ <- case res of
                  Left err -> log $ "Could not write " <> frontMatter.slug <> ".md to html (" <> show err <> ")"
                  Right _ -> log $ rawContentsFolder <> "/" <> frontMatter.slug <> ".md -> " <> tmpFolder <> "/" <> frontMatter.slug <> ".html" <> " = success!"
              pure res

getFilesAndTemplate :: ExceptT Error Aff { files :: Array String, template :: String }
getFilesAndTemplate = do
    files <- ExceptT $ try $ readdir rawContentsFolder
    template <- readPostTemplate
    pure { files, template }

generatePostsHTML :: Array FormattedMarkdownData -> ExceptT Error Aff Unit
generatePostsHTML fds = do
    template <- readPostTemplate
    _ <- parTraverse_ (\f -> writeHTMLFile (Template template) f) fds
    pure unit

replaceContentInTemplate :: Template -> FormattedMarkdownData -> String
replaceContentInTemplate (Template template) pd =
    replaceAll (Pattern "{{title}}") (Replacement $ "<a href=\"./" <> pd.frontMatter.slug <> "\">" <> pd.frontMatter.title <> "</a>") template
        # replaceAll (Pattern "{{content}}") (Replacement $ pd.content)
        # replaceAll (Pattern "{{date}}") (Replacement $ formatDate "MMM DD, YYYY" pd.frontMatter.date)
        # replaceAll (Pattern "{{page_title}}") (Replacement pd.frontMatter.title)

readPostTemplate :: ExceptT Error Aff String
readPostTemplate = ExceptT $ try $ readTextFile UTF8 blogpostTemplate

buildSite :: ExceptT Error Aff Unit
buildSite = do
    log "\nStarting..."
    _ <- createFolderIfNotPresent tmpFolder
    { postsToPublish, postsToRebuild } <- getPostsAndSort
    log "Generating posts pages..."
    _ <- generatePostsHTML postsToRebuild
    log "Generating posts pages: Done!\n"
    log "Generating archive page..."
    -- _ <- createFullArchivePage postsToPublish
    _ <- writeIndexPage postsToPublish
    log "Generating archive page: Done!\n"
    -- log "Generating home page..."
    -- _ <- createHomePage postsToPublish
    -- log "Generating home page: Done!\n"
    log "Copying 404.html..."
    _ <- ExceptT $ try $ liftEffect $ execSync ("cp " <> templatesFolder <> "/404.html " <> tmpFolder) defaultExecSyncOptions
    log "Copying 404.html: Done!\n"
    log "Copying images folder..."
    _ <- ExceptT $ try $ liftEffect $ execSync ("cp -r " <> templatesFolder <> "/images " <> tmpFolder) defaultExecSyncOptions
    log "Copying images folder: Done!\n"
    log "Copying js folder..."
    _ <- ExceptT $ try $ liftEffect $ execSync ("cp -r " <> templatesFolder <> "/js " <> tmpFolder) defaultExecSyncOptions
    log "Copying js folder: Done!\n"
    log "Generating styles.css..."
    _ <- generateStyles
    log "Generating styles.css: Done!\n"
    log "Generating RSS feed..."
    _ <- Rss.generateRSSFeed postsToPublish
    log "Generating RSS feed: Done!\n"
    log $ "Copying " <> tmpFolder <> " to " <> htmlOutputFolder
    _ <- createFolderIfNotPresent htmlOutputFolder
    _ <- ExceptT $ try $ liftEffect $ execSync ("cp -r " <> tmpFolder <> "/* " <> htmlOutputFolder) defaultExecSyncOptions
    log "Copying /tmp to /public: Done!\n"
    log "Updating cache..."
    _ <- ExceptT $ try $ Cache.writeCacheData
    log "Updating cache: Done!\n"

-- createFullArchivePage :: Array FormattedMarkdownData -> ExceptT Error Aff Unit
-- createFullArchivePage sortedArray = do
--   content <- (toHTML sortedArray)
--   writeFullArchivePage content
--   where
--   toHTML :: Array FormattedMarkdownData -> ExceptT Error Aff String
--   toHTML fd = do
--     template <- ExceptT $ try $ readTextFile UTF8 archiveTemplate
--     pure $ replaceAll (Pattern "{{content}}") (Replacement $ "<ul>" <> content <> "</ul>") template
--     where
--     content = foldl fn "" fd
--     fn b a = b <> "<li><a href=\"./" <> a.frontMatter.slug <> "\">" <> a.frontMatter.title <> "</a> &mdash; <span class=\"date\">" <> formatDate "MMM DD, YYYY" a.frontMatter.date <> "</span>" <> "</li>"
--   writeFullArchivePage :: String -> ExceptT Error Aff Unit
--   writeFullArchivePage str = ExceptT $ try $ writeTextFile UTF8 (tmpFolder <> "/archive.html") str
generateStyles :: ExceptT Error Aff Buffer
generateStyles = ExceptT $ try $ liftEffect $ execSync command defaultExecSyncOptions
    where
    command = "npx tailwindcss -i " <> templatesFolder <> "/style.css -o " <> tmpFolder <> "/style.css"

recentPosts :: Int -> Array FormattedMarkdownData -> String
recentPosts n xs =
    let
        recentN = take n xs
    in
        case recentN of
            [] -> "Nothing here."
            ys -> renderRecents ys
                where
                renderRecents fds = "<ul>" <> foldl fn "" fds <> "</ul>"

                fn b a = b <> "<li><a href=\"/" <> a.frontMatter.slug <> "\">" <> a.frontMatter.title <> "</a> &mdash; <span class=\"date\">" <> formatDate "MMM DD, YYYY" a.frontMatter.date <> "</span>" <> "</li>"

getPostsAndSort :: ExceptT Error Aff ({ postsToPublish :: Array FormattedMarkdownData, postsToRebuild :: Array FormattedMarkdownData })
getPostsAndSort = do
    filePaths <- ExceptT $ try $ readdir rawContentsFolder
    onlyMarkdownFiles <- pure $ filter (contains (Pattern ".md")) filePaths
    oldCacheData <- ExceptT $ try $ Cache.readCacheData
    newCacheData <- ExceptT $ try $ Cache.createCacheData
    formattedDataArray <- filePathsToProcessedData onlyMarkdownFiles
    removeIgnored <- pure $ filter (\f -> not f.frontMatter.ignore) formattedDataArray
    removeCached <- pure $ filter (\f -> Cache.needsInvalidation oldCacheData newCacheData f.frontMatter.slug) removeIgnored
    pure $ { postsToPublish: sortPosts removeIgnored, postsToRebuild: sortPosts removeCached }
    where
    filePathsToProcessedData :: Array String -> ExceptT Error Aff (Array FormattedMarkdownData)
    filePathsToProcessedData fpaths = parTraverse (\f -> readFileToData $ rawContentsFolder <> "/" <> f) fpaths

sortPosts :: Array FormattedMarkdownData -> Array FormattedMarkdownData
sortPosts = sortBy (\a b -> if a.frontMatter.date < b.frontMatter.date then GT else LT)

-- groupPostsByYear :: Array FormattedMarkdownData -> Map Int (Array FormattedMarkdownData)
-- groupPostsByYear posts = foldl foldFn Map.empty posts
--     where
--     foldFn :: (Map Int (Array FormattedMarkdownData)) -> FormattedMarkdownData -> Map Int (Array FormattedMarkdownData)
--     foldFn b a =
--         let
--             updateFn v = Just $ Array.snoc (fromMaybe [] v) a

--             year = extractYear a.frontMatter.date
--         in
--             case year of
--                 Nothing -> b
--                 Just y -> Map.alter updateFn y b

--     extractYear dateString =
--         split (Pattern "-") dateString
--             # Array.head
--             # Maybe.map (fromString)
--             # join

postsToHTML :: Array FormattedMarkdownData -> String
postsToHTML fds =
    let
        formattedDataToHTML :: FormattedMarkdownData -> String
        formattedDataToHTML fd = "<li><span class=\"date\">" <> formatDate "MMM DD, YYYY" fd.frontMatter.date <> "</span><a href=\"/" <> fd.frontMatter.slug <> "\">" <> fd.frontMatter.title <> "</a></li>"

    in
        "<ul>" <> (map formattedDataToHTML fds # joinWith "") <> "</ul>"

-- groupedPostsToHTML :: Map Int (Array FormattedMarkdownData) -> String
-- groupedPostsToHTML groupedPosts =
--     let
--         formattedDataToHTML :: FormattedMarkdownData -> String
--         formattedDataToHTML fd = "<li><a href=\"/" <> fd.frontMatter.slug <> "\">" <> fd.frontMatter.title <> "</a> &mdash; <span class=\"date\">" <> formatDate "MMM DD, YYYY" fd.frontMatter.date <> "</span></li>"

--         arrayDataToHTML :: Array FormattedMarkdownData -> String
--         arrayDataToHTML fs = "<ul>" <> (map formattedDataToHTML fs # joinWith "") <> "</ul>"

--         mapAsList :: Array (Tuple Int (Array FormattedMarkdownData))
--         mapAsList = Map.toUnfoldable groupedPosts # sortBy (\(Tuple a1 _) (Tuple a2 _) -> if a1 > a2 then LT else GT)

--         tupleToString :: Tuple Int (Array FormattedMarkdownData) -> String
--         tupleToString (Tuple year fds) = "<section><h3>" <> show year <> "</h3><div>" <> arrayDataToHTML fds <> "</div></section>"

--         result :: String
--         result = map tupleToString mapAsList # joinWith ""
--     in
--         result

-- writeArchiveByYearPage :: Array FormattedMarkdownData -> ExceptT Error Aff Unit
-- writeArchiveByYearPage fds = do
--     contentToWrite <- pure $ groupedPostsToHTML $ groupPostsByYear fds
--     templateContents <- ExceptT $ try $ readTextFile UTF8 $ archiveTemplate
--     replacedContent <- pure $ replaceAll (Pattern "{{content}}") (Replacement contentToWrite) templateContents
--     ExceptT $ try $ writeTextFile UTF8 (tmpFolder <> "/index.html") replacedContent

writeIndexPage :: Array FormattedMarkdownData -> ExceptT Error Aff Unit
writeIndexPage fds = do
    contentToWrite <- pure $ postsToHTML fds
    templateContents <- ExceptT $ try $ readTextFile UTF8 $ archiveTemplate
    replacedContent <- pure $ replaceAll (Pattern "{{content}}") (Replacement contentToWrite) templateContents
    ExceptT $ try $ writeTextFile UTF8 (tmpFolder <> "/index.html") replacedContent

dummyData :: Array FormattedMarkdownData
dummyData =
    [ { frontMatter: { ignore: false, tags: [], date: "2023-01-01", slug: "something", title: "something" }, content: "more", raw: "fasdf" }
    , { frontMatter: { ignore: false, tags: [], date: "2023-01-01", slug: "something", title: "something" }, content: "more", raw: "fasdf" }
    , { frontMatter: { ignore: false, tags: [], date: "2023-01-01", slug: "something", title: "something" }, content: "more", raw: "fasdf" }
    , { frontMatter: { ignore: false, tags: [], date: "2022-01-01", slug: "something", title: "something" }, content: "more", raw: "fasdf" }
    , { frontMatter: { ignore: false, tags: [], date: "2022-01-01", slug: "something", title: "something" }, content: "more", raw: "fasdf" }
    ]

-- test = groupedPostsToHTML <<< groupPostsByYear
