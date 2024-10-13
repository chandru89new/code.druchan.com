---
title: Haskell Journal - Day 7
date: 2024-10-13
slug: haskell-journal-day-7
---

- Continuing from [day 6](./haskell-journal-day-6)'s thought, I put all the code (except the one-time Youtube feed link extractor) in a single file. While it felt like I had written a lot of code, it's just about 250 lines including some 25 lines of `import` statements. At some point in the project, I'll have to break this up but this is too early and unnecessary right now.
- The biggest win for today has been -> I got a good working prototype of a function that reads a table to get a list of rss links, then goes out to fetch each link and process it, and adds the posts from the feed to another table. And all of it done with the right kind of error handling (as far as my rudimentary tests are concerned). So now I could just invoke one function to fetch the latest updates from every rss link I have.
- I had a terrible time gaining some understanding of the underlying monadic things about my data structure `App`. I played around a bunch of options — like reducing the lower-level functions to just be `IO a` instead of `ExceptT ...` etc but things kept feeling messy. I did finally manage to keep them all neat and tidy into the `ExceptT` (because that's how one can safely hold errors). Briefly, my app kept crashing if a malformed URL was sent down the wire and I realized it was just a matter of me not handling a throwable `IO ()` in a function that fetched contents of a URL.
- Functions that use the connection pool (a.k.a functions that interact with the DB) were the hardest to write because the `withResource` function kept tripping me up. That function has type `Pool Connection -> (Connection -> IO a) -> IO a` , i.e. it takes a connection pool and a function that takes a connection and returns an `IO a`... but it took my stupid brain a long time to figure out how to bubble errors up from the inner function. Was a simple `try $` slapped in front .. but I had to make sure the `try`'s `SomeException` was returned as `AppError` afterwards. This piece was the one that actually caused all sorts of trouble in my intuition of the app's helper functions (involving database access), but once this clicked in place, a lot of things got simplified.
- Type-level reasoning saved the day a few times: I would write the `withResource` line, type annotate it, then figure out the inner function slowly by unwrapping and then wrapping the results...
- I'd start with something like this:

```haskell
...
res <- try $ withResource connPool handleSomething :: IO (...)
...
where
  handleSomething :: IO ... -- this is where I play with and finalze the type till compiler stops complaining
  handleSomething = undefined
```

- And then workout the `handleSomething` function by unwrapping/wrapping stuff.
- With one of the core prerequisites done, I am now going to do some work on finding out what I want the outputs to look like and how the CLI should behave. I am partly leaning towards being able to run a single command that produces a simple HTML file which I can just serve or see directly to get my "daily digest". But how would I mark the reads as reads if it's a static html file?
- Update: at the end of the day, I spent a little more time on the codebase. I was particularly looking for ways to extract some patterns out and minimize code. Somewhere, I feel like there are a bunch of utilities from the standard library that I could be using to wrap, unwrap, map over the monadic datatypes involved in the app at this point, but I couldn't really get a sense of what those would be. (The `hlint` does sometimes suggest interesting alternative options that make the code concise, without losing the readability mostly). I did realize though that I have a bunch of `try`s in the app and then I always have to handle the `SomeException` and convert it into my `AppError`... so I wrote a custom `try'` that I could use all over the place and never worry about having to convert `SomeException` to `AppError` again.

```haskell
try' :: (String -> AppError) -> IO a -> IO (Either AppError a)
try' mkError action = do
  res <- (try :: IO a -> IO (Either SomeException a)) action
  pure $ case res of
    Left e -> Left . mkError $ show e
    Right a -> Right a
```
