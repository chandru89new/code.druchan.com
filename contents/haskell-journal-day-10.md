---
title: Haskell Journal - Day 10
date: 2024-10-16
slug: haskell-journal-day-10
---

- The digest list I generated seemed bland and unfriendly as a single list, so I grouped them based on the feed URL (eventually, feed title). This improved the experience of viewing a day's digest, as it now appears as a [grouped list](https://imgur.com/sk14hRb). This change also required updates to the template.html file.

- For grouping, I initially considered using the Map datatype but felt it was overkill. Instead, I decided to write small functions to handle a datatype which is Map-like `[(key, value)]`.

- I occasionally encounter "bus errors," which are usually related to out-of-memory issues. I suspect this is due to Haskell's laziness. These errors typically occur when fetching feeds, but randomly. I need to investigate the cause.

- I'm now considering having this tool spin up a local server to serve the digest on-demand. Commands could also be invoked from the web UI. Alternatively, I could explore concurrency to allow parts of the feed item refresh process to occur simultaneously.
