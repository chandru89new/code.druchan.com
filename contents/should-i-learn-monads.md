---
title: "'Should I Learn Monads?'"
date: 2023-05-17
slug: should-i-learn-monads
---

Someone asked about this on reddit today and I wanted to think about this a bit.

- This is written (or thought) from the perspective of a JS developer who
  discovered functional programming as recently as 2019 and has used monads.
- This is not a tutorial on monads, by the way.

**Propriety**

I still do not profess to know monads ... but I consider that I do understand
core idea of functional monads. FWIW, I've implemented monads from scratch in
Purescript through [this fascinating resource][monad-challenges].

**Has monads changed the way I write JS code?**

Absolutely.

It's quite normal for JS developers to be okay with doing
`possibleObject.someProperty` when `possibleObject` is not guaranteed to be an
object in the first place. That is, it could be "null" or "undefined". Learning
monads and using them (the `Maybe` monad in this case) has helped me be aware of
and mitigate this risk (of property access in vanilla JS). Now, I use `get` from
[Lodash](https://lodash.com) or the fancier `S.prop` from
[Sanctuary](https://sanctuary.js.org/) depending on the project.

Functions that could throw errors (known and unknown) will need to be handled
with `try catch` blocks. The `Either` monad has helped me not only be more
conscious about such functions when I use them but also model my data structures
and pipeline functions better to handle this easily. Think of this: instead of
`try catch` all over the place, I wrap functions in a way that they will return
a tuple of `[error, data]` and I just need to check for either to be `null` to
know if the function worked or failed. No `try catch` blocks all over the place.

Monad's `bind` and `map` have helped me understand how useful such functions are
when dealing with pipelines and data transformation (which is about 80% of my
work). Maybe they are only useful when you write code in a functional-style but
the utility is enormous nevertheless.

Learning monads has also helped me quickly identify certain patterns (for
example, think of running an array of promises parallelly and then processing
the result. In JS, this is `[Promise<value1>, Promise<value2>, Promise<value3>]`
but using this data as-is is a messy business. But if you convert this into a
`Promise<[value1, value2, value3]>`, suddenly, you only have to unwrap a single
promise (via `await`) to get all the values and have fun using simple,
synchronous array functions. This idea is called `sequence` and within the
FP-world, most libraries provide this function).

**Learning monads**

While this is a completely subjective feeling, I think the best way to learn
about monads would be to actually build them from scratch.

The monad challenges were hard. I spent days solving some of them and had to
rope in some help from the FP community.

But in the end, while I came out of it battered, some of the core ideas of
monads (and why we have them in the first place) got ingrained in me. And
they've made writing and approaching problems (to be solved through code) much
easier.

**Also**:

- [Safe vs Unsafe Javascript](/safe-vs-unsafe-js)

[monad-challenges]: https://blog.curlyfri.es/monad-challenges-purescript/
