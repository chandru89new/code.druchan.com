---
title: "A tool-building mindset"
slug: toolbuilding-mindset
date: 2023-05-17
---

Everyone uses tools to build things.

Frameworks like React/Vue, libraries like Lodash/Ramda, vendor plugins etc. are
tools like hammers, like bulldozers - they are ready-made, are handy to use when
you build stuff (stuff in our case is web apps, or websites, or even modules
that may be backend-specific).

Building things gets easier with tools, yes. Faster too (at least, most of the
time).

But because these tools exist, many of us fall into a simple mindset trap: there
are tools and there are apps (ie, built stuff).

This mindset causes us to do things that are often repetitive and time-consuming
without us realizing that they are so.

Tools, it turns out, can be used to build bigger tools, better tools. Apps are
bigger tools built from smaller tools.

Bigger, better tools are great because they often save time, make your code look
and read better (better debugging, lesser testing!) and help you build things in
a much more easier way.

Eg. Take the fetch API. (let's assume we want to avoid Axios for this use case).

The fetch API is a tool to make HTTP requests, get responses and pass it down to
whatever function you have to store and process the response.

The level zero of using fetch in your project is using it as-is. Let's say you
have a page where a component lives. The page makes a call to the API, gets the
data and hands it over the component. Some pseudo code in React:

```jsx
const Page = () => {
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState(null);
  useEffect(() => {
    fetch(URL + "/something", {
      method: "get",
      headers: {
        authorization: "Bearer " + TOKEN,
        ["content-type"]: "application/json",
      },
      //...other options
    })
      .then((r) => r.json())
      .then((res) => {
        setData(res);
        setLoading(false);
      });
  }, []);
  return <Child data={data} loading={loading} />;
};
```

You can see where this is going to be a problem: your app is going to have so
many pages, making so many calls to the API, and writing this fektch.then(r =>
r.json()).then(...) is going to be a chore.

So you build an abstraction. We will skip a few steps ahead and have ourself an
async fetch wrapper - a wrapper that does three things:

1. it automatically injects the default configuration like the method, headers
   and whatnot.
2. it handles an error-code response (400s, 500s) so you don't have to do `r.ok`
   every time to check for successful responses.
3. and it hands you data at the end if everything went well.

The code for the wrapper might look something like this:

```jsx
const fetchWrapper = (url, options) => {
  return fetch(url, {
    ...DEFAULT_OPTIONS,
    ...options,
  })
    .then((r) => {
      return r.ok ? Promise.resolve(r.json()) : Promise.reject(r.statusText);
    })
    .catch((e) => Promise.reject(e));
};
```

The two explicit Promise.rejects enable us to use the fetchWrapper like this:

```jsx
useEffect(() => {
  fetchWrapper({
    url: "/something",
  })
    .then((res) => {
      setData(res);
    })
    .catch((e) => {
      console.error(e);
      // or some toast-like notification
    })
    .then((r) => setLoading(false));
}, []);
```

Let me pause for a second here. This is not about reduction in code or something
trivial like that - although this will eventually be one good reason to adopt a
tool-building mindset.

We've built a mini tool (fetchWrapper) on top of another tool (the fetch API)
which converts an unwieldy-looking, unwieldy-behaving function into a simpler
one that makes it easier for us to use it.

But we need to go further here with the fetchWrapper. It's an okay tool, but
it's not very useful yet.

Promises and async/await are great but here's the problem: if a promise fails
(ie rejects, throws an error), you have to write the "catch" function to handle
it. Otherwise, the app will crash and cause ugly UX issues.

Most developers I see have resigned to writing catch glue everywhere to handle
this. Okay, but can we do better?

Turns out, yes.

Our fetchWrapper, if you think about it, either resolves into data or rejects
into an error. That is, there are only two things that it "returns": a data or
an error.

Once again: the problem is we keep writing ".then" and ".catch" everytime we use
the wrapper. The ideal solution is - and this sort of thing always needs a bit
of imagination (sometimes bold) - that you never have to write a ".then" and
".catch". Let's see:

We could go try-catch but that is not really much different now is it?:

```jsx
try {
  const data = await fetchWrapper(...)
  // do something with data
} catch (e) {
  // do something with error e
}
```

It's slightly shorter but it is still repetition. Needless repetition.

What if the modified, better fetchWrapper could return both data and error in a
single object?

```jsx
const { data, error } = await fetchWrapper(...)
```

Wait, how come there is no try or catch?

Because fetchWrapper takes care of "catching" errors for us and returns it in a
"safe" way.

Actually, if we implement fetchWrapper this way - where it never throws or
rejects but returns an error as a simple object key - we eliminate a big class
of problems: ie, your app crashing because something at the API failed for some
weird reason.

This is not relevant for this talk but here's how the code might look. Again,
this is just pseudo code:

```jsx
const fetchWrapper = (url, options) => {
  return fetch(url, {
    ...DEFAULT_OPTIONS,
    ...options,
  })
    .then((r) => {
      return r.ok
        ? Promise.resolve({
            data: r.json(),
            error: null,
          })
        : Promise.resolve({
            data: null,
            error: r.statusText,
          });
    })
    .catch((e) =>
      Promise.resolve({
        data: null,
        error: e.toString(),
      })
    );
};
```

The fetchWrapper is still a Promise but it will never "reject". In other words,
you will never have to write a '.catch' for it and if you use async/await sugar,
you will never have to write '.then' either. Both data and error come in the
result value and if there is data, error is null and if there is error, data is
null.

In your use of the wrapper, you'll simply do this:

```jsx
const { data, error } = await fetchWrapper(...)
if (data) {
  setData(data)
}
if (error) {
  setError(error)
}
setLoading(false)
```

The bigger and better tool-building mindset is not just about saving time or
reducing lines of code. It is also about paving way for a better API for your
own internal use. Like the poor fetch becomes a better fetch and you destroy the
chance of errors crashing your app because of the API-calling layer.

Let's take another example. Most components that receive data (esp from an API
call) will need to have three states:

