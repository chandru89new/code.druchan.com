---
title: Haskell Journal - Day 4
date: 2024-10-10
slug: haskell-journal-day-4
---

- A couple of big wins today.
- The big-ticket item: I managed to port most functions to `ExceptT`, so now I don’t have to wrestle with the `IO (Either e a)` datatype with pattern matching or bifunctor wrangling. Most functions involving side effects are now just `ExceptT SomeException IO a`—I can use them as if they yield the happy-path result. At some point, a `main` function will run `runExceptT`, and I can handle the errors there.
- Another big-ticket item: I got a handle (no pun intended) on integrating SQLite into my project and was able to write into one of the tables. All exploratory, but it worked—I wrote data into the DB from a Haskell function, and it landed safely in the SQLite file. I also started thinking about the table schema, but I haven't spent enough time on that yet.
- Since it's still early, I haven’t thought about managing the database and changes—so no migrations yet. I just nuke the database when I need to change the columns or table structure.
- I was happy that if a table has a `TEXT` column (with a `NOT NULL` constraint), passing a `Just String` value inserts the `String` into the column, but passing `Nothing` throws an error at the DB layer.
- With the database integrated, two new problems arose: every function interfacing with the DB has to open and close the connection, and passing the connection around is redundant and ugly. I knew I'd eventually have to dip my toes into the `ReaderT` monad... turns out I’ll have to do that soon.
- To wrap up the day, I chatted with ChatGPT to check some examples on how to combine `ReaderT` (to pass global config, like the DB connection) and `ExceptT` to handle errors gracefully. The examples were simple enough, so I have my work cut out for the next day on this project.
