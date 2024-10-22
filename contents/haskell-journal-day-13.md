---
title: Haskell Journal - Day 13
date: 2024-10-21
slug: haskell-journal-day-13
---

Here's the cleaned up text while preserving all information:

- Added an important update: rdigest requires you to specify where to store the db and digest files via environment variable. This was surprisingly easy to implement.

- Attempted to add subreddit RSS, which proved very temperamental. It works sometimes, but often no feed comes through because Reddit aggressively blocks direct access by tools/scrapers. Went on a troubleshooting journey trying to solve this by using alternative libraries like wreq, but these didn't help. All these "simpler" libraries were actually much harder to get started with and use. While this arguably makes them more typesafe, they are poor for rapid prototyping. The examples in their documentation are also inadequate. Returned to the original library (Network.HTTP.Simple) and added a user-agent header, which occasionally fixes the Reddit RSS issue.

- There are spots in the code where better use of available instances for particular datatypes could improve readability. For example, in the `runApp` where the environment variable is retrieved:

```haskell
runApp :: App a -> IO ()
runApp app = do
  let template = $(embedFile "./template.html")
  rdigestPath <- lookupEnv "RDIGEST_FOLDER"
  case rdigestPath of
    Nothing -> showAppError $ GeneralError "It looks like you have not set the RDIGEST_FOLDER env. `export RDIGEST_FOLDER=<full-path-where-rdigest-should-save-data>"
    Just rdPath -> do
      pool <- newPool (defaultPoolConfig (open (getDBFile rdPath)) close 60.0 10)
      let config = Config {connPool = pool, template = BS.unpack template, rdigestPath = rdPath}
      res <- (try :: IO a -> IO (Either AppError a)) $ app config
      destroyAllResources pool
      either showAppError (const $ return ()) res
```

- In this code, `app` returns an `IO a` which is handled as a potentially-throwing action. However, the extraction of `rdPath` happens outside the `try`. Better code would follow the happy-path pattern, with errors handled inherently in a global `try` block. The `runApp` function is intended to be that global try block for all `App a` actions, but the environment variable extraction happens outside this boundary.

- At some point in this Haskell journey, the project began feeling like routine code similar to Typescript. This prompted reflection on the benefits derived from using Haskell beyond learning the language and code architecture. Notable advantages include:

  - Easier writing and reading of async/effectful actions due to `bind` abstractions (sugared as `do` blocks) with upper-level error handling
  - Clean implementation of applicative parsing, which would be challenging in non-functional programming languages
  - Convenient data types and constructors that simplify logic construction

- Hlint often recommended ways to make code more concise through [point-free](https://wiki.haskell.org/Pointfree) style or using operators. For example, this code:

```haskell
parseURL :: String -> Maybe URL
parseURL url = case parseURI url of
  Just uri -> (if uriScheme uri `elem` ["http:", "https:"] then Just url else Nothing)
  Nothing -> Nothing
```

Can be written as:

```haskell
parseURL :: String -> Maybe URL
parseURL url = parseURI url >>= \uri -> if uriScheme uri `elem` ["http:", "https:"] then Just url else Nothing
```

- Sometimes explicit destructuring and imperative-style expressions were preferred for better understanding of the logic.

- This was largely a matter of familiarity. With more exposure to situations requiring unwrapping double monadic structures, the use and understanding of `>>=` became more natural:

```haskell
getDomain :: Maybe String -> String
getDomain url =
  let maybeURI = url >>= parseURI >>= uriAuthority
   in maybe "" uriRegName maybeURI
```

- This experience recalled the [exchange](https://mail.haskell.org/pipermail/haskell-cafe/2009-March/058475.html) on terseness and readability.

- I think sometimes I am able to think very cleanly thanks to the type-system and the functional-style of programming but there's certainly the feeling that I am not completely tapping into that potential. Being able to express the logic in the code as a beautiful equation is still elusive.
