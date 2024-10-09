---
title: Haskell Journal - Day 1
date: 2024-10-07
slug: haskell-journal-day-1
---

- Decided to finally build something in Haskell to learn the language. So far, I've been solving puzzles and similar tasks, but nothing has given me the confidence to say, "Yes, I can build that in Haskell."
- Areas to focus on:
  - File I/O
  - Making API calls to some service and processing data
  - Web scraping
  - Running a web server
  - Interacting with a database
  - Concurrency
- A recent problem I faced: YouTube's UI doesn't expose RSS feeds for channels, but it's present in the HTML source code. The idea: a CLI tool that takes a YouTube channel URL, scrapes the HTML source, and returns the feed link.
- Asked ChatGPT for a good web scraping library in Haskell. It suggested `tagsoup` and `html-conduit` (for fetching the source). Took a look at the examples and docs... seemed a little hard to grasp. Asked ChatGPT for a simpler alternative, and it suggested `scalpel`. Liked it, and decided to use it.
- Wrote some initial code based on ChatGPT's example of scraping. However, ChatGPT got the `attr` function wrong. There was some wrangling between `ScraperT` and `Scraper`, and I finally learned that I could use the `Identity` monad to go from `ScraperT` to `Scraper`. (Monad Transformers).
- Also experimented with constructing a scraper from a selector and then using it in the `scrapeURL` function.
- It took me a while to get an intuition for how the selectors and scrapers fit together, and then using the scraper in the scrape runners. I also felt uneasy when trying to "compose" a scraper from other scrapers (almost thought it was impossible).
  - I hit this issue because I needed to scrape the whole source but pick multiple data points—title of the channel and feed link URL—which were in different tags.
  - The solution was to use `optional`.
  - Eventually, I didn’t need this.
- The final piece of the puzzle was running this as a CLI tool, meaning I needed to take an argument (the YouTube channel's URL). ChatGPT suggested `optparse-applicative`, but I decided it was overkill for what I needed. A simple `--url <url>` argument was enough. ChatGPT suggested pattern matching on the arguments:

```haskell
case args of
  ("--url" : url : _) -> ...
  _ -> ...
```

- I tried to initialize the project with Stack first, but it threw some weird errors. So I decided to go with a Cabal-only approach, which worked. I haven’t investigated why Stack failed. I might not do that for now, as the Cabal setup seems good enough—I was able to add packages, build the binary, test it, and also run the REPL from Cabal.
- Overall, a great day 1—just the right amount of pushing against my comfort zone.
