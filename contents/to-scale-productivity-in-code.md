---
title: "To scale productivity in code"
date: 2020-12-12
slug: to-scale-productivity-in-code
---

A startup founder - let’s call him Nate - I worked with had this interesting philosophy of optimization where “automation” was a key to doing things efficiently. While PG wrote “do things that don’t scale”, Nate swung in the other direction – he would pick a thing almost only if it was scalable. And “can it be automated?” was one of the important yardsticks to see if something was scalable and, therefore, worth his time.

I think somewhere this notion is prevalent in many people. A co-founder from another startup - let’s call him Abe - exhibited this in a different way. While Nate’s automation yardstick was applied to everything in the business world (which is to say it encompassed everything from marketing to sales to engineering), Abe’s was more pronounced in the engineering department. Perhaps this is because he was more of an engineer than an overall-product person in the scope/context I knew him.

In building the frontend, Abe came up with this idea that it should be easy to “compose” not just the components we write but also an entire app with specific features disabled. Not only was it helpful in the business sense (eg feature-flagged product) but also helpful in isolated tests of complete business modules. We were building an application (think super-app) with a bunch of sub-apps in it and his idea was for anyone with bare mininum tech chops to be able to build the modules together.

That idea morphed into a philosophy for the app we built (at least to a decent degree, I think). So now I was trying not only to write a build system that would allow someone to selectively build the modules that would render in the final app but also enable people to write components that plug into the database somewhat more easily than usual. As a quick example, I wrote an entire layer that abstracted the API interactions (think Vuex Actions) and store access to a level where a simple wrapping component was all you needed to get data (along with loading, error states plus HTTP POST/PUT/DELETE handlers) to all the APIs in our app.

At the time of writing such layers of abstraction that would automate a lot of things for the developer, I was not aware of such patterns pre-existing in other frameworks (React/Apollo for instance). Now, I see that pattern in a lot of places. The crowning glory however – not to sound boastful but still – was the fact that I was able to write something from scratch which ended up saving me a lot of time.

The seed for that endeavour, which I am sure I wouldn’t have undertaken had it not been put on my desk as a requirement from who could often sound like a madman, came from Abe’s incessant need to simplify writing code by using generators, decorators, abstractions and what other ideas have you to write lesser code. In that pursuit, you usually end up writing a hell lot of code in the first few weeks of your system getting into shape and then it pays rich dividends.

If some engineer were to say, “my goal is not only to build a great product for the organization I work for but also to make my life easier and write less code”, most people would probably balk at the idea and not hire them. Yet, that is precisely the kind of ideas Abe has/had in his mind and that is what led us to build a frontend that had such levels of abstraction. A culture of “how can we create a tool here that will help us make building things easier?” should be in the minds of every engineer. While not all of us can create rich frameworks like React or Vue, we certainly can create tools with existing libraries or prior art that would help us in our everyday lives.
