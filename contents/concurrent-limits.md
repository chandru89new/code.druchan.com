---
title: "A Thousand Splendid Promises – Concurrency with Limits in Javascript"
date: 2023-08-04
slug: concurrent-limits
---

Update: the solution is not quite what the problem expects. See if you can find the issue.

The other day, I stumbled on [this tweet](https://twitter.com/thdxr/status/1686856181745111040):

![tweet](/images/concurrent-promise-tweet.png)

While the tweet does say _libraries allowed_, it got me curious.

What if it said _no libraries allowed_?

There are possibly many _clever_ ways of solving it. As I thought about it, I realized that this could be a great exercise to **implement an actual concurrent promise executer that can be used for any kind of a list**!

So here I am.

First off, let's scope out what we want to do:

- run a large list of promises/async functions parallelly
- but run them in batches of X, where X = some integer
- make sure to collect all errors
- in fact, make sure to collect all values! that way, one can use this even if they want to extract all values out

To be sure, I am not aiming for brevity or cleverness here. I'm looking to build the lego building blocks (primitives) that will help us "compose" or construct the final function easily.

### Breaking down the basic structure/idea of concurrency with limitations

What does it mean to run a 1000 promises, but 25 at a time?

How can be break this down into smaller steps?

- First, split the 1000 items into lists of 25 each. That is, _make groups of X where X = 25_.
- Then, loop through each _group_ and run all the promises _inside_ each group _parallelly_.
- While doing that, make sure you _await_ the result of each group's promise run before running the next. That is, _each group should run sequentially_.
- Finally, flatten everything because we had _grouped_ a giant list into a list of smaller lists. And return the flattened results.

We need small functions/helpers to do each of these:

- we need a `groupsOf` function to split a large list into a list of smaller items,
- we need a helper that can take a list of promises, run them parallelly and return the results,
- and we need a helper that can take a list of promises and run them sequentially.

### Groups of X

```js
const groupsOf =
  (number = 0) =>
  (arr = []) => {
    return arr.reduce(
      (acc, curr, idx) => {
        const step_ = acc.step.concat(curr);
        if (idx === arr.length - 1 || step_.length === number) {
          return { final: acc.final.concat([step_]), step: [] };
        }
        return { final: acc.final, step: step_ };
      },
      { final: [], step: [] }
    ).final;
  };
```

The `groupsOf` function takes a number (the max number of items in a list), an array and then chunks the array into groups of whatever number we give it.

The logic is simple: it accumulates a `step` list till the number of items in the `step` list reaches the max number allowed. Once it reaches that, it pushes the `step` list into the `final` list and resets the `step` list. There are some checks to ensure that the if it's the last item in the array and the `step` list is not "full" yet, it still makes it to the `final` list.

Let's test this:

```js
const array = range(1, 11);
console.log(groupsOf(3)(array));
// [ [ 1, 2, 3 ], [ 4, 5, 6 ], [ 7, 8, 9 ], [ 10 ] ]
```

### Run promises parallelly and collect errors

```js
const runPromisesPar = async (promiseFns = []) => {
  return await Promise.allSettled(promiseFns.map((p) => p()));
};
```

Here, the `promiseFns` is a list of functions that return a promise.

So something like `async () => { return await something; }`.

This distinction is critical (as we'll use it again).

A promise is a value that could resolve or reject.

A promise function (in this post) refers to a function _that will return a promise when we call the function_.

So in our `runPromisesPar`, we take a list of functions that return a promise, do a `map` to _call_ each function (so we have a list of promises) and use `Promise.allSettled` to convert it into an async list of values.

In types, we go from `Array<Promise<value>> -> Promise<Array<value>>`

We use `allSettled` instead of `all` because we want to "collect" errors. `all` would crash and return the first error it encounters. `allSettled` will run every promise even if there are errors/rejections and finally return all values/errors.

Testing this:

(I made up a few helper functions to create a promise function and then a list of promise functions):

```js
const createPromise = (val, err, timeout = 100, idx) => {
  return () =>
    new Promise((res, rej) => {
      console.log(
        `running promise #${idx} with val: ${val}, err: ${
          err ? err.toString() : null
        }, timeout: ${timeout}`
      );
      setTimeout(() => {
        if (val) {
          res(val);
        } else if (err) {
          rej(new Error(err));
        } else rej("No value or error given");
      }, timeout);
    });
};

const promises = range(1, 11).map((val) => {
  return createPromise(
    val % 5 === 0 ? null : val,
    val % 5 === 0 ? "oops" : null,
    val * 50,
    val
  );
});
```

```js
> console.log(await runPromisesPar(promises))

running promise #1 with val: 1, err: null, timeout: 50
running promise #2 with val: 2, err: null, timeout: 100
running promise #3 with val: 3, err: null, timeout: 150
running promise #4 with val: 4, err: null, timeout: 200
running promise #5 with val: null, err: oops, timeout: 250
running promise #6 with val: 6, err: null, timeout: 300
running promise #7 with val: 7, err: null, timeout: 350
running promise #8 with val: 8, err: null, timeout: 400
running promise #9 with val: 9, err: null, timeout: 450
running promise #10 with val: null, err: oops, timeout: 500
[
  { status: 'fulfilled', value: 1 },
  { status: 'fulfilled', value: 2 },
  { status: 'fulfilled', value: 3 },
  { status: 'fulfilled', value: 4 },
  {
    status: 'rejected',
    reason: Error: oops
        at Timeout._onTimeout (/Users/chandrashekharv/Documents/projects/promise-concurrency/test.js:21:15)
        at listOnTimeout (node:internal/timers:559:17)
        at processTimers (node:internal/timers:502:7)
  },
  { status: 'fulfilled', value: 6 },
  { status: 'fulfilled', value: 7 },
  { status: 'fulfilled', value: 8 },
  { status: 'fulfilled', value: 9 },
  {
    status: 'rejected',
    reason: Error: oops
        at Timeout._onTimeout (/Users/chandrashekharv/Documents/projects/promise-concurrency/test.js:21:15)
        at listOnTimeout (node:internal/timers:559:17)
        at processTimers (node:internal/timers:502:7)
  }
]
```

### Run promises sequentially

```js
const runPromisesSeq = async (promiseFns = []) => {
  let res = [];
  for (let promise of promiseFns) {
    res.push(await promise());
  }
  return res;
};
```

Nothing fancy here. We use a `for ... of ...` loop, `await` every promise and then proceed to the next one, collecting results all along.

Testing this:

```js
> console.log(await runPromisesSeq(promises))

running promise #1 with val: 1, err: null, timeout: 50
running promise #2 with val: 2, err: null, timeout: 100
running promise #3 with val: 3, err: null, timeout: 150
running promise #4 with val: 4, err: null, timeout: 200
running promise #5 with val: null, err: oops, timeout: 250
/Users/druchan/Documents/projects/promise-concurrency/test.js:21
          rej(new Error(err));
              ^

Error: oops
    at Timeout._onTimeout (/Users/druchan/Documents/projects/promise-concurrency/test.js:21:15)
    at listOnTimeout (node:internal/timers:559:17)
    at processTimers (node:internal/timers:502:7)
```

If there's an error in any promise, it will crash.

Why not "handle" this too?

Technically, we could but we don't have to, in our case. Our `runPromisesPar` returns a "safe" promise – one that will never crash. And we're only going to use the `runPromisesSeq` to run the groups returned from `runPromisesPar`.

Note: In a real-world setting, I'd probably make `runPromisesSeq` not crash but short-circuit and return the error as a value instead.

### Combining all these together

```js
const runPromiseConcurrent =
  (limit = 0) =>
  async (promiseFns = []) => {
    // create the groups
    const promiseGroups = groupsOf(limit)(promiseFns);

    // promiseGroups is Array<Array<() => Promise<any>>>
    // we can only pass Array<() => Promise<any>> to `runPromisesSeq`
    // so we transform promiseGroups

    const transformed = promiseGroups.map(
      (group) => () => runPromisesPar(group)
    );
    // now transformed is Array<() => Promise<Array<any>>>
    // which is equivalent to Array<() => Promise<any>>

    // finally, run it and flatten the results
    return (await runPromisesSeq(promiseGroups)).reduce(
      (acc, curr) => acc.concat(curr),
      []
    );
  };
```

A simplified version:

```js
const runPromiseConcurrent =
  (limit = 0) =>
  async (promiseFns = []) => {
    const promiseGroups = groupsOf(limit)(promiseFns).map(
      (group) => async () => await runPromisesPar(group)
    );
    return (await runPromisesSeq(promiseGroups)).reduce(
      (acc, curr) => acc.concat(curr),
      []
    );
  };
```

[Here's a gist](https://gist.github.com/chandru89new/1f8d7d299023a04b1384ee0b50610fe3#file-index-js) of this all.
