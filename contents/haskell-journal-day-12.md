---
title: Haskell Journal - Day 12
date: "2024-10-19T20:00:00Z"
slug: haskell-journal-day-12
---

- All improvements made on [day 11](./haskell-journal-day-11) went to waste because the app kept crashing when I tried to 'refresh' the feeds. It either crashed with a `bus error` message, a `malloc` related error, or in the worst case scenario, just got stuck while the machine ran out of memory and my MacBook asked me to force quit some apps.

- I went on a wild goose chase trying to isolate the issue and then test various combinations. I isolated the issue to the fetching of feeds from the feed URLs, but all sorts of changes to that function did not help. Going lazy ByteString didn't help. Using an alternative library (wreq, req etc.) didn't help either.

- I asked a bunch of folks via the usual help channels: FP slack #haskell channel, FP India Telegram channel, and reddit.

- I spent a day obsessing about this, trying everything. I then decided to give it a break because it was getting on my nerves.

- Finally, the breakthrough came when I asked on IRC (Libra server, #haskell). One of them pointed to a known issue with `ghc < v9.2.6` in the `GMP` module (which I, being ignorant, obviously had no clue about). Updating my `cabal` and `ghc` just magically fixed the issue. My app finally is able to terminate correctly and function absolutely well! (I don't mind the 1G memory footprint it has when it refreshes all feeds).

- One learning did come out of this though: I was concatenating strings and forming SQLite query strings that way — but I was advised to use parameterization, so that change was incorporated.

- After almost two days of drudgery and not having any idea about how to fix the crashes, there's now excitement that the app works and I can continue adding features to it.
