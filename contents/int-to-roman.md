---
title: "Integer to Roman: Purescript version"
date: 2023-06-05
slug: int-to-roman
---

Decided to pick a Leetcode puzzle last night to solve in Purescript.

I did a couple of them but here's one that I liked.
[Converting an integer (under 3999) to Roman numerals](https://leetcode.com/problems/integer-to-roman/).

The basic rules are these:

1. Roman numerals are represented by seven different symbols: `I`, `V`, `X`,
   `L`, `C`, `D` and `M`.
2. There's a table on the puzzle page that shows what these symbols mean. For
   the most part, it's simple. Things change at 5, 10, 50, 100, 500 and 1000.
3. And then there are special rules for 4, 9, 40, 90, 400 and 900 which are
   represented with a slightly different algorithm. (Eg, 4 is not `IIII`, it's
   `IV` and 40 follows a similar logic, so it's `XL` – that is, 10 less than
   50).

**The basic idea:**

Say, the number to convert into Roman is 23.

I could split that as 20 + 3 (so we know what numbers show up in 1s, 10s ... and
so on places).

Then, I can "translate" the numbers like so:

```text
23 -> [2x10, 3x1]
      [XX, III]
      [XXIII]
```

But if I have a 4 or a 9 somewhere, I need to use a slightly different
representation:

```text
49 -> [4x10, 9x1]
      [XXXX, IX] -> wrong
      [XL, IV] -> correct
      [XLIV]
```

So for each place (1s, 10s, 100s, 1000s), there are special rules for the
numbers 4, 5 and 9.

Come to think about it, there are also special rules for numbers greater than 5
in each place.

In 1s place, any number greater than 5 but less than 9 is represented as (Roman
for 5) + (Roman for difference).

Eg, 7.

```text
7 -> greater than 5 by 2.
  -> Roman for 5 + Roman for 2
  -> V II
  -> VII
```

The same kind of a rule applies for 70 too but now, the application changes a
little:

```text
70  -> greater than 50 by 20
    -> Roman for 50 + Roman for 20
    -> L XX
    -> LXX
```

So I realized that the best thing to do (given the limitation that the larger
number to convert could only be 3999) was to just write replacement rules for
each place in the decimal system.

Here's the replacement rule for the unit (1s) place:

```haskell
import Prelude
import Data.Maybe as Maybe
import Data.String.Utils (repeat)

process1sPlace :: Int -> String
process1sPlace x
  | x == 4 = "IV"
  | x == 5 = "V"
  | x == 9 = "IX"
  | x < 5 = repeat x "I" # Maybe.fromMaybe ""
  | x > 5 = "V" <> (repeat (x - 5) "I" # Maybe.fromMaybe "")
  | otherwise = ""
```

As you can see, the logic is kind of straightforward:

- for 4, 5 and 9, we have special cases. I just directly convert them into their
  corresponding roman numeral,
- for anything less than 5, I just repeat `I` as many times,
- and for anything more than 5, I prepend a `V` and then repeat `I` as many
  times as the difference.

The `repeat` function from `Data.String.Utils` returns a `Maybe`, which explains
why I use a `fromMaybe` to unbox the data.

These are the functions for the rest of the places:

```haskell
process10sPlace :: Int -> String
process10sPlace x
  | x == 1 = "X"
  | x == 4 = "XL"
  | x == 5 = "L"
  | x == 9 = "XC"
  | x < 5 = repeat (x) "X" # Maybe.fromMaybe ""
  | x < 10 = "L" <> (repeat (x-5) "X" # Maybe.fromMaybe "")
  | otherwise = ""

process100sPlace :: Int -> String
process100sPlace x
  | x == 1 = "C"
  | x == 5 = "D"
  | x == 4 = "CD"
  | x == 9 = "CM"
  | x < 5 = repeat x "C" # Maybe.fromMaybe ""
  | x > 5 = "D" <> (repeat (x-5) "C" # Maybe.fromMaybe "")
  | otherwise = ""

process1000sPlace :: Int -> String
process1000sPlace x = repeat x "M" # Maybe.fromMaybe ""
```

Note that for the 1000s place, I just repeat `M`. We're not dealing with numbers
greater than 3999 so this solution works.

Well, now I have the logic to process each number based on which place it is on
the decimal system but that leaves me with one other problem: How do I actually
split a number into its corresponding number + decimal place?

As an example: 437.

```text
437  -> 4x100s, 3x10s, 7x1s
```

Turns out, this one I'll have to work in reverse.

1. If I divide 437 by 10, I get 43 as the quotient and 7 as the remainder.
   Hurray, I was able to "extract" 7 out.
2. If I repeat the division by 10 on the quotient 43, I now get 4 as the
   quotient and 3 as the remainder! Hurray again: I've extracted the 3 out.
3. Repeat this again and I'm left with 0 as quotient and 4 as remainder -> i.e,
   extracted the 4 out too!

But wait, I also have to remember which decimal place each number belonged to.

I could do this by _keeping track_ of the number of times I'm dividing by 10.
The first time, it's 1s place, the second time, it's the 10ths place and so on.

The logic seems okay but I have to think of a nice data structure that can hold
this information. (Side quote: _Good programmers worry about data structures and
their relationships._ - Linus Torvalds)

I thought a Tuple would be best. So:

```text
437 -> [ (4,100), (3,10), (7,1) ]
```

seemed like a nice representation that I can work with. (Remember the place
functions above: I can use the Tuple to know which place function to pass the
number through!)

So here's the code I wrote to represent the data and also split the number into
the data type:

```haskell
import Data.Tuple as Tuple
import Data.Int (rem, quot, pow)
import Data.Array (snoc, reverse)

type Group = Tuple.Tuple Int Int -- the data structure

splitter :: Int -> Array Group
splitter x = reverse $ go (quot x 10) (rem x 10) 0 []
  where
    go :: Int -> Int -> Int -> Array Group -> Array Group
    go quotient remainder power acc
      | quotient == 0 = snoc acc (Tuple.Tuple remainder (pow 10 power))
      | otherwise = go (quot quotient 10) (rem quotient 10) (power + 1) (snoc acc (Tuple.Tuple remainder (pow 10 power)))
```

The `splitter` takes a number and starts doing the logic I discussed above.
Divide by 10, save the remainder and the decimal value (by using the power
function) and repeat till the quotient is 0.

And finally it `reverse`s the list (because I worked backwards).

As a test run:

```bash
> splitter 437
[(Tuple 4 100),(Tuple 3 10),(Tuple 7 1)]
```

Okay, now I just have to take each Tuple and then:

- use the second part of the tuple to find out which place function to use
- and use the first part of the tuple as input for the place function

```haskell
groupToRoman :: Group -> String
groupToRoman (Tuple.Tuple num place)
  | place == 1 = process1sPlace num
  | place == 10 = process10sPlace num
  | place == 100 = process100sPlace num
  | place == 1000 = process1000sPlace num
  | otherwise = ""
```

At this point, just wanted to note how amazing the destructuring and guard
syntaxes are in Purescript/Haskell to be able to write such succint functions
that read like math expressions easily.

Now that I have this function to process a Tuple, I can use `foldr` to simply
walk over a list of tuples and join them:

```haskell
-- all other imports
import Data.Array (snoc, reverse, foldr) -- modified to add `foldr`

arabicToRoman :: Int -> String
arabicToRoman x =
  splitter x
    # foldr fn ""
    where
    fn grp acc = groupToRoman grp <> acc
```

And to test:

```bash
> arabicToRoman 437
CDXXXVII

> arabicToRoman 3789
MMMDCCLXXXIX

> arabicToRoman 7
VII
```

And that's it.

The fun bits was trying to break the logic into small chunks that can be
expressed cleanly in Purescript and then the composition.

**Behind the scenes**

- I initially thought I could use a look-up table for the 4, 9, 40, 90...
  special cases. But that seemed to create more complexities.
- The lookup table also failed because the rules change at the 5 mark (5,
  50, 500) for each place: it becomes a representation of Roman for 5/50/500
  plus the roman for the difference.
- Also, a lookup table would've introduced a lot more `Maybe` unwrappings, which
  could clutter the code.

You can see/hack around with the
[full source here](https://try.purescript.org/?code=LYewJgrgNgpgBAWQIYEsB2cDuALGAnGAKEJWAAcQ8AXOABQKgjCJPMpoFEAzLmAYxoAKbrwEBKVhWpwAKngCetCAQDKfPCjJDsARgA0cbACYDZA1RgAPKgagoAzjbjpmaJ3bQBrAwTTM8BnzgMBKkUjQAIkhUSAB0AIJ4eEjycIL2aCB8BlwgUGABcAQAbvj2IZLscFExscjyAEbwSPaIKU2V0jVxAJJuaQTABgCOECBOFJihbF3RcSpUGmgA5rEAqlQoUK2CBGQw0dPh1XOxMhBksHAtshewhAC0D84zkacAYnlgSA1Xgrn5PASQjAVAYABc4LgIn4NDWaBQVBBYLgAF5CHAijA-Pg4AASQw6NIWaz467JBooPgyEAAJRAoIwAGYAOwADgAnBJMU8sTi8GTdMSrDQCfZsCBMGT7JdERYBQAWVncuCEMh4LIwez2HT2WhQJB8eCQuB9GgPAB8cAWS2Wao1Ru1uv1hvgllVmIAPnB3ajUXAFWi4AAiHoANWDGLg3t9-oArEHgxGozG0f6OYmegANSNen1wAA8cAT-r2Bxo7tDwbgAGI2o0YLEuBrgPUmiHc9H81aSyGI4WrbsYPtoml3c842IQz1q3W243mwz5x2Vd7xrg8JgHPB-cHI-bNU6AAx6g1GuAms1wS3WxboO3qw86k8u8-ulP5v1wIm7nMf2MBomWYADKdqmX69sGoH-mmcAZr%2BADCYH5kWvZlqOgiWFOwY5rW9ZNE2LbLnuMFFjoR6JqBA4DMO5Zjg8k4hrhc7tAuRGsSuH7rvgW7lImnYHo6z4vmexpQleN42veglasJp6uvmMFfj%2BIZIUp8aJhEyEAYGu4IVp6lwYmCEINphbFkG6EVqps74WxS4cSRebuj2mnVgWg5WfRjHBkheHzoRDkNpxebcZu278VGMnHkeIkKZe-SSXeKzRcJcVvpZtGjpWpn%2BaxgWto5%2B5UPI%2BxwAA4hqFxBuclyNrVVxXmaxAynYVDyhe4mJVaiTJKklUgBchCtXKuK%2BlipR4HxBLLCAaSjOM%2BbkVOQ7AEtR5ThRADaAC6UY4Pg8BRpis2daa3XneaVoST1SQpBVVVkNet19Q9g1kMdcCnQtmzYjQgxgv4cCTLihp8B6mKQ96P0oH9sEUf6GRZNcfDg4IDX1Xc8AAy4uKCJM34USDQIqpDXZhbxO5fXNgg-XAMNw8tNFrQz-RM-jkq4gA1N%2BK1I%2BDYNpBjZxY1ioK4wKHNSuRwOcyTKqfYQyyPTS9KMmdA3VUltpKyrdIMkgGDo1jIt1XAaAQGtlyuquwOibBKmPkJzr2xbwAftb57KQjwMOrJ5Hyeebse-b3s%2B07-uxYH8DB3mns7v65GxUGEcxelMeW1xVAbpTkWYoQSAUlSqsGxCXVXbeOuFz8xf6%2Br41RiN7VjZ9dYAgUcBcBgTmQwdBCfV3X14E9gv%2Bsr70l%2BrytPR5KN8Ir48XDSUkrBrj3PZX0mL2Qy-JcsQsmxj1xwA0U67oI7lWuKkrH7PwYGJfcDX1KDTUcGYidvnvLb71KS77aZ1f79XXtraS39HpAP-veH0rR-TtygJ3bu1ZLD2EeM8TEfd4CD1fkgIM28oGr1wXfSEj8GiKzJuQyGn0gA).
