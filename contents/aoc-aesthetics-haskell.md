---
title: Advent of Code and Aesthetics
date: 2024-12-12
slug: aoc-aesthetics-haskell
ignore: false
---

Over the last few days, I've been solving [Advent of Code 2024](https://adventofcode.com/2024/) puzzles in Haskell. This is only my second time hurting my brain by trying to come up with solutions for AoC ([last time was in 2021](https://github.com/chandru89new/elm-aoc), when I used Elm; I barely made it to Day #15 before giving up).

AoC puzzles expose me to many sorts of list and graph-type data structure puzzles, with some accompanying search (usually DFS) / update algorithms. As someone who comes from a non-CompSci background with very weak math acumen (one of the reasons I did not pursue a masters in Physics), all of this hurts but it's nevertheless so much fun to think of an algorithm, express it in Haskell syntax (or try to) and then run the code to see it output what has so far ended up being the right answers to the AoC puzzles.

Some notes arose out of this.

### "Thinking in types" does not go brrrr

It's all fun and games to think in types. In fact, it makes sense when I am [building something](https://github.com/chandru89new/rdigest). But boy does it suck to introduce sum types and such when doing these puzzles. I started the first couple of days with a type-based approach but by [Day 6](https://github.com/chandru89new/aoc2024/blob/main/app/Day6.hs), I turned away from it. It's useful when I can afford to spend a whole lot of time building types and functions for data transformation but not when I just want to solve a damn puzzle that just involves a whole bunch of `Char`s.

### My algorithms lack mathematical aesthetics

One of the wonderful after-effects of me discovering the [world of FP](https://en.wikipedia.org/wiki/Functional_programming) is that I could model something as data-transformations. A lot of things can be modelled like that and the triumvirate of immutability, applicative/monadic laws, and strong typing make it a delightful experience. AoC puzzles literally are about data transformations. Great.

But when I compare my solutions to those of someone like [Abhinav](https://github.com/abhin4v/AoC24), good lord, my programs feel so imperative. Almost every puzzle lends itself to some really aesthetic mathematical jugglery, sometimes simple, sometimes complex. I guess having a good mathematical bent helps in discovering or inventing these aesthetic-looking solutions (yes, aesthetics is subjective, I know). Haskell is well-suited to expressing these mathematical things almost verbatim. Too bad I have not the level of acumen or knowledge.

### REPLing is fun till that large computation hits you

[REPL-based development](https://blog.cleancoder.com/uncle-bob/2020/05/27/ReplDrivenDesign.html) is a gift. I am sad that it's not the norm in many environments (like frontend, except [when it's Clojurescript](https://www.youtube.com/watch?v=toGEegAzrZA)). While not as exceptional as Clojure, Haskell's REPL is great and it accelerates development.

Except, during some of these AoC puzzles, the computation does take a while and it's a long pensive wait because sometimes I can't tell if the code went into an infinite recursion or it's just taking a long time. (Long times here mean ~120s, which doesn't feel all that long on paper but when other puzzles solve in under a second or two, 120 is huuuuuuge).

I compiled the program to test some other mechanism I was building into my code unrelated to some long-running puzzles, and then I ran the binary, running the puzzle inadvertently. Suddenly, the ~120s function ran in a fraction of that time! Crap. I could've saved a lot of anxiety by just building the binary (which takes <5s) and running the solutions!

### Resisting the urge to be (point-)free

Several times in a coding session, there's this opportunity to [reduce an expression](https://wiki.haskell.org/Eta_conversion), often to the extent of [point-free](https://wiki.haskell.org/index.php?title=Pointfree). It is tempting. But I imagine myself reading this code a few weeks down the line and I can vividly picture a completely confused brain that struggles to comprehend what it wrote. That keeps the terseness-shenanigans at bay. However, it would be cool to have a branch where the code is as terse as can be.

\*

Anyway, it is almost always a delight to be able to solve some puzzles by writing some code. Amidst some stressful work caretaking for a recovering parent from their surgery, I look forward to these moments when I get to think about these AoC puzzles.
