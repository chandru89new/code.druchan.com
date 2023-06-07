---
title: "Defining a valid trade using typeclass"
date: 2023-06-10
slug: max-stock-profit-leetcode-typeclass
# ignore: true
---

[In the last note posted](/max-stock-profit-leetcode), we "implicitly" defined
some valid trades.

Two data structures specifically had this notion associated with them:

```haskell
type Day = Int
type Price = Int
type StockDay = Tuple Price Day

data BuySell = BuySell StockDay StockDay
```

Two `StockDay`s could be valid only if they happen on subsequent days.

That is:

```haskell
a = Tuple _ 1
b = Tuple _ 6

c = Tuple _ 8
d = Tuple _ 4
```

In this, `a` followed by `b` can be a valid trade because the "day" order makes
sense. (That is `a` is on 1st day and `b` is on 6th day - buy on 1st and sell on
6th).

But `c` followed by `d` (and `b` followed by `d`) are not valid because the day
orders are reversed.

This notion comes into the picture when we "pair" these to make a `BuySell`
combination.

We expressed this as a `Maybe`:

```haskell
makeBuySell :: StockDay -> StockDay -> Maybe BuySell
makeBuySell t1@(Tuple p1 a) t2@(Tuple p2 b) =
  if a < b && p1 < p2 then Just (BuySell t1 t2) else Nothing
```

That `a < b` part takes care of the "valid trade" logic.

It's OK and there's no need to "improve" this...

But now, there's also this other function that we use in our computation:

```haskell
isValidTradeDayOrder :: BuySell -> BuySell -> Boolean
isValidTradeDayOrder (BuySell (Tuple _ a) (Tuple _ b)) (BuySell (Tuple _ c) (Tuple _ d)) =
  (a < b && c < d && c > b) || (c < d && a < b && d < a)
```

Here, we're trying to confirm if two buy-sell pairs are actually valid by making
sure the dates/days align. (Remember that _within_ a `BuySell` pair, the
`StockDay`s are valid thanks to our `makeBuySell` function. Essentially, a
`BuySell` represents valid, profitable buy-and-sell operation).

Again, though, in the case of a `isValidTradeDayOrder`, we're dealing with this
idea of "valid trade".

I decided (or rather, wanted to experiment) if this general idea of a "valid
trade" can be encoded into the code as a general function.

Purescript, like Haskell, allows you to define your own
[typeclasses](https://book.purescript.org/chapter6.html) and then define
instances for your data types.

So, here's a generic `ValidTrade` class:

```haskell
class ValidTrade a where
  validTrade :: a -> a -> Boolean
```

Any datatype using the `ValidTrade` class must simply describe a `validTrade`
function.

And so, here are the definitions for both the `StockDay` and `BuySell` data
types:

```haskell
instance ValidTrade BuySell where
  validTrade (BuySell (Tuple _ a) (Tuple _ b)) (BuySell (Tuple _ c) (Tuple _ d)) =
    (a < b && c < d && c > b) || (c < d && a < b && d < a)

instance ValidTrade StockDay where
  validTrade (Tuple _ d1) (Tuple _ d2) = d1 < d2
```

I also added an `infix` to help make the code a little succinct:

```haskell
infixr 1 validTrade as ??
```

Now, I could get rid of the `isValidTradeDayOrder` function in totality and
replace some instances with `??`:

```haskell
makeBuySell :: StockDay -> StockDay -> Maybe BuySell
makeBuySell t1@(Tuple p1 _) t2@(Tuple p2 _) =
  if (t1 ?? t2) && p1 < p2 then Just (BuySell t1 t2) else Nothing

bestBuySellPair :: BuySell -> SortedArray (BuySell) -> Int -> Maybe BestCandidate -> Maybe BestCandidate
bestBuySellPair buySell (SortedArray []) maxProfitSoFar bestTradeSoFar =
  if buySellProfit buySell > maxProfitSoFar then (Just $ Tuple buySell Nothing)
  else bestTradeSoFar
bestBuySellPair buySell (SortedArray tradePairs) maxProfitSoFar bestTradeSoFar =
  case head tradePairs of
    Just h ->
      -- notice the ?? here. we've replaced the `isValidTradeDayOrder` function with ??
      if ((buySell ?? h) && (buySellProfit buySell + buySellProfit h) > maxProfitSoFar) then bestBuySellPair buySell (fromMaybe (SortedArray []) (map SortedArray $ tail tradePairs)) (buySellProfit buySell + buySellProfit h) (Just $ Tuple buySell (Just h))
      else bestBuySellPair buySell (fromMaybe (SortedArray []) (map SortedArray $ tail tradePairs)) maxProfitSoFar bestTradeSoFar
    Nothing ->
      if buySellProfit buySell > maxProfitSoFar then (Just $ Tuple buySell Nothing)
      else bestTradeSoFar
```

And the script continues to run just fine:

```bash
> totalProfits [3,1,0,0,5,4,1]
5

> totalProfits [3,1,0,0,1]
1

> totalProfits [3,1,0,0,1,2,3]
3
```
