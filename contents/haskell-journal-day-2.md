---
title: Haskell Journal - Day 2
date: 2024-10-08
slug: haskell-journal-day-2
---

- The tool initially handled a single URL and returned the feed link, but I needed it to work with multiple URLs since I had a lot of YouTube channels whose RSS feed links I wanted.
- The easy solution: pass a file to the tool, where the file contains one YouTube channel link per line. The code would then process each link, fetch the feed link, and finally write all the results to another file.
- This was straightforward to implement—I simply used `mapM` over the existing function that scraped and extracted the feed link.
- I asked ChatGPT if there was a more efficient, concurrent way to perform the mapping instead of `mapM`, and it suggested `mapConcurrently` from the `async` library. I added it and tested the execution times. However, there wasn't much difference between `mapM` and `mapConcurrently`. I suspect I might not be using it optimally.
- I spent some time experimenting with extracting additional data (such as the channel title, avatar, etc.), but I ultimately decided to stick to just extracting the feed link since this was intended to be a one-time operation.
- I realized that I wasn't handling file I/O errors properly when reading the list of URLs or writing the feed links. The code was just performing `IO a`, which could crash if there was an issue (e.g., an invalid file path). I decided to look into using `try` from `Control.Exception`—something I had used before in Purescript.
- I struggled with how to handle the exceptions and where to handle them. The types were now `IO (Either SomeException a)`, and I had to write several pattern matches (inside `do` blocks) for the `Left` and `Right` cases of the `Either`. I asked ChatGPT for ways to reduce this boilerplate, and it suggested using the `either` function, which wasn't as helpful as I hoped. I decided to revisit this later.
- I tend to trip up when dealing with `IO (Either ...)` types because I can't always tell where the code is in the `IO` context versus the `Either` context. My current approach involves trying every combination until the compiler stops complaining.
- After setting up the functions and testing them, I could finally implement the final feature—getting the tool to accept a `--path` parameter instead of a `--url`. This involved adding another pattern match in the code for `("--url" : url : _)`, but also required differentiating between a URL and a file path. A custom `data` type for the arguments helped here.
- Day 2 was interesting—it made me realize that I need to build error handling into my data types and functions from the start. The `IO (Either e a)` type is not ideal; I need an abstraction over it. The tool can now handle both single URLs and a file path containing multiple URLs, and it writes the feed links to a file.
