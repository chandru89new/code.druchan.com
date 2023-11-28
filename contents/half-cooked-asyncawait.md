---
title: "Half-cooked Async/Await"
date: 2018-04-25
slug: half-cooked-asyncawait
---

**Update (2019)**: I've changed my mind about this and prefer `async/await` over the callback-hell.

---

I wrote [a library that generates unique IDs](http://druchan.com/gen_id) of any reasonable character length.

Yes, there are possibly thousands like these. But this is a good, basic learning experience and that’s the only reason I did this.

But turns out I could then expand this into something a bit more.

And so it turned out to be a lesson in the new Async/Await thing in JS.

The `generateID(options)` function is written as a promise.

And the `Generate Id` button/link on the demo page uses the async/await method to print the result on the page.

Exactly why should `generateID()` be a promise? Why not a simple, straightforward function?

In the real world, `generateID()` is useful for generating unique IDs. Sort of like primary keys for rows of data (or documents, if you come from MongoDB).

One use-case would be to ensure that the generated ID is truly ‘unique’. That means cross-checking the generated ID with the existing ones and confirming that there’s no duplicate.

As this process takes time, I converted the `generateID(options)` function into a promise.

There may be other use-cases. I’m not aware of them, I can’t think of any other at the moment of writing this. But the one above is quite important when people use libraries to generate unique IDs.

So, in essence, this library is instantly extensible. I put in a dummy/silly function in the library as an example. `generateID(options)` will check if the generated ID contains the letter 'o’ … if not found, it will throw an error. (You can tweak this function to do something valuable instead: like check for uniqueness of the generated ID).

Here’s where the stupidity of Async/Await shows up - a.k.a it’s still immature.

Typically, I’d use a simple `generateID(options).then().catch()` kind of a code on the front-end. You would too. But there’s this async/await fad going about. So let’s try that.

When you click “Generate ID”:

I do this:

![](https://64.media.tumblr.com/bb99b5adf8ba6a66295c3d95d4352d30/tumblr_inline_p7q6j3VMJf1qbg0pd_540.png)

But `await` cannot be used like that. It _has_ to be inside an `async` function. Er… that seems stupid.

So we have to rewrite it.

![](https://64.media.tumblr.com/d54d4ee3c84fe86d16fa671000d83c9e/tumblr_inline_p7q6huq2jT1qbg0pd_540.png)

Okay this worked. But hold up. What if there was an error in the `generateID()` function itself? Like, it threw a `reject()` instead of a `resolve()`?

There’s no way async/await can handle errors. You have to manually try and catch errors. Get it?

![](https://64.media.tumblr.com/6597d56323598b1d1b5d3fdbde37b410/tumblr_inline_p7q6mbCnzu1qbg0pd_540.png)

Compare this with how you’d typically handle a promise.

![](https://64.media.tumblr.com/bf1f3df04447904ad695d78b810261ba/tumblr_inline_p7q6uucVbi1qbg0pd_540.png)

I still think the chaining is better than this half-cooked async/await thing we’re being sold.
