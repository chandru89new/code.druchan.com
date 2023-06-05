---
title: "Building a useInterval hook from scratch"
date: 2023-02-09
slug: use-interval-hook
---
**TL;DR**:
- running a function repeatedly, at set intervals, is tricky in React. existing examples and libraries are all-too simple for real-world use cases (for eg, they dont work great for async functions, they dont do well with exponential backoff and they dont stop when the function being called at regular interval fails)
- you might reach for setInterval at first, but it has problems like waiting for an async function to finish before calling it again at a given interval, or to stop after a few failed calls. complexity compounds when you add a backoff to this.
- what we'll end up doing in this exercise is to build on top of two critical things – setTimeout and useEffect's "unmounting" behavior – to build a decently-robust useInterval hook that works great for both regular and async functions, and comes with a couple of extra niceties like stopping after n-retries and exponential backoff that are very useful in real-world scenarios.

---

You'll find a lot of examples online if you went looking for a way to run a function repeatedly after a delay that goes something like this:

```js
const useInterval = (fn, { delay = 5000 }) => {
	useEffect(() => {
		
		let id;
		
		if (delay === null) {
			return;
		}
		
		id = setInterval(fn, delay)
		
		return () => clearInterval(id)
		
	}, [delay])
}
```

The idea is simple:
- you create a hook that takes the function to run and a delay time
- and it uses a `useEffect` to setup a `setInterval` that runs the function after the delay
- and when the component using this hook unmounts, you clear the interval

---

There are a bunch of problems with this approach:

- What if the function you want to run is async and returns (or resolves) only after a few seconds? (Ans: you'll see function stackups if your `delay` is less than the time it takes for your async function to resolve.)
- What if you wanted to add some kind of an exponential backoff? (Ans: Not possible in the current scheme. Plain old `setInterval` is too limiting)
- Oh what if the function throws an error?! (Ans: we could simply slap a `try ... catch` but then, it doesnt solve for advanced use-cases like retrying a few times before giving up)

So let's make our `useInterval` robust by solving these problems.

**Supporting async functions**

Here's the ask: you want to run async functions repeatedly (with a delay) but you want the next-run of the function to be some seconds _after_ the first run is complete. To do this, we have to `await` our function. But `setInterval` does not care for waiting - it just keeps calling whatever you give it after a delay.

We could use  a `setTimeout` instead. Sure, the problem is it runs just once but let's see:

```js
const useInterval = (fn, { delay = 5000 }) => {
	useEffect(() => {
		
		let id;
		
		if (delay === null) {
			return;
		}
		
		id = setTimeout(async () => {
			await fn()
		}, delay)
		
		return () => clearTimeout(id)
		
	}, [delay])
}
```

Because all logic is inside a `useEffect`, we could simply force the `useEffect` to re-run after a delay - and that will call `setTimeout` again!

And `useEffect` will re-run if something changes in the dependency array. To do this, we'll just introduce a random state variable (which is just `Math.random()`):

```js
const useInterval = (fn, { delay = 5000 }) => {

	let [randomN, setRandomN] = useState(Math.random())

	useEffect(() => {
		
		let id;
		
		if (delay === null) {
			return;
		}
		
		id = setTimeout(async () => {
			await fn()
			setRandomN(Math.random())
			clearTimeout(id)
		}, delay)
		
		return () => clearTimeout(id)
		
	}, [delay, randomN])
}
```

What happens is this:
- the hook loads
- it calls the `useEffect` function
- which calls the `setTimeout` (if there is a valid `delay` value)
- in the `setTimeout`, we call the function to call (and wait for it to resolve)
- once the function is run, we clear the interval and we set a new `randomN` which triggers the `useEffect` to re-run

---

**Supporting error-retries**

But of course what's a function if it does not throw in the most unexpected way?

Error handling is simple: we just wrap the function call with in a `try ... catch` but what that achieves is not optimal. Why? Because if the function (for some reason) keeps throwing an error _all the time_, what's the point in calling it over and over again?

So we have to get the whole thing to stop if the function throws an error. We'll just be a little fancy and ask our hook to "retry" the function a few times before giving up.

That is, just two rules:
- don't blow up
- try a few times

To do this, we'll just do 3 things:
- introduce a "retryCount" state; except, we'll just use a ref for this because we don't want to re-render anything when it changes
- update the retryCount when our function errors
- and if retryCount has hit the max, we clear the timeout and stop the whole logic from running again

```js
const useInterval = (fn, { retries = 3, delay = 5000 }) => {

	let [randomN, setRandomN] = useState(Math.random())
	let retryCount = useRef(retries)

	useEffect(() => {
		
		let id;
		
		if (delay === null) {
			return;
		}
		
		if (retryCount.current === 0) {
			clearTimeout(id)
			return;
		}
		
		id = setTimeout(async () => {
			try {
				await fn()
			} catch (_) {
				retryCount.current = retryCount.current - 1
			}
			setRandomN(Math.random())
		}, delay)
		
		return () => clearTimeout(id)
		
	}, [delay, randomN])
}
```

There is a small problem with this logic though: our hook tracks retries but not "consecutive" ones. We want the hook to stop _only_ if the function throws three consecutive times.

To do this, we'll reset the `retryCount` if the function succeeds.

```js
const useInterval = (fn, { retries = 3, delay = 5000 }) => {

	let [randomN, setRandomN] = useState(Math.random())
	let retryCount = useRef(retries)

	useEffect(() => {
		
		let id;
		
		if (delay === null) {
			return;
		}
		
		if (retryCount.current === 0) {
			clearTimeout(id)
			return;
		}
		
		id = setTimeout(async () => {
			try {
				await fn()
				retryCount.current = retries
			} catch (_) {
				retryCount.current = retryCount.current - 1
			}
			setRandomN(Math.random())
		}, delay)
		
		return () => clearTimeout(id)
		
	}, [delay, randomN])
}
```


**Adding an incremental backoff**

This is a great place to be at. But more realistically, these interval-functions need an exponential backoff so that the retries are lagged by an increasing amount of delay.

All we need to do is keep track of – and use – a new delay amount everytime the function runs. We can do this by introducing a new reference or variable called `delayAmt` and updating its value when the function finishes running.

```js
const useInterval = (fn, { retries = 3, delay = 5000, backoffFactor = 1.2 }) => {

	let [randomN, setRandomN] = useState(Math.random())
	let retryCount = useRef(retries)
	let delayAmt = useRef(delay)

	useEffect(() => {
		
		let id;
		
		if (delay === null) {
			return;
		}
		
		if (retryCount.current === 0) {
			clearTimeout(id)
			return;
		}
		
		id = setTimeout(async () => {
			try {
				await fn()
				retryCount.current = retries
				delayAmt.current = delayAmt.current * backoffFactor
			} catch (_) {
				retryCount.current = retryCount.current - 1
			}
			setRandomN(Math.random())
		}, delayAmt.current)
		
		return () => clearTimeout(id)
		
	}, [delay, randomN])
}
```

And that's a complete, usable useInterval hook.

**Other improvements you could try:**

- The hook should update if the function passed to it changes
- Use this as a wrapper around popular data-fetching libraries like SWR and TanStack Query