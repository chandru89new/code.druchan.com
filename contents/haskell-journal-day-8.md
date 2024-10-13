---
title: Haskell Journal - Day 8
date: 2024-10-14
slug: haskell-journal-day-8
---

- While I actually didn't want to work on the project today, one thing led to another and I ended up working on it.
- I was watching [this video](https://www.youtube.com/watch?v=kbFGvUXqUcw&pp=ygUSaGFza2VsbCBleGNlcHRpb25z) on exceptions and realized I could use a simple `IO a` type for my functions instead of `ExceptT...` because all `IO a` types _can_ potentially throw. Combined with a custom `Exception` interface for my `AppError`, I could potentially get rid of a few `runExceptT`s in the code — so I went about doing it and the whole app got converted into a simple `IO a` (i.e., the `App a` wrapper stopped being an `ExceptT ...` and became an `IO a`). There were some places where I had to handle things correctly so that errors were managed properly (like when trying to insert a link, the inner function crashes if the SQL insert query fails — but the handler that uses the inner function shouldn't crash, because failing for one feed item shouldn't fail others).
- What I like about this approach is that I can have any throwable `IO a`, and I can simply run it through `failWith <AppError>` and it will produce an `IO a` or throw with the right kind of `AppError`. i.e, it takes an `IO a` that could throw a `SomeException` and converts it into an `IO a` that could throw an `AppError`.
- The codebase became much cleaner and reasoning about the steps is now far simpler. I also discovered there was one place where I was returning an `IO a` for no reason — the function could be very pure and return `a` simply.
- After this, I couldn't stop. I ended up writing a simple command system for the app so I can now compile the binary and run a few commands like:

```bash
> rss-digest add <url> # this adds an XML URL to the database, correctly showing an error if the URL is already added or it's an invalid URL.
> rss-digest refresh # this fetches all feed links from all the RSS feeds in the database, and then updates the feed_items table.
> rss-digest purge # nukes the whole thing
```

- I wanted to check the size of the binary and it was a whopping 64MB. Ignorant me was surprised as heck. I asked ChatGPT about it and it said it was because the binary was packing everything to be self-sufficient. One of the options it gave was to use dynamic linking instead of static linking — I had concerns about this because how would that work if one were to distribute the binary? The reduction was anyway not all that great. There were other options it suggested like "no profiling", turning off debug mode, using some "O2" mode of optimization etc... nothing really worked.
- One thing I missed in the ChatGPT list of recommendations was to use the `strip` command on the binary. Instead, I went to Stack Overflow and Google... and one of the suggestions there was `strip` too. So I did that and the binary came down to 41MB which is still humongous (for comparison, GitHub's CLI tool `gh` v2.49 is ~48MB). `strip` removes all the symbols from the binary. I did a test run of the binary after doing the `strip` and it was working OK. (update: if I compile the binary with dynamic linking, and then do a `strip`, the binary size is about 200kb)
- I'm quite happy about the way the project has shaped up so far. Might do a recap of what I learned, patterns that seem to emerge etc at some point.
