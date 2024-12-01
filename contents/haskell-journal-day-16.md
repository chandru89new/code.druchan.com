---
title: Haskell Journal - Day 16
date: 2024-11-27
slug: haskell-journal-day-16
---

One of the things that has been bugging me since I wrapped most bits on the `rdigest` project was that I could not get it to work in a Github repo where I planned to run it on a cron so that digests get created automatically every day and hosted somewhere so I can read from anywhere.

My first attempts to do this was to upload my locally-built binary and see if that works in a GH action running on a `macos-latest` machine — it did not. I spent a tiny bit of time before my day-job took precedence and because I couldn't get it to work, I decided to park there and come back later.

Coming back later, I decided to make the `rdigest` repo build its binaries on `ubuntu-latest` and release the artefact in [the repo](https://github.com/chandru89new/rdigest/releases). This was exceedingly simple (probably needed a couple of iterations to get the right configuration options for GHCup, Cabal, GHC, tagging etc.). This worked nice, and all that was left to do was to consume the release in my [`rdigest-data` repo's](https://github.com/chandru89new/rdigest-data) cron action.

With a few iterations, I got all of it tied up. The cron ran once every day and updated the digest for a particular day. With GH Pages setup on that repo, I was able to just hit the URL and see a list of all digests and read each digest at leisure.

But this unearthed a new problem: since I ran the digest update just once, and the process would only update for "today" (whatever today was at the time of running the binary), some posts could "slip" the digest depending on the timing. I haven't spent much time thinking about the optimal approach to fixing this but in the meantime, it made sense to just update all digest-days once I have refreshed (and saved posts from) all feeds in my list. Ugly, nuclear solution but it ensures all my digest files are up-to-date.

Life is getting a lot in the way in recent times so there's been a pause in activity but I am itching to refine the `rdigest` codebase to elegantly separate out the functional and imperative bits. And also revisit what interesting things the project can spawn into and make it more useful than just producing digests.
