---
title: "Justifying a paragraph of text: Part 1"
date: 2023-06-06
slug: text-justify
# ignore: true
---

Following-up on the [leetcode stuff I was doing recently](/int-to-roman), I decided to pick up another Leetcode problem. This time, [text justification algorithm](https://leetcode.com/problems/text-justification/).

Quick rundown of the problem:

- you're given an array of words (eg `["This", "is", "an", "example", "of", "text", "justification."]`)
- and a max-length per line (eg `16`)
- and you have to space the words in such a way that the resulting text/paragraph is "justified".

The rule for spacing is simple:

- one space between words
- if that does not fit the line (length of line = 16), introduce more spaces between words
- more spaces get distributed left to right so spaces on the left would get filled / incremented first and then the right.
- the last line can be left-aligned so just one space between the words is fine.

I spent a few minutes trying to find out how to extract the collection of words that would fit a line.

That is, if this is the text:

```text
["This", "is", "an", "example", "of", "text", "justification."]
```

and the max length per line is 16,

the first line can only have `["This", "is", "an"]`.

This is because if I include the word "example", then the length of this line exceeds 16. Remember that I have to include spaces between the words as well in the calculation of line length.

I decided to park this and assume there's a function that gives me a "valid" line already and work on calculating the number of spaces to distribute to justify a "valid" line.

(A valid line is basically an array of words that can fit _within_ the max-length per line including at least 1 space between each word).

In this example, some valid lines would be:

```text
valid lines:
["This", "is", "an"]
["example", "of", "text"]
```

I decided to use a `newtype` to differentiate between any random array of words and a valid line:

```haskell
newtype ValidLine = ValidLine (Array String)
```

What I have to get to, as a first step, is this function:

```haskell
validLineToParaLine :: Int -> ValidLine -> String
validLineToParaLine maxLen validLine = ? -- to be implemented
```

After a while of thinking about this, here's one logic I came up with:

- the actual length of the line is length of each word in the valid line, and spaces between them.
- the total number of spaces (single-space) in a valid line array is simply one less than the total number of words in the valid line array.
- if I subtract the actual length of the valid line from the deficit, I get the number of extra spaces I have to distribute.

This gives me the number of spaces to distribute.

Here's an example of the logic at work:

```text
valid line        -> ["This", "is", "an"]
spaces            -> total words in valid line (3) minus 1 = 3-1 = 2
total characters  -> sum of length of each word in valid line (4+2+2=7) + spaces(2) = 8+2 = 10
deficit           -> max length (16) minus total chars (10) = 16-10 = 6
```

Okay, so now I have "extra number of spaces to distribute" in the line.

But it got tricky here as I had to find out how to distribute `x` number of spaces across `y` number of space-slots.

That is:

```text
deficit = 6
6 spaces have to be distributed in this line: "This is an".
```

Visually, it looks easy. There are just 2 space-slots. Divide 6 by 2 = 3. So each slot gets 3 extra spaces. (Will replace space with hyphen to be more clear in the representation)

```text
This----is----an
```

But what is the general logic here?

After much thought, I came up with what looks like a slightly-complicated solution.

Here's the logic:

1. First off, instead of using the "deficit" (that is, how many _more_ spaces need to be distributed besides the usual number of spaces), I combined the deficit with existing spaces so that now, I just have to worry about how many spaces to distribute in total between the words.
2. Using the "total spaces to distribute" number, I construct another array that represents the number of spaces to actually put between each word in the valid line.

Here's an example of point #2:

```text
valid line          -> ["This", "is", "an"]
total spaces to     -> usual spaces (2) + deficit (6) = 8
distribute
space distribution  -> ["----","----"]
array
```

If the total spaces to distribute was 9, then the array would look like this:

```text
["-----","----"]
```

That is, the first item will have 5 spaces and the second will have 4.

If I have this array, I could simply merge these two arrays in some way to get the final result:

```text
valid line        -> ["This", "is", "an"]
spaces array      -> ["----","----"]

justified         -> ["This","----","is","----","an"]
```

The trick is to find out how to go from a "number of spaces to distribute" to a "special spaces array".

I'll post about that in the second part.
