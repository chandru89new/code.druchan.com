---
title: Haskell Journal - Day 12
date: "2024-10-18T06:00:00Z"
slug: haskell-journal-day-12
---

- I made improvements to the tool. I can now refresh just a single feed and build a digest for a date range. The digest now picks items whose `published` date — `updated` in the DB — is in the range. There's also a command to create a digest for today.

- I updated the code to handle some edge cases, such as asking the app to process a feed that isn't yet added to the database. This can cause issues because the feed.id won't be in the DB but will be linked to the feed_items table.

- I made lots of improvements to [the template](https://i.imgur.com/4GJi0bd.png). The error messages are now much better and friendlier.

- I noticed that there were multiple feed items that had `updated` as `null` because the datetime parser was returning `Nothing`. It turns out I had to add 4 more date formats to handle this:

```haskell
parseDate datetime = fmap utctDay $ firstJust $ map tryParse [fmt1, fmt2, fmt3, fmt4, fmt5, fmt6]
   where
     fmt1 = "%Y-%m-%dT%H:%M:%S%z"
     fmt2 = "%a, %d %b %Y %H:%M:%S %z"
     fmt3 = "%a, %d %b %Y %H:%M:%S %Z"
     fmt4 = "%Y-%m-%dT%H:%M:%S%Z"
     fmt5 = "%Y-%m-%dT%H:%M:%S%Q%z"
     fmt6 = "%Y-%m-%dT%H:%M:%S%Q%Z"
     ...rest of the code
```

- I also renamed the project from `rss-digest` to `rdigest`.

- As you can imagine, there hasn't been much Haskell-specific learning here. I can feel the effects: I'm kind of losing excitement because the work I'm doing isn't pushing my comfort zone mechanics, I think, and I'm not learning something new. I think I should work on making the tool "serve" the digest — this would involve some updates to the UI to accept date ranges and adding server capability to the tool itself.
