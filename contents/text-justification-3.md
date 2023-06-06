---
title: "Justifying a paragraph of text: Part 3"
date: 2023-06-08
slug: text-justify-3
ignore: true
---

Read [part one here](/text-justify). Read [part two here](/text-justify-2).

In the last part, I left here:

> All that remains now is getting `ValidLine`s out of the given array of words.

I just got around to writing the function that converts an array of strings into
an array of valid lines that I can then pass/process through the
`validLineToParaLine` function I wrote in part two.

```haskell
validLineToParaLine :: Int -> ValidLine -> String
validLineToParaLine maxLen (ValidLine xs) =
  specialIntercalate xs (makeSpaces maxLen (ValidLine xs))
  # Str.joinWith ""
```

Here's how I approached the validline generation. I was going to rely on an
accumulating recursive function (very common in functional/recursive programs):

1. The function I'm going to write will keep track of a current valid line, a
   final array of valid lines, and the list of words to process.
2. As a base case, if the list of words to process is empty, it's simply going
   to concatenate the final array of valid lines and the current valid line and
   return the whole thing. That will be my final valid line list!
3. If the list of words to process is not empty:

- I'm going to pick the first element from the words list
- and then I'm going to add it temporarily to the current valid line that the
  function is carrying around
- and check if the total length of this temporary valid line is less than the
  max-length
- if yes, I will recurse again on the function, passing as the list of words to
  process the tail of the list (because I've already picked out the first
  element)
- if not, I will just add whatever's current valid line to the final valid lines
  list, and recurse on the function, passing in existing list of words (because
  I did not use the first element) and also emptying out the current valid line
  because a new valid line is going to form.

In code:

```haskell
listToValidLines :: Int -> Array String -> Array ValidLine
listToValidLines maxlen xs = helper (ValidLine []) [] xs
  where
    helper :: ValidLine -> Array ValidLine -> Array String -> Array ValidLine
    helper (ValidLine acc) final [] = snoc final (ValidLine acc)
    helper (ValidLine acc) final ys =
      case head ys of
        Maybe.Nothing -> helper (ValidLine acc) final (Maybe.fromMaybe [] $ tail ys)
        Maybe.Just wrd ->
          let
            tempValidLine = snoc acc wrd
            lengthTempValidLine = totalCharLength $ ValidLine tempValidLine
          in
            if lengthTempValidLine > maxlen
              then helper (ValidLine []) (snoc final (ValidLine acc)) ys
              else helper (ValidLine tempValidLine) final (Maybe.fromMaybe [] $ tail ys)
```

There's a bit of a `Maybe` wrangling because I'm using `head` and `tail`, but
it's OK. The code is safer.

Now that I have a function that converts an array of words to an array of valid
lines, I can simply map over this list to generate a list of justified lines!

```haskell
justify :: Int -> Array String -> Array String
justify maxWidth = listToValidLines maxWidth >>> map (validLineToParaLine maxWidth)
```

`maxWidth` is the same as max length of a line.

I could've written it this way too:

```haskell
justify :: Int -> Array String -> Array String
justify maxWidth xs = listToValidLines maxWidth xs # map (validLineToParaLine maxWidth)
```

Time to test:

```bash
> justify 16 ["This", "is", "an", "example", "of", "text", "justification", "folks,", "okay?"]
["This----is----an","example--of-text","justification","folks,-----okay?"]
```

We can join this text with "\n" to get a paragraph:

```haskell
justify 16 ["This", "is", "an", "example", "of", "text", "justification", "folks,", "okay?"] # joinWith "\n"
```

```text
This----is----an
example--of-text
justification
folks,-----okay?
```

The last rule in the puzzle was:

> the last line can be left-aligned so just one space between the words is fine.

I think there are a couple of ways to accomplish this.

I could have used an indexed map in `justify` function to not justify the last
item in the array of valid lines.

Or I could simply use regex to replace all multilpe spaces (ie, one or more
spaces) with just one space in the last line.

Those are trivial, so leaving it here for now.

---