1. the loading state
2. the data state
3. the error state where the expected data couldn't come through We will ignore
   the empty state. Let's assume it's part of the data state.

Most of us have written this kind of stuff in every component:

```jsx
const Child = (props) => {
  if (props.loading) return <Loader />;
  if (props.error) return <div>{props.error}</div>;
  if (props.data) return <div> ... </div>;
  return <></>;
};
```

Imagine writing something similar for every single component in your app.

It doesn't look daunting at all because we're kind of used to doing it. But at
the end of the app building exercise, look back at the number of components you
wrote this boilerplate and you'll realize it's a horrendous amount of time spent
doing that.

If we apply the tool building mindset to this, we will think of a component that
takes care of rendering a loader or showing an error for all components without
us having to do it manually every time.

Here's a basic implementation in React:

```jsx
const DataWrapper = (props) => {
  if (props.loading) return <Loading />;
  if (props.error) return <div> {error} </div>;
  return <>{props.children}</>;
};
```

And we'd use it like so:

```jsx
<DataWrapper loading={loading} error={error}>
  <Child data={data} />
</DataWrapper>
```

In Vue, for example, this use case will translate to slots.

With this, all your components have to be written as if they will only have data
(or data could be null or something). You can stop wiring the loading and error
states throughout the codebase.

Of course you might want to make DataWrapper more fine-grained with more options
for things like a different-styled loader or different-styled error render but
they are trivial things to do once you build the base.

The point, of course, is this: when we walk into our workday, we already have
tools given to us, selected by us, tools that we use often, tools we've gotten
fond of, tools we swear by.

They will help you build your app, sure. But they are not built for your app -
they are built for all apps. Which means they are not crafted specifically to
make building your app easy, fast and seamless.

It is up to us and up to the app we're working on to build bigger tools using
the tools we're given to make the whole experience of building simpler, better
and smoother.
