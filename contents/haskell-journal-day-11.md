---
title: Haskell Journal - Day 11
date: 2024-10-17
slug: haskell-journal-day-11
ignore: true
---

- Made significant improvements to the tool. Now able to refresh a single feed and build a digest for a date range. The digest selects items with `published` dates (`updated` in the database) within the specified range. Added a command to create a digest for today.

- Updated code to handle edge cases, such as attempting to process a feed not yet added to the database. This prevents issues related to missing feed IDs in the database affecting the feed_items table.

- Implemented numerous improvements to [the template](https://i.imgur.com/4GJi0bd.png). Error messages are now more user-friendly and informative.

- Discovered multiple feed items with `null` updated values due to the datetime parser returning `Nothing`. Added four new date formats to address this issue:

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

- Renamed the project from `rss-digest` to `rdigest`.

- Progress on Haskell-specific learning has slowed. Excitement is waning due to lack of challenges outside the comfort zone. Considering adding server capabilities to the tool, allowing it to serve the digest. This would involve UI updates to accept date ranges and implementing server functionality.
