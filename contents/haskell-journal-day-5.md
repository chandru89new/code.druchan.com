---
title: Haskell Journal - Day 5
date: 2024-10-11
slug: haskell-journal-day-5
---

- Quite possibly one of the worst days in the project so far.
- At first, I set up the app to be an `AppM` monad that was basically a `ReaderT config (ExceptT SomeException IO) a` — continuing from the idea from [day 4](/haskell-day-4). It was interesting and somewhat simple to execute because I had backing code from ChatGPT, and a fairly decent understanding of what was happening with the `runApp` mechanics. I had a `runApp` function that took a function of type `AppM a`, and then just ran it by passing it config like so:

```haskell
runApp :: AppM a -> IO (Either e a)
runApp app = do
	config <- ask -- gets the global app config
	runExceptT $ (runReaderT app config)
	-- runReaderT runs the app and extracts the inner monad (ExceptT e a)
	-- runExceptT then runs the inner monad and returns an IO (Either e a)
```

- Problems started brewing because all my lower-level functions were of the `ExceptT` type. At some point, the way I was doing it, running the app returned something like `IO (Either SomeException (Either SomeException ()))` — i.e., I was not passing the ExceptT context correctly.
- This had disastrous effects: errors were not being bubbled up (in my mind, that was the whole point of wrapping the app in the ExceptT monad). Instead, they were wrapped in another Either monad surrounded by the IO. Horrible. I had output that looked like this:

```haskell
Right (Left <some_error_message>)
```

- I had a long chat with ChatGPT about these things, asking it about the idea of bubbling up the errors from ExceptT without having to do `runExceptT` wherever I wanted the error to be bubbled up but the ideas it returned were not working or not useful — or in some cases, it was just reinventing the ExceptT or ReaderT monad transformers.
- But it did tell me how to actually unwrap the ExceptTs at lower-levels (using `runExceptT` of course), and then lift them in the `AppM` monad so that the exceptions bubble up and are caught at the top-most function — which is exactly what I want but not at the cost of having to run `runExceptT`s at the inner functions and then lifting them using custom lift functions.
- I had working code that did involve `runExceptT` and an interesting custom `liftEitherAppM` function:

```haskell
liftEitherAppM :: Either SomeException a -> AppM a
liftEitherAppM = either throwE return . lift
```

- As you can imagine, I spent all this time trying to understand some higher-level mechanics of the app (i.e. abstraction) rather than just working on the actual functionality and it was too late by the time I realized what I was doing.
- One other interesting thing that I noticed was that I did not google for solutions or ideas for a long time; it was almost at the end that I realized I could also just google/SO for solutions. That didn't help though. Ended up posting my questions on the FP slack.

Update: In the morning, I had the idea of looking at opensource Haskell projects to see what patterns they use. I tried Hakyll and PostgREST: both the projects seem to be just passing config to the relevant functions, so I think I will simplify the app for now to just pass `Config` (the one that has connection pool so that my inner functions that deal with DB can get a connection to work with) to the functions instead of using the `ReaderT` monad transformer until I get some more ideas and understanding of the monad.
