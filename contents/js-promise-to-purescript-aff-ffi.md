---
title: "Going from Promises to Aff in Purescript"
date: 2023-11-28
slug: js-promise-to-purescript-aff-ffi
---

The other day, I was fooling around with an idea that has come up often in my chats with [Jon Udell](https://en.wikipedia.org/wiki/Jon_Udell) at work. We do not have a good test suite that can verify and flag errors in the hundreds / thousands of example queries listed on [Steampipe Hub](https://hub.steampipe.io) and – since a lot many weeks had passed since I wrote some program for fun – I decided to take a shot at this. I chose Purescript.

Very briefly, the idea is to:

- "extract" the example queries from where they live (either in a markdown file in between `sql` codeblocks or in a configuration file) in a plugin or a mod repository and,
- run those queries using [steampipe](https://steampipe.io) and,
- collect and log the results.

Needless to point out, this involved running some CLI commands and reading files etc. That is to say, a bunch of `Node.*` modules in Purescript.

At first, I wrote the thing to run sequentially. This is slow but for development and quick prototyping, this was OK. This meant I could get away with `Effect` monads all the way through. Most notably, `Node.ChildProcess`'s `execSync` was very handy to run commands and grab the results without having to fall into callback traps.

The first draft ran painfully slowly because it was running validation checks on some dozen queries in series/sequence and that took a handful of minutes. The validation and logging worked – great – but so many minutes to check just _one_ plugin? That won't fly. I had to parallelize it now.

[`parTraverse`](https://pursuit.purescript.org/packages/purescript-parallel/7.0.0/docs/Control.Parallel#v:parTraverse) is a go-to for parallelizing `traverse` (and the equivalent for `sequence` is `parSequence`) but the big problem I had at this point was that all my "effect-ful" functions were in the `Effect` monad... and that monad has no `Parallel` instance. (To the uninitiated, your monad needs a `Parallel` instance to be able to use functions like `parTraverse` on it).

This meant I had to convert all those `Effect` monads into `Aff` monads.

And that's where converting `execSync` to `Aff` took me on a goose-chase.

Obviously, the first thing I tried to ChatGPT and Google was "how to convert an `Effect` to `Aff`" and the only standard library function to do this is the seemingly-complicated [`makeAff`](https://pursuit.purescript.org/packages/purescript-aff/7.1.0/docs/Effect.Aff#v:makeAff) function. I've yet to wrap my mind around that.

The other thing to try involved [FFI](https://book.purescript.org/chapter10.html) with [`EffectFnAff`](https://pursuit.purescript.org/packages/purescript-aff/5.1.2/docs/Effect.Aff.Compat#t:EffectFnAff). This seems straightforward at first and probably is to people who have successfully intuited it, but it mandates your foreign function to be in a particular shape.

In both the `makeAff` and `EffectFnAff` cases, I was able to get the code to compile (which is a great sign that your code works in Purescript) but the query validation continued to run in sequence instead of parallel.

Turns out JS's `execSync`, even when converted into a promise on the JS side and then imported into an `Aff` on Purescript via `EffectFnAff` will continue to block. (That or the way I wrote it was blocking).

Finally, I stumbled on `aff-promise` through [this post](https://blog.drewolson.org/purescript-async-ffi) and discovered a very simple way to convert Node's `exec` into a Purescript `Aff`:

On the JS side, you have this:

```js
import { exec } from "child_process";

export const exec_ = (cmd) => {
  return () => {
    return new Promise((res, rej) => {
      exec(cmd, { encoding: "utf-8" }, (err, stdout, stderr) => {
        if (err || stderr) {
          rej(err || stderr);
        } else {
          res(stdout);
        }
      });
    });
  };
};
```

which is essentially exporting a function that returns a "thunk" which returns a [Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise).

And on the Purescript side, where you import this "exec\_" as an FFI, you have this:

```haskell
import Control.Promise (Promise, toAffE)
import Data.Either (Either)
import Effect (Effect)
import Effect.Aff (Aff, try)

foreign import exec_ :: String -> Effect (Promise String)

execAff :: String -> Aff (Either Error String)
execAff = try <<< toAffE <<< exec_
```

which is essentially:

- import the foreign/JS function `exec_` as an `Effect (Promise a)` (where `a = String` in my case)
- convert the `exec_` result into an `Aff` using `toAffE` (so, `toAffE <<< exec_ :: Aff String`)
- slap a `try` onto this to catch any errors that could be thrown in the `exec_` function.

I must've spent as much time on finding a way to convert `execSync` into an `Aff` as I did writing the entire program, but c'est la vie.

I hope to move to the query extraction part – where you point a folder and the program extracts all queries it finds in the markdown or config files – in the next iteration.
