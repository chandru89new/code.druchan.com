---
title: "Another Leetcode episode in Purescript"
date: 2023-06-09
slug: max-stock-profit-leetcode
# ignore: true
---

Lately, I've been enjoying solving some Leetcode problems [as][leet1] [is][leet2] [clear][leet3] [from my ramblings here][leet4].

Today, I decided to pick [this one][leet-source].

You are given a list of integers representing a stock's price for consecutive days.

```text
[3,1,0,0,5,4,1,3]
```

You can buy on one day and then sell on any future day. You cannot buy and sell on the same day, nor can you buy more than once before selling it. Also, you can only buy and sell atmost twice. (That is, two buy-sell trades).

Given those conditions, find out what's the maximum profit you can make if you picked the best 1 or at most 2 trades from the list.

So for the example list of numbers from above, here's one potential candidate of trades that can net you the maximum profit:

```text
stock prices: [3,1,0,0,5,4,1,3]
max profit = 7
because:
best trade #1 = 0 (buy on day 3 or 4), 5 (sell on 5th day) => profit = 5
best trade #2 = 1 (buy on 7th day), 3 (sell on 9th day) => profit = 2
total profit = 7
```

---

I thought that the first thing to do was to sort the array ascending so that it was eaiser to know which trades netted the maximum profits.

Example:

```text
unsorted: [3,1,0,0,5,4,1,3]
sorted: [0,0,1,1,3,3,4,5]
```

But of course, we have to also "carry" the information of which number (price) belongs to which day (original index) because to be able to calculate the best trade, we need to have a valid buy-sell sequence. If I sort the list, I know `0` and `5` net a great profit but those could not even be a valid sale as `5` _could_ be on day 1 and `0` could be on day 2 (i.e, you cant sell before you buy).

Something like this would be a better data to carry around:

```text
unsorted: [3,1,0,0,5,4,1,3]
sorted but with date info:
  [(0,3), (0,4), (1,2), (1,7), (3,1), (3,8), (4,6), (5,5)]
```

In Purescript, that's a `Tuple`:

```haskell
type Price = Int

type Day = Int

type StockDay = Tuple Price Day

arrayToStockDay :: Array Int -> SortedArray StockDay
arrayToStockDay xs = sortStockDay $ go xs 1 []
  where
  go :: Array Int -> Int -> Array StockDay -> Array StockDay
  go [] _ acc = acc
  go ys day acc =
    case head ys of
      Just stockPrice -> go (fromMaybe [] $ tail ys) (day + 1) (snoc acc (Tuple stockPrice day))
      Nothing -> acc
```

(I will cover the `SortedArray` bit shortly; for now, treat it just as a wrapper around an `Array`)

This data structure lets me do an important thing: find all possible valid trades (single buy-and-sell) and their profit.

Suppose I take the first item: `(0,3)`

I can now iterate over the rest of the items and make up a list of valid buy-sell trades like this:

```text
buy = (0,3)
valid sells =
  (0,4)
  (1,7)
  (3,8)
  (4,6)
  (5,5)
```

`(1,2)` and `(3,1)` are not valid because their "days" are before the chosen `(0,4)`.

And now, I can do one more thing: get profits for each of the valid sells.

```text
buy = (0,3)
valid sells with profit info =
  (0,4) => 0
  (1,7) => 1
  (3,8) => 3
  (4,6) => 4
  (5,5) => 5
```

Let me do this for the next item in the list `(0,4)`

```text
buy = (0,4)
valid sells with profit info =
  (1,7) => 1
  (3,8) => 3
  (4,6) => 4
  (5,5) => 5
```

And more:

```text
buy = (1,2)
valid sells with profit info =
  (1,7) => 0
  (3,8) => 2
  (4,6) => 3
  (5,5) => 4

buy = (1,7)
valid sells with profit info =
  (3,8) => 2
```

and so on.

Notice that because I'm sorting the array by the stock price, I only have to pick the _subsequent_ items in an array when comparing one item with the rest.

What I need now is to somehow represent all that data (from the previous step) so that I can then use it to find out the _best_ two sequential trades that can give me maximum profits.

I could simply rely on another "pair" like so:

```text
buy = (0,3)
valid sells with profit info =
  (0,4) => 0
  (1,7) => 1
  (3,8) => 3
  (4,6) => 4
  (5,5) => 5

can be represented as:

[
  ( (0,3) , (0,4) ),
  ( (0,3) , (1,7) ),
  ( (0,3) , (3,8) )
  ( (0,3) , (4,6) ),
  ... and so on
]
```

And then you just combine all of them to have one giant list of all valid profit-making sales. By the time I get to code, I'll have one more check to filter out those valid trades that result in _some_ profit so the list is really small. (Our example only has 14 valid profit-making buy-sell combinations).

Translating this logic to code, I worked from the smallest step: if I compare two stock-price-day items, I should be able to tell if the pair is a valid buy-sell trade:

