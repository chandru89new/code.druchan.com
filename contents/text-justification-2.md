---
title: "Justifying a paragraph of text — Part 2"
date: 2023-06-07
slug: text-justify-2
ignore: true
---

Read [part one here](/text-justify).

In the first part, I had this problem to fix:

> The trick is to find out how to go from a "number of spaces to distribute" to
> a "special spaces array".

I worked through a few examples to get an intuitive feel of how the logic could
look like:

Suppose there are 7 spaces to distribute in 3 slots:

```text
spaces to distribute        -> 7
slots                       -> 3
```

I could first distribute equally by dividing the two (integer division):

```text
equal division        -> 7 / 3 = 2 (remainder 1)
                      -> ["--", "--", "--"]
```

And then distribute the `remainder` left-to-right:

```text
equal division        -> 7 / 3 = 2 (remainder 1)
                      -> ["--", "--", "--"]
with remainder        -> ["---", "--", "--"]
distributed
```

I tried to run some more examples for this. Like this:

```text
spaces to distribute  -> 15
slots to distribute   -> 4
equal distribution    -> 15/4 => 3
                      -> ["---","---","---","---"]
remainder             -> 3
remainder distributed -> ["----","----","----","---"]
```

This still did not give me a clear grasp of the distribution logic.

Eventually, I came up with this idea: I could have a function that gradually
"builds" the array of spaces from an empty array.

It would do this by "remembering" and "updating" the number of extra/remainder
spaces it has to distribute across the slots.

So, something like this:

```text
example: 15 spaces, 4 slots

step 1: empty array ([]), number of slots to fill (4), number of remainders to distribute (remainder 15/4 = 3)
step 2:
  - push the first space slot into the array [?]
  - where ? = normally, just the equal distribution of space.
  - in this case, that's 15/4 quotient = 3. so => [3]
  - but the number of remainders to distribute is more than 0,
  - so we just add 1 more to the fill => [4]
  - now that we've filled the first, we have to reduce number of slots to fill to 3.
  - also, we've distributed 1 of the 3 remainders to distribute so that also becomes 2.
step 3:
  - repeat the above step for the next slot,
    but remember that we only have 2 remainders to distribute and 3 slots to fill.
...and so on...
```

Doing this "recursively" gives us a final array of space slots.

The function looks something like this:

```haskell
import Prelude

import Data.Array (snoc, catMaybes)
import Data.Int (quot, rem)
import Data.String.Utils (repeat)

makeSpaces :: Int -> ValidLine -> Array String
makeSpaces maxLen vl =
  let
    d = deficit maxLen vl
    spaceSlots = numberOfSpaces vl
    totalSpaces = d + spaceSlots
  in
    makeSpacesHelper [] (quot totalSpaces spaceSlots) (rem totalSpaces spaceSlots) spaceSlots
    # map (\a -> repeat a "-")
    -- note: I'm using hyphens for demonstration
    -- use space in the real program
    # catMaybes

makeSpacesHelper :: Array Int -> Int -> Int -> Int -> Array Int
makeSpacesHelper xs _ _ 0 = xs
makeSpacesHelper xs n incCount timesCount =
  makeSpacesHelper (snoc xs a) n (incCount-1) (timesCount-1)
    where
    a = n + (if incCount > 0 then 1 else 0)
```

In this:

```
incCount => the remainders to be distributed
timesCount => number of slots to be filled
```

I've used a bunch of helper functions in the above code like `deficit`,
`numberOfSpaces` and some library functions like [`catMaybes`][catmaybes].

Here's definitions for the helpers:

```haskell
import Data.Array (length, foldl)
import Data.String as Str

deficit :: Int -> ValidLine -> Int
deficit maxLen vl = maxLen - (totalCharLength vl)

numberOfSpaces :: ValidLine -> Int
numberOfSpaces (ValidLine xs) = length xs - 1

totalCharLength :: ValidLine -> Int
totalCharLength (ValidLine xs) =
  foldl (\b a -> b + Str.length a) 0 xs + numberOfSpaces (ValidLine xs)
```

Testing all of this:

```bash
> makeSpaces 16 (ValidLine ["this","is","an"])
# that is max length is 16. valid line has char length = 10.
# deficit = 6. Total spaces to distribute is 6+2 = 8. Across 2 slots.
["----","----"]

> makeSpaces 19 (ValidLine ["a","b","c","d","e"])
# that is, max length is 19, valid line has 9 characters length, so deficit is 10.
# Total spaces to distribute is 10+4 = 14. Across 4 slots.
["----","----","---","---"]
```

All we need now is a way to mix an array of strings (from the `ValidLine`) and
this spaces array such that the words and spaces are interleaved.

I checked Purescript's Array package and found a `transpose` function that fit
the need perfectly:

```haskell
transpose :: forall a. Array (Array a) -> Array (Array a)

{-
The 'transpose' function transposes the rows and columns of its argument. For example,

transpose
  [ [1, 2, 3]
  , [4, 5, 6]
  ] ==
  [ [1, 4]
  , [2, 5]
  , [3, 6]
  ]

If some of the rows are shorter than the following rows, their elements are skipped:

transpose
  [ [10, 11]
  , [20]
  , [30, 31, 32]
  ] ==
  [ [10, 20, 30]
  , [11, 31]
  , [32]
  ]
-}

```

So I could just put the array of valid lines and array of space slots into
another array and then `transpose` them.

```haskell
import Data.Array (transpose, concat)

specialIntercalate :: forall a. Array a -> Array a -> Array a
specialIntercalate xs ys = transpose [xs, ys] # concat
```

Mixing these so far:

```haskell
validLineToParaLine :: Int -> ValidLine -> String
validLineToParaLine maxLen (ValidLine xs) =
  specialIntercalate xs (makeSpaces maxLen (ValidLine xs))
  # Str.joinWith ""
```

And the test:

```bash
> validLineToParaLine 19 (ValidLine ["a","b","c","d","e"])
"a----b----c---d---e"

> validLineToParaLine 16 (ValidLine ["This","is","an"])
"This----is----an"
```

All that remains now is getting `ValidLine`s out of the given array of words.

I'll write about that in the next part.

[catmaybes]: https://pursuit.purescript.org/
