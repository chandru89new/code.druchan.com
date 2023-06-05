---
title: "Everything hard is easy again"
date: 2018-05-16
slug: everything-hard-is-easy-again
---
When I read [Frank Chimero’s piece](https://frankchimero.com/writing/everything-easy-is-hard-again/) on the state of web dev, I was ecstatic that someone with so much clout and know-how wrote exactly about the frustrations I was feeling - but more in the sense of not being able to make sense of all this `npm install` shit that seems to be the start of every tutorial these days than as someone working (sometimes) as a web dev.

For many months, I had been avoiding this npm and webpack route like the plague. Until I hit a point where I _had_ to work with `vue-cli` for a project (subsequently couple more projects). I still have some qualms about this new web-dev workflow that we’ve got ourselves into but I had the luxury of some quiet evenings to ponder over my initial — but long — aversion to the current state of web-dev workflows and webpacks and whatnots.

Turns out, in my specific case, there were two issues.

One, I like to know “why” and “why not something else” when someone tells me to do something. Without a convincing “why” and “why not”, I cannot wrap my head around the rest of the instruction set. Since 2015 or thereabouts, if you take a look at tutorials on web dev, almost everything is exactly like how Frank Chimero describes it:

> simply npm your webpack via grunt with vue babel or bower to react asdfjkl;lkdhgxdlciuhw

Two, I was on a hiatus and that meant I missed a big chunk of historic context on how we got here.

The first issue is a constant and is more of a good feature than an issue so that stays. (I still get pissed off at tutorials that aim to do the simplest of things but will require you to `npm install` half-a-dozen packages. If fucking packages are getting things done, why do you even bother to write a tutorial, ya nincompoop)

The second issue is something resolvable. So on one of the quiet evenings I traced the history of web dev workflows.

And that’s when everything cleared and my aversion for `npm`\-style workflow melted away.

It all starts with our penchant for economy of effort.

*   Things like package managers came to be because we started including a lot of js libraries in our projects. DRY took a stronghold (but note how the best creators are often the ones who flout the DRY rule and always build things their own way from scratch?). Handling these libraries became a chore when you had to upgrade them.
    
*   Things like bundling came to be because the benefit of minification was for all to see.
    
*   Things like transpilers and compilers came to be because we wanted to go with Python-like simplicity in CSS and OOP-like functionality in JS.
    
*   Things like starter packs are fairly simple to trace: we had ‘alias'es in our .bashrc file to create a project file, touch index.html and mkdir some folders like 'js’ and 'css’ and so on.
    
*   And finally, of course, we have things like hot reloading and live reloading and libraries that handle these - and these came to be out of this whole packaging, bundling, compiling consortium.
    

The real hard thing was a year or so ago when each existed independently. I know one project where the dev was using “bower” to manage packages, using “grunt” to serve and build the app, then there was node too to wrap all this. Imagine having to remember the commands for each (the lazy programmer would say “but there are only a handful of commands that you use constantly so it’s no big deal”).

What happend with this `npm` craze is that we managed to bundle all of these things - dependencies (a.k.a package managers), compilers/transpilers, local server setup, hot/live reloading into one nifty command-line tool.

And so, technically, everything hard has become somewhat easy again.

It still doesn’t justify the stupid tutorials that start with “install these 73 packages first and then we’ll start connecting with that API to fetch data”.