```haskell
import Data.Tuple (Tuple(..))
import Data.Maybe (Maybe(..))

-- represeting a buy sell trade
data BuySell = BuySell StockDay StockDay

makeBuySell :: StockDay -> StockDay -> Maybe BuySell
makeBuySell t1@(Tuple p1 a) t2@(Tuple p2 b) =
  if a < b && p1 < p2 then Just (BuySell t1 t2) else Nothing
```

I use the `Maybe` data type to indicate if a comparison of two stock-price-day items results in a valid pair (valid by both day sequence and guaranteed profit).

I can use this `makeBuySell` function to do the comparison I wrote about earlier:

```haskell
import Data.Array (snoc, head, tail)
import Data.Maybe (Maybe(..), fromMaybe)

makeBuySellList :: StockDay -> SortedArray StockDay -> Array BuySell
makeBuySellList sdp (SortedArray xs) = go sdp xs []
  where
  go _ [] acc = acc
  go _sdp ls acc = case head ls of
    Just h -> case makeBuySell _sdp h of
      Nothing -> go _sdp (fromMaybe [] $ tail ls) acc
      Just tp -> go _sdp (fromMaybe [] $ tail ls) (snoc acc tp)
    Nothing -> acc
```

Okay, pause here. I'm using a new data type called `SortedArray`. It's really just a `newtype`.

But why?

An `Array` can be sorted or unsorted. There is no way for me to know, by looking at a type signature, if an array being used by a function is sorted or not. Also, sorting can mean different things when we are talking about a `Tuple` or complex data structures.

So, I decided to use a `newtype` called `SortedArray` to indicate any array that is sorted (in some way).

```haskell
newtype SortedArray a = SortedArray (Array a)
```

Again, I am not interested in the sort order or the sort logic here. All I want is a distinction between any random array (that could or could not be sorted) and a sorted array which is sorted using _some_ logic that I don't care about.

Also, to make development easy, I decided to write a `Show` instance for it:

```haskell
instance showSortedArray :: Show a => Show (SortedArray a) where
  show (SortedArray a) = "SortedArray " <> show a
```

I tried to derive a `Show` instance for this (via `derive newtype instance`) but given that the polymorphic `a` is really an unknown, I couldn't write a derivation. That's a knowledge-gap for me.

Finally, with these functions, I can go through the whole list and make combinations:

```haskell
import Data.Array (reverse, sortBy, head, tail, concat)
import Data.Maybe (Maybe(..), fromMaybe)

makeBuySellCombinationsList :: SortedArray StockDay -> SortedArray BuySell
makeBuySellCombinationsList xs = SortedArray $ reverse $ sortBy sortBuySell $ go xs ([])
  where
  go :: SortedArray StockDay -> Array BuySell -> Array BuySell
  go (SortedArray []) tps = tps
  go (SortedArray sdps) (tps) =
    case head sdps of
      Nothing -> (tps)
      Just h -> go (SortedArray $ fromMaybe [] $ tail sdps) (concat [ tps, makeBuySellList h (SortedArray $ fromMaybe [] $ tail sdps) ])

sortBuySell :: BuySell -> BuySell -> Ordering
sortBuySell bs1 bs2 =
  if buySellProfit bs1 > buySellProfit bs2 then GT else LT
```

Worth noting that while I make this list, I am also sorting the list by profits descending. That means, I have buy-sell combinations with maximum profit at the front of the list.

With this (reverse) sorted list, I can now simply do this:

- take the highest profit-making trade
- compare it to the next-highest profit-making trade
- check if the day/date sequence works out. That is, the first trade sequence should have dates that are either before or after the second trade sequence in the comparison.

Here's one example of valid combo:

```text
((0,4), (5,5))
followed by
(1,7),(3,8)
is valid
because I buy on 4th day, sell on 5th,
then buy again on 7th day and sell on 8th.
```

The interesting thing to note is that I have to check for both directions. I could have a combination like this:

```text
((1,7), (9,8))
compared with
((0,2),(3,6))
```

That is also a valid combination because you could buy on 2nd day, sell on 6th, then buy again on 7th day and sell on 8th.

So, basically, check both directions.

```haskell
isValidTradeDayOrder :: BuySell -> BuySell -> Boolean
isValidTradeDayOrder (BuySell (Tuple _ a) (Tuple _ b)) (BuySell (Tuple _ c) (Tuple _ d)) =
  (a < b && c < d && c > b) || (c < d && a < b && d < a)
```

Before I write the function that goes through a list of sorted buy-sell pairs and fetches a possible "best candidate", I need to define what a "best candidate" really is:

```haskell
type BestCandidate = Tuple BuySell (Maybe BuySell)
```

The idea really is this -> A best candidate is potentially:

- either a pair of two buy-sell trades
- or just one buy-sell trade

Why the second option?

Because according to the leetcode puzzle, you are allowed _at most_ two trades in total. That means, you could also have a case where you make maximum profits with just one trade (and there is no other trade you can make which is profitable after the first).

Hence, the structure:

```haskell
type BestCandidate = Tuple BuySell (Maybe BuySell)
```

The second `(Maybe BuySell)` is that "optional" buy-sell trade.

And now, the function that works through the whole list and picks the best candidate:

