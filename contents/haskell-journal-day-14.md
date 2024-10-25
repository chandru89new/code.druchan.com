---
title: Haskell Journal - Day 14
date: 2024-10-25
slug: haskell-journal-day-14
---

- I added 286 YouTube channel RSS feeds (from channels I’m subscribed to) to my personal `rdigest` collection. This surfaced some usability challenges. For any given day, more than 70% of the links were from YouTube, highlighting the need for better categorization.
- Initially, feeds were grouped by the source URL, but this wasn't sufficient for YouTube because all feed URLs have the same hostname (`youtube.com`). I needed a way to distinguish them by the feed title. However, I wasn’t capturing the title, and `title` wasn’t even a column in the `feeds` table. So, I updated the database schema to add a `title` column—essentially setting up a basic migration system. I experimented with a simple "up-only" migration approach, which worked reasonably well and now allows me to run multiple SQL queries from a file in sequence within a transaction.
- Adding titles to feeds enabled grouping by URL while displaying titles, making the digest easier to scan. This required reconsidering how I structured the data. I went from grouping as `(URL, [FeedItem])` (where `FeedItem` represents an individual post from the feed at `URL`) to `((URL, String), [FeedItem])`. Though straightforward at the type level, the change needed adjustments in functions. The digest grouping now happens within the function that writes the digest file since that's where grouping is required. It’s a relief to be able to use tuples as keys without having to worry — imagine facing this in the Javascript world.
- Once again, I enjoyed the process of writing code as if functions already existed, defining type annotations and `undefined` placeholders, and then iteratively filling in the `undefined` parts with help from the language server and occasionally ChatGPT.
- Another crazy thing happened with the binary size. The un-stripped one (but with all optimizations from cabal and GHC) is over 80MB. Stripping it of symbols reduces it to 51MB. I was randomly searching for discussions about Haskell binary sizes and discovered a tool called `upx`. Using that, the binary size dropped to 15MB. Can you imagine?!
