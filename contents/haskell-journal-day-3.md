---
title: Haskell Journal - Day 3
date: 2024-10-09
slug: haskell-journal-day-3
---

- I reflected on the project so far—it fetches RSS links for all the channels I'm subscribed to. But I could pivot and make this into a tool that works more like an RSS feed reader, or better yet, a way for me to get a "daily digest" from all the websites I want to track (using their RSS feeds).
- This idea sounds great because it allows me to play with databases as well. I’d have to store the data in a DB (leaning towards SQLite), and then fetch the "daily digest" data from there.
- This meant I needed to parse XML from RSS feeds and extract at least the following: **title**, **original link of the post**, and **published or updated date**.
- After looking around, I found **TagSoup** to be the best option (Scalpel didn't seem like the right fit since it's more focused on HTML than XML).
- I asked ChatGPT for an introduction to **TagSoup**, which gave me an idea of the main functions to use. Armed with this info, I dove into the documentation and found a few more helpful bits.
- It took a few tries to get things right. I created a dummy XML file to test on, and I had to extract the title, link, and updated date. **TagSoup** has some nice operators and combinators. After about an hour, I managed to extract all feed items from the given XML (though now I realize it’s specific to YouTube's RSS feed—other feeds have different tags for their items… this will be another problem to solve).
- The tool has now morphed—it no longer extracts feed links from YouTube channel URLs. I removed that functionality since it was a one-time need for me (specific to YouTube channel feeds).
- I'm now thinking of refocusing the tool to perform tasks like:
  - Adding a feed to the database (`./app --add-feed <feed_url> --other-args`).
  - Running and fetching the daily digest (`./app digest`).
  - Managing the feeds stored in the DB with additional commands.
- Another thought: I used **Scalpel** for extracting info from YouTube subscriptions and for fetching the RSS feed link. I could potentially use **TagSoup** and **html-conduit** to handle these tasks and remove **Scalpel** as a dependency. However, since the YouTube-specific code is likely one-time use, this might not be necessary.
- Another discovery today, though I haven't fully explored it, is the use of **EitherT** and **ExceptT** monad transformers, which could simplify handling `IO (Either e a)` types. I had used these in my PureScript project (which manages my blog) but had forgotten about them. I asked ChatGPT, and it reminded me of monad transformers.
- Day 3 has opened up a lot of new possibilities for coding!
