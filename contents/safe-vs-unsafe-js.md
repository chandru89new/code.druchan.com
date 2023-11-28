---
title: "Safe vs Unsafe JavaScript"
date: 2020-12-20
slug: safe-vs-unsafe-js
---

> TLDR: Try to catch errors early, convert errors into "data" that can safely be passed around without the fear of your app crashing. JavaScript does not provide built-in mechanisms like `Either` to do this but you can build a trivial one yourself. Make programs safe.

The other day a colleague and I got into a conundrum involving JavaScript Promises, unhandled exceptions and who ultimately should own the responsibility of handling thrown errors and rejected promises.

Here's some setup.

Your frontend architecture has three distinct layers that work like a pipeline:

- an API handler which is more or less a wrapper for a Promise-based API library like [Axios](https://github.com/axios/axios)/[Fetch](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API) which makes the calls to the backend service
- a caching layer which exposes data and functions to query and mutate the data (mutations ultimately get passed over to the API layer)
- and the app's rendering layer which consists of pages and components

One of the first places your app can "throw" an error is the API layer. For example, all HTTP responses that are in the 4xx or 5xx status zones are technically errors for Axios.

Since you export these helpers out to the caching layer, you have the option of either handling the error at the API layer and passing a "safe" data-only artefact to the subsequent layers of your pipeline, or letting the subsequent layers handle the error the way they see it fit.

Now this is a problem. Why? Because there is no standard operating procedure (enforced either by the language's built-in paradigms or by coding discipline + style-guide), any opinion on who should "handle" the error finds merit. Should it be the API layer itself? Or should it be the component/page that actually triggers the pipeline?

In our case, we also had a constraint: our caching layer needed functions that will "throw" in case of errors (in order for it to run some side-effects on error). One of the libraries being used deep inside components would also need promises that can reject/throw. So, since we were passing around promises across the pipeline, the argument went, the final consumer can do a simple `.catch` (in our case with a `noop` for the `catch`) and none will be the wiser. Long story short, we have a codebase where unhandled promise rejections are being piped across the app.

I think there's some sort of a Sapir-Whorf equivalent to programming languages as well. At a different time, I'd not think this approach is inherently risky and wrong because JavaScript does not provide built-in mechanisms to do two things that completely alter the way we think about unhandled exceptions: 1) a way to safely wrap errors so they wont crash an app and 2) a way to handle such wrapped errors and pipe them across so that they can be handled just at the level they need to be - again, without crashing the app.

My first tryst with functional programming came when I started reading about this frontend language that compiled to JS, called [Elm](https://elm-lang.org) and one of the USPs that it tooted often was "No runtime errors!" (Given how notorious JS is for runtime type errors and `undefined`s, this is a fantastic marketing tag for Elm).

In Elm, I found the ideas of what's called the `Either` (or `Result`) datatype that lets you - very safely - wrap the output of a function (like an Axios promise) even if it throws an error so that your app can continue to work without crashing. You can then inspect what's inside the `Either` - if it's a `Left`, then it's an error and if it's a `Right` then you have successful data. (And this is a concept available in all typed languages that offer some category theory sprinkling)

Of course this is not enough. You need mechanisms in the language that let you do that _inspection_ easily. That part is provided by [pattern matching / case expressions](https://www.haskell.org/tutorial/patterns.html) in many functional languages. I think our approach to solving these classes of problems is influenced by the languages we "speak". Knowing and using ideas such as `Either/Result` alters the way we look at such problems.

At Algoshelf, when I wrote the API layer for a VueJS frontend, one of the first things I did was to turn the response from Axios into a tuple of `(data, error)` (of course, represented in JavaScript as a plain array of length 2). Every function down the pipeline, then, had merely to do a case expression (`if`). Luckily, the whole architecture was designed so we didn't have to write boilerplate code for everytime we were using those functions. And the component design was such that the wrapping component would handle it for us.

The general principle here is that "data" is a safer thing to carry around and pass in your application than "error" (especially the kinds that need a "catch" mechanism). Instead, adopting a mechanism where errors are turned into data at the first instance gives us the ability to have a consistent, uniform and a safe way to inspect the contents of the data and decide if it's a successful response or an error one.

JavaScript does not provide such mechanisms out of the box but that does not mean you can't build one yourself. Libraries like Sanctuary/Folktale make it easier to get such paradigms imported into your JavaScript code.
