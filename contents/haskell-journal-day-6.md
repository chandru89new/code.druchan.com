---
title: Haskell Journal - Day 6
date: 2024-10-12
slug: haskell-journal-day-6
---

- Managed to remove the complexities of the `ReaderT` thingy with the app and introduced a much simpler type:

```haskell
type App a = Config -> ExceptT AppError IO a
```

- So now, any function that needs the config can simply be a function that takes a `Config` and returns an `ExceptT AppError IO a`.
- I also updated the feed-item extracting part of the code so that it can, in one pass, work for both Youtube feeds and other RSS XML 2.0 spec feeds — the difference in YT feeds is that they use `<link href="..." />` instead of `<link>{actual_url}</link>`, and they use `<published>` and `<updated>` instead of `<pubDate>`.. basically different specs. The way I handled this was to use the wonderful `<|>` (alternative) operator. My use-case has been very simple so far thankfully — I just try to extract/parse (using `tagsoup`) and then return a `Maybe String`. Combined with the `<|>` operator, I get what I want - if the item has `<pubDate>`, that's extracted and returned. But if it has `<updated>` instead, that will be extracted and sent. If both exist, the first will be returned.

```haskell
extractData :: [Tag String] -> FeedItem
extractData tags =
  let title = getInnerText $ takeBetween "<title>" "</title>" tags
      linkFromYtFeed = extractLinkHref tags -- youtube specific
      link = case getInnerText $ takeBetween "<link>" "</link>" tags of
        "" -> Nothing
        x -> Just x
      pubDate = case getInnerText $ takeBetween "<pubDate>" "</pubDate>" tags of
        "" -> Nothing
        x -> Just x
      updatedDate = case getInnerText $ takeBetween "<updated>" "</updated>" tags of
        "" -> Nothing
        x -> Just x
      updated = pubDate <|> updatedDate
   in FeedItem {title = title, link = link <|> linkFromYtFeed, updated = fromMaybe "" updated}
```

- The success in `extractData` did not last by the time it came to working with functions that had to interface with the DB. Had a lot of trouble writing that one function `processFeed :: URL -> App ()` which takes a URL (String), and an app config (`Config`) and then actually fetches the contents, then writes to the database. This was because I had a tough time unwrapping/wrapping to `IO ()` without losing the errors.. but then, I realized I had not really thought about error/crash strategy: like, when I extract feed items and attempt to write each link to the database, should I crash at the first error or should I just log it to the console and carry on with the next item?
- I decided that it was best to log and continue to the next. Then came the question of which function should do the logging? For now, the `insertFeedItem` (which takes a feed item and writes to the DB) is the one that logs... but that came about after so much wrangling with these functions. At the end of the day, I went with really simplified `insertFeedItem` whose return type went from `ExceptT ... ()` to `IO ()`... which I am not really happy about because a thrown error is not caught.
- Eventually, `insertFeedItem` got wrapped inside `processFeed` (which processes a single feed URL), which then got wrapped inside `processFeeds` which processes a list of URLs, simply mapping over the `processFeed` function.
- Overall — the good thing is that I managed to get a working function that took a URL and fed the feed items into the table. But the code is already somewhat confusing and there were times where things compiled and worked but I just couldn't get a complete understanding of what was going on in the wrapping/unwrapping — a feeling I commonly encounter when dealing with these functional programming languages.
- I spent time on finalizing the table schemas. The `link` is the primary key so duplicate inserts are prevented at the DB level besides being prevented at the code level.
- I am also briefly mulling if I could put all the code in a single file. I have modules around functions (like DB-related, RSS parsing related etc) but they are already coupled by sharing of types and whatnot. So I am thinking maybe for now I will put them all in a single Main.hs file and then extract out modules based on what natural grouping requirements emerge in that file.