```haskell
workThroughStockDays :: SortedArray BuySell -> Maybe BestCandidate
workThroughStockDays tradePairs = go tradePairs 0 (Nothing)
  where
  go :: SortedArray BuySell -> Int -> Maybe BestCandidate -> Maybe BestCandidate
  go (SortedArray []) _ candidate = candidate
  go (SortedArray tps) maxProfitSoFar candidate =
    case head tps of
      Just tp ->
        let
          candidate1 = bestBuySellPair tp (SortedArray tps) maxProfitSoFar candidate
          bestCandidate = case candidate, candidate1 of
            Just c1, Just c2 -> Just $ getBestCandidate c1 c2
            Just c1, Nothing -> Just c1
            Nothing, Just c2 -> Just c2
            _, _ -> Nothing
          newMaxProfitSoFar = map candidateProfit bestCandidate # fromMaybe 0
        in
          go (fromMaybe (SortedArray []) $ map SortedArray $ tail tps) newMaxProfitSoFar bestCandidate
      Nothing -> candidate
```

The logic of the `workThroughStockDays` function is this:

- take the first item from the BuySell list (ie, the first buy-sell pair/combination)
- check if it has the best candidature (ie, max profits) when compared with another candidature (starting value of this candidature is `Nothing`)
- get the profit value for the best candidate from the comparison
- feed it recursively to the next step and do this till you run out of BuySell items in the list

The best candidate comparison function is this:

```haskell
bestBuySellPair :: BuySell -> SortedArray (BuySell) -> Int -> Maybe BestCandidate -> Maybe BestCandidate
bestBuySellPair buySell (SortedArray []) maxProfitSoFar bestTradeSoFar =
  if buySellProfit buySell > maxProfitSoFar then (Just $ Tuple buySell Nothing)
  else bestTradeSoFar
bestBuySellPair buySell (SortedArray tradePairs) maxProfitSoFar bestTradeSoFar =
  case head tradePairs of
    Just h ->
      if (isValidTradeDayOrder buySell h && (buySellProfit buySell + buySellProfit h) > maxProfitSoFar) then bestBuySellPair buySell (fromMaybe (SortedArray []) (map SortedArray $ tail tradePairs)) (buySellProfit buySell + buySellProfit h) (Just $ Tuple buySell (Just h))
      else bestBuySellPair buySell (fromMaybe (SortedArray []) (map SortedArray $ tail tradePairs)) maxProfitSoFar bestTradeSoFar
    Nothing ->
      if buySellProfit buySell > maxProfitSoFar then (Just $ Tuple buySell Nothing)
      else bestTradeSoFar


buySellProfit :: BuySell -> Int
buySellProfit (BuySell a b) = fst b - fst a
```

There's a bit of a duplication there but I figured I could optimize this later.

Also, the `getBestCandidate` function:

```haskell
getBestCandidate :: BestCandidate -> BestCandidate -> BestCandidate
getBestCandidate c1 c2 =
  if candidateProfit c2 > candidateProfit c1 then c2 else c1

candidateProfit :: BestCandidate -> Int
candidateProfit (Tuple t1 Nothing) = buySellProfit t1
candidateProfit (Tuple t1 (Just t2)) = buySellProfit t1 + buySellProfit t2
```

At this point, it looks like the pieces are in place so I can start composing them all to go from an array of integers to a best candidate!

```haskell
arrayToBuySellList :: Array Int -> SortedArray BuySell
arrayToBuySellList = arrayToStockDay >>> makeBuySellCombinationsList

findBestCandidate :: Array Int -> Maybe BestCandidate
findBestCandidate = arrayToBuySellList >>> workThroughStockDays
```

One final step. Just having a `Maybe BestCandidate` is not good. I need to know what profits were made (that's the original solution).

So:

```haskell
profitFromBestCandidate :: BestCandidate -> Int
profitFromBestCandidate (Tuple tp1 Nothing) = buySellProfit tp1
profitFromBestCandidate (Tuple tp1 (Just tp2)) = buySellProfit tp1 + buySellProfit tp2
```

Now I can simply do:

```haskell
totalProfits :: Array Int -> Int
totalProfits = findBestCandidate >>> map profitFromBestCandidate >>> fromMaybe 0
```

And as a test:

```bash
> totalProfits [3,1,0,0,5,4,1,3]
7

> totalProfits [3,1,0,0,5,4,1]
5

> totalProfits [3,1,0,0]
0

> totalProfits [3,1,0,0,1]
1

> totalProfits [3,1,0,0,1,2,3]
3
```

The [full source-code can be found here][source-code].

_Update_: I [wrote some notes on refactoring small bits of the code][refactor] to use a custom `Typeclass` to define what's a "valid trade".

[leet1]: /text-justify
[leet2]: /text-justify-2
[leet3]: /text-justify-3
[leet4]: /int-to-roman
[leet-source]: https://leetcode.com/problems/best-time-to-buy-and-sell-stock-iii/
[source-code]: https://github.com/chandru89new/leetcode-stuff/blob/1ce02699f8f8295378291ab0a6f9001ae902fc41/src/StockProfits.purs
[refactor]: /max-stock-profit-leetcode-typeclass