You can play around with
[the full-code here](https://try.purescript.org/?code=LYewJgrgNgpgBAWQIYEsB2cDuALGAnGAKEJWAAcQ8AXOABQKgjCJPMpoBEkqkA6AMRBQwSAEaw4ACgBmQsAEpWFanC49eAZRjAUAczwgIZKQGMoSAM4W4WnfsNlFpZTQCi06TBM1J7z96c2FQAVPABPWggCDRM8FDIfbABGABo4bAAmNLI0k3AYNKoYAA8qNKgUCzK4dGY0aoq0AGs0gjRmPECXVW4%2BADkYTCowsnhJM0trAaGRmC72HvUAQTw8JDCpWDRdKmw02WEoNIs0EBNc7mQw0RgLXJA0E25CtbQLCgsC9JgkMELUKDzFRqPgaKhxbZwSw2cFKBYg3gASXqUgAjhAQNUCMAgZxeppwehdLwAKpUFBQaySAijbi4xZ8K43KHWJksQjAVAYAC8cDaHTgABI4MZxvkhXAiqUJRZsCBMBKAFYQKooaQbTnFADqKDAuzgFiQ5FgABlKlRFBykNrdfreUkAGzENCDYajOAANSQFTAZpdcF5Xp9frGKzWGzBEN0lsNxpgZqqcAAXEm4GH1jCo4RY2RTeaA3AANoAImC2EqxbSxYrVaQaErcGLJSNuZgDeLIGk7alVHbytV0hQT3JD3bByad3bICa6wA-MWALrEAC0y893t1IZq1jrUNWGc7BsJ2wshFXWDln0lmO9cC2O2w27Pa9gVkl2F3u3gmp1euwxA6FAADd4BdGZ3XQKo6xMeBZXlINN3QeAUxsOUFQQ30kJXNdAJAuAwLdeBIJ4R5YO0FAowwrcUNsPQDCMddgyw584Fw0DXVmGo3hImC4FAU5dSopDk1TBAHhAXVGMQl1iCAjdMJdYIQFoJA1mo1NkRoZcAD4pIU%2BAdMzIlCDkpjFOU1SkC3TUTRgDBJCE-1igseQC0IOADVGEwUG9TT8CecwijgZypE5JoYA0MgkBg6wbLsqRHPgZz5EUDyAGJM14RUJLQHV9WLYtnQgYAbjwAB5aRIui24RL0rdDM0wg0GK0qKqqmKEvkrdkoLe99RCtckmIKgbygABhD88Fs7Z9RQxK4AalFCBGnhxsm6aH06sykpcgsDjAKApAAHVEKEFt006AGpMr6x8kFcgAGYLrGu5qSvwNqoo6hyuuE5KAJgQdvJoFDNPOurhMWqhCGYIGUBoOKMCAw7eURhapBW70JtUjb9WRy0woir7bgACRgKBRjwWr0w2MGofBundMZtN91p%2BorXC9rSfJynnrgAB9AW4Ce3lnI5onqosMmKfwPmMHQEwxsMFFyWAW4lYgFFeXcvikE54mpZ52XJBOM4%2Bfu-CpAVjX6mXJJXMkVX1eVqg7dSjyL3wIgPbO3kMGuyQ1S4xWXbgXSnq-DAkjgcmrwe92PPFrnrFBlFDPmwyaaM7Yk4N3XimmuBkbcjzYBoHWPLAAtYaHeH88L5GK886qNCgTFrD9lqPsqvPG59zGoGT6u4Gu94W7bqhTw89Am8J5Ppd5wsFzRDEaAHoex5g1v24d7Fr1Wjfie3yfXM3iKJ6nj2Ms5UUjqQcGaR%2BGh7%2BLZdiwTuAMuHNlL8Tn3sy8j5KAfk8ABW4MhVMsg1hQEOnwFm4YzqZ1Zog3SWckAAK8EAkBYCgohTCB3SUrx3ggCvIWZyaR8HLy-g8YcxAKhVCUolFOGk06oOQZGIk4Ms6JUIPQqgjDfoulitaLYfNeS4BllTH620iwLlckvZ6OscBezgE3CRvM5qCIMmwhBGcdEZg4ZCJBuitFqKNlI%2Ba0UTCuUHGgW8CjeSmxMHAWxt5pHSXgFYj%2B6jjaWJMNYlx6Bbz4IDE3DyTwry4F%2BHAEJh4wkezZLwPomJyxGN0j4ixWioT%2BJsUEw6khEnSAMMANksiJQ8ApDEly8SPKJIAFIqhoJgPAVdDI1I9mXdp-dtBkHmo404zirFYBaV0jpdkHzBB6X0-eWN1rjP1MKeaRRyA8J9msriqj1nrKDrdSZKysm6U1FsUZ-dcAYAyVtDxsiHZOMCXY-JfjrGuXwScj2sd4AXPcfpSUUytG5PuVIQpxTSkKOFBUw6%2BDLSEH7OSdUtVmZZ0MboLh7Djy6GhY0tUGprS-jtHec0AjtrCJtH%2BMO2lDlIFFKZDxSkVJqWEj%2BW02AoXECAA).
