---
title: "How to render a basic calendar UI in Elm"
slug: elm-calendar
date: 2023-07-31
---

The beauty of a language like [Elm](https://elm-lang.org) (and other lambda-calculus / functional programming inspired languages) is that **there's very little transformation involved in going from an idea to code. And that seems to have a big impact on getting things done.**

Making a basic calendar UI turned out to be a great example of this.

Here's the final output I aimed for:

![final output example](https://github.com/chandru89new/elm-simple-calendar/blob/main/screens/final_out_example.png?raw=true)


I started by thinking about the lowest unit: the month.

**Given a month (and a year), can I get this?**

![month render](https://github.com/chandru89new/elm-simple-calendar/blob/main/screens/month_render.png?raw=true)

My first idea was to do this:

- get all dates in a given month-year. 
- get some padding for the first week and padding for the last week so that I can fill them with empty blocks (this depends on when the week starts)
- pass this data to a rendering function!

The type of data we choose should be good enough to make it possible to render it easily. 

So, in our case, we're rendering dates. Lists of dates. 

And because we're rendering "rows" of dates, each row is a week of dates. 

So the data structure I'm going for is this:

```elm
-- assuming `Date` is some valid date representation
type Week = List Date
type MonthData = List Week
```

**`MonthData` could have 5-6 items, each item being a `Week`. And each `Week` being a list of 7 `Date`s.**

I took a look at Elm's [time](https://package.elm-lang.org/packages/elm/time/latest/) library to see if that fit the bill. Turns out it didnt. It's too low-level and involves a lot of `Task` mechanics that was an overkill.

Looking around, **I found Justin's [date](https://package.elm-lang.org/packages/justinmimbs/date/latest/) library which seemed like a great candidate.**

(Edit: In fact, it turned out to be a life-saver. It has everything we need.)

Justin's [date](https://package.elm-lang.org/packages/justinmimbs/date/latest/) library had these two functions which were interesting:

```elm
ceiling : Interval -> Date -> Date
-- Round up a date to the beginning of the closest interval. The resulting date will be greater than or equal to the one provided.

floor : Interval -> Date -> Date
-- Round down a date to the beginning of the closest interval. The resulting date will be less than or equal to the one provided.
```

So, if I wanted to find the nearest "previous" Sunday before 1st July 2023, I can do this:

```elm
import Date
import Time

result = Date.floor Date.Sunday (Date.fromCalendarDate 2023 Time.Jul 1)
```

Testing this in REPL:

```bash
> result |> Date.format "EEE, d MM y"
"Sun, 25 Jun 2023" : String
```

And if I wanted to nearest "next" Saturday after 31st of July 2023, I can do this:

```elm
import Date
import Time

result = Date.ceiling Date.Saturday (Date.fromCalendarDate 2023 Time.Jul 31)
```

In REPL:

```bash
> result |> format "EEE, d MMM y"
"Sat, 5 Aug 2023" : String
```

That's fantastic. **Now, my logic is simplified to this:**

- take start of week (eg `Sunday`), month and year as inputs
- compute the "proper" start date (which is the nearest `start of week` for a given first-day of the month)
- compute the "proper" end date (which is the nearest `start of week minus one` for a given last-day of the month)
- get all dates falling between these two dates (including both) – this becomes a list of all dates to render
- split them into groups of 7 and we have a list of weeks... which is the same as our `MonthData`!

## Getting the start date for a given month, year and start of week:

First step: take month, year and start of week and output the right/proper start date.

Example what we want:

```
-- `getProperStartDate : StartOfWeek -> Month -> Year -> Date`
getProperStartDate Sunday July 2023 == "25th June 2023"
getProperStartDate Sunday June 2023 == "28th May 2023"

-- ignore the fact that the result is string. that's just for demonstration
```

To get here, we just have to use the `floor` function from the `Date` library:

```elm
import Date
import Time

getProperStartDate : StartOfWeek -> Month -> Year -> Date.Date
getProperStartDate startOfWeek month year =
    Date.floor (weekdayToInterval startOfWeek) (Date.fromCalendarDate year month 1)

-- we also need a function that converts a Time.Weekday to a Date.Interval
-- to use in the `getProperStartDate` function
weekdayToInterval : Time.Weekday -> Date.Interval
weekdayToInterval weekday =
    case weekday of
        Time.Sun ->
            Date.Sunday

        Time.Mon ->
            Date.Monday

        Time.Tue ->
            Date.Tuesday

        Time.Wed ->
            Date.Wednesday

        Time.Thu ->
            Date.Thursday

        Time.Fri ->
            Date.Friday

        Time.Sat ->
            Date.Saturday
```

Test in REPL:

```bash
> getProperStartDate Time.Sun Time.Jul 2023 |> Date.format "EEE, d MMM y"
"Sun, 25 Jun 2023" : String
```

Next up, **let's also write a function to get the proper end date for a given month, year and start of week.**

This time, it's not as straight-forward.

Take 31st July 2023 and Sunday (for start of week) as an example:

- 31st July 2023 is a Monday
- The next closest Sunday is 6th August 2023. 
- But we don't need a "Sunday". We need the next closest "Saturday". 
- At first, I thought "hey we could compute the actual end of week day from the given start-of-week day" but that's a lot of code. Instead, we can just get the next-closest Sunday and then reduce 1 day!

And here's that logic:

```elm
getProperEndDate : StartOfWeek -> Month -> Year -> Date.Date
getProperEndDate startOfWeek month year =
    let
        endDate =
            Date.add Date.Months 1 (Date.fromCalendarDate year month 1) |> Date.add Date.Days -1

        endDateIsStartOfWeek =
            Date.weekday endDate == startOfWeek
    in
    if endDateIsStartOfWeek then
        Date.add Date.Days 7 endDate

    else
        Date.ceiling (weekdayToInterval startOfWeek) endDate |> Date.add Date.Days -1
```

- First we calculate the end date of the month.
- Then we find the actual end date we need – this happens to be the closest "start of week" day minus 1 (so that it's the end of the week).
- One small additional condition there that checks if the actual end date of the month also happens to be the start of the week. In that case, we add 7 days to get to the closest end of week day.

Testing this in REPL:

```bash
> getProperEndDate Time.Sun Time.Jul 2023 |> format "EEE, d MMM y"
"Sat, 5 Aug 2023" : String
```

Now that we know the proper start and end dates, we can use them to get all dates in that range.

```elm
getDatesBetween : Date.Date -> Date.Date -> List Date.Date
getDatesBetween start end =
    Date.range Date.Day 1 start (Date.add Date.Days 1 end)
```

This `Date.range` function excludes the last date in the range. But we need the proper end date as well, so we just add one.

And now that we have all the dates to render, we can group them to get a list of weeks!

To do this, I'm using the [`List.Extra`](https://package.elm-lang.org/packages/elm-community/list-extra/latest/) library's `groupsOf` function:

```elm
getMonth : List Date.Date -> List Week
getMonth =
    List.Extra.groupsOf 7
```

And of course, we need to take just month, year and start of week as inputs and get back an entire month of dates:

```elm
getDatesForMonth : Month -> Year -> List Week
getDatesForMonth month year =
    let
        start =
            getProperStartDate Time.Sun month year

        end =
            getProperEndDate Time.Sun month year

        dates =
            getDatesBetween start end
    in
    getMonth dates
```

Yes, we're just hard-coding the start of the week (`Time.Sun`) for now. We can switch this later to be something that the function accepts as an input.

Testing these in REPL:

```bash
> getDatesForMonth Time.Jul 2023
[[RD 738696,RD 738697,RD 738698,RD 738699,RD 738700,RD 738701,RD 738702],[RD 738703,RD 738704,RD 738705,RD 738706,RD 738707,RD 738708,RD 738709],[RD 738710,RD 738711,RD 738712,RD 738713,RD 738714,RD 738715,RD 738716],[RD 738717,RD 738718,RD 738719,RD 738720,RD 738721,RD 738722,RD 738723],[RD 738724,RD 738725,RD 738726,RD 738727,RD 738728,RD 738729,RD 738730],[RD 738731,RD 738732,RD 738733,RD 738734,RD 738735,RD 738736,RD 738737]]
```

The `RD Int` is a native representation of the `Date` library.

We can format this to be human-friendly and check that the results are OK:

```bash
> getDatesForMonth Time.Jul 2023 |> List.map (List.map (Date.format "EEE, d MMM y"))
[["Sun, 25 Jun 2023","Mon, 26 Jun 2023","Tue, 27 Jun 2023","Wed, 28 Jun 2023","Thu, 29 Jun 2023","Fri, 30 Jun 2023","Sat, 1 Jul 2023"],["Sun, 2 Jul 2023","Mon, 3 Jul 2023","Tue, 4 Jul 2023","Wed, 5 Jul 2023","Thu, 6 Jul 2023","Fri, 7 Jul 2023","Sat, 8 Jul 2023"],["Sun, 9 Jul 2023","Mon, 10 Jul 2023","Tue, 11 Jul 2023","Wed, 12 Jul 2023","Thu, 13 Jul 2023","Fri, 14 Jul 2023","Sat, 15 Jul 2023"],["Sun, 16 Jul 2023","Mon, 17 Jul 2023","Tue, 18 Jul 2023","Wed, 19 Jul 2023","Thu, 20 Jul 2023","Fri, 21 Jul 2023","Sat, 22 Jul 2023"],["Sun, 23 Jul 2023","Mon, 24 Jul 2023","Tue, 25 Jul 2023","Wed, 26 Jul 2023","Thu, 27 Jul 2023","Fri, 28 Jul 2023","Sat, 29 Jul 2023"],["Sun, 30 Jul 2023","Mon, 31 Jul 2023","Tue, 1 Aug 2023","Wed, 2 Aug 2023","Thu, 3 Aug 2023","Fri, 4 Aug 2023","Sat, 5 Aug 2023"]]
```

Now that I have this data structure, all I need to do is render it as a month!

We can work this inside-out. That is, we can build functions to render a date, a week and then combine these to render the month.

Here's a function to render the date:

(I'm using Tailwind classes to simplify styling)

```elm
viewDate : Date.Date -> Html Msg
viewDate date =
    H.div [ Attr.class "flex items-center justify-center" ] [ H.text <| Date.format "d" date ]
```

And the week:

```elm
viewWeek : Week -> Html Msg
viewWeek dates =
    H.div [ Attr.class "grid grid-cols-7 items-center gap-4" ] (List.map viewDate dates)
```

I'm using CSS `grid` to make it easy to arrange the dates. Each date is `flex` and center-aligned (see the `viewDate` function above). And the week-render takes care of rendering all dates in a 7-column grid.

And the view month is just this:

```elm
viewMonth : List Week -> Html Msg
viewMonth weeks =
    H.div [] (List.map viewWeek weeks)
```

And of course, we need to render the week header as well which lists the weekdays.

To do this, I'm going to be a bit hacky: 
- We already have a list of weeks in `List Week`. 
- We can take the "first" element of this list and
- format each date in the list to just extract the weekday
- and use the resulting list to render the week header!

Expressed in code, we start with the week header view function which takes a list of weeks and renders a list of weekday headers.

```elm
viewWeekHeader : Week -> Html Msg
viewWeekHeader week =
    H.div [ Attr.class "grid grid-cols-7 items-center gap-2" ] <|
        List.map (\date -> H.div [ Attr.class "flex items-center justify-center" ] [ H.text <| Date.format "EEEEE" date ]) week
```

Combining all of this into a view function:

```elm
view : Model -> Html Msg
view _ =
    let
        dates =
            getDatesForMonth Time.Jul 2023
    in
    H.div [ Attr.class "w-72" ]
        [ viewWeekHeader (Maybe.withDefault [] (List.head dates))
        , viewMonth dates
        ]
```


Here's what it renders as:

![month render ugly](https://github.com/chandru89new/elm-simple-calendar/blob/main/screens/month_render_initial.png?raw=true)

**It's ugly, shows dates from the previous/next months and there's so much room for improvement.** 

But we've got the basics right and that's good enough to boot.

The first order of business now is to **not show dates which are not part of the month.**

In the example above, that's 25th - 30th (June) and 1st - 5th (August).

What we have is a long list of dates. We need to somehow *know* if a date in the list is part of the current month (eg July) or not. 

Let's think in terms of the type:

```elm
type alias CalendarDate =
    { date : Date.Date, dateInCurrentMonth : Bool }
```

And we'll change our week to be:

```elm
type alias Week =
    List CalendarDate
```

**The moment we make this change, the Elm compiler will start guiding us through the functions that need updating.**

We'll change the `getMonth` one first:

```elm
getMonth : List CalendarDate -> List Week
getMonth =
    List.Extra.groupsOf 7
```

And:

```elm
getDatesForMonth : Month -> Year -> List Week
getDatesForMonth month year =
    let
        start =
            getProperStartDate Time.Sun month year

        end =
            getProperEndDate Time.Sun month year

        dates =
            getDatesBetween start end
                |> List.map (\date -> { date = date, dateInCurrentMonth = Date.month date == month })
    in
    getMonth dates
```

And the last things we need to fix are the `viewDate` and `viewWeekHeader` functions. The logic is simple: if the date is not that of current month, we'll set the opacity to 0.

```elm
viewDate : CalendarDate -> Html Msg
viewDate { date, dateInCurrentMonth } =
    H.div
        [ Attr.class "flex items-center justify-center"
        , Attr.class
            (if dateInCurrentMonth then
                ""

             else
                "opacity-0"
            )
        ]
        [ H.text <| Date.format "d" date ]

viewWeekHeader : Week -> Html Msg
viewWeekHeader week =
    H.div [ Attr.class "grid grid-cols-7 items-center gap-2" ] <|
        List.map (\{ date } -> H.div [ Attr.class "flex items-center justify-center" ] [ H.text <| Date.format "EEEEE" date ]) week
```

This gets us to here:

![refining month render](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/9terox36aq3afqb2j0ct.png)

**One of the things that's been bothering me about this render is that there's a lot of duplication because of the way we're rendering the rows.**

Each row is it's own "grid", instead of the whole month being a grid. (And the week header is also it's own "grid").


![too many divs](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/o0dn9mcoordfj14sgki9.png)



We can fix this.

We want a structure like this:

```
<div class="grid grid-cols-7 items-center gap-2">
	<div>S</div>
	<div>M</div>
	<div>T</div>
	... all weekday headers
	...
	<div>1</div>
	<div>2</div>
	... all dates
</div>
```

We can do this in two steps:
1. first, we'll write one generic container `viewBox` which wraps all its children in the grid
2. then, we'll ensure all our viewMonth/viewWeek functions return a list of `div`s that we can just render inside the `viewBox`

```elm
viewBox : List (Html Msg) -> Html Msg
viewBox =
    H.div [ Attr.class "grid grid-cols-7 gap-2 items-center" ]
```

And to make life easier, I'll also add a `viewItem` (which is basically the date render):

```elm
viewItem : List (Html Msg) -> Html Msg
viewItem =
    H.div [ Attr.class "flex items-center justify-center" ]
```

And now, we'll change the other view functions so they return a `List (Html Msg)` instead of `Html Msg`:

```elm
viewWeek : Week -> List (Html Msg)
viewWeek dates =
    List.map viewDate dates


viewMonth : List Week -> List (Html Msg)
viewMonth weeks =
    List.concatMap viewWeek weeks


viewWeekHeader : Week -> List (Html Msg)
viewWeekHeader week =
    List.map (\{ date } -> H.div [ Attr.class "flex items-center justify-center" ] [ H.text <| Date.format "EEEEE" date ]) week
```

In the `viewMonth` function, we use the `List.concatMap` function because:
- viewMonth is a list.map over weeks using the `viewWeek` function
- the `viewWeek` function returns a list
- so the final result is list of lists
- which we `concat` to flatten into a list.

Finally, we'll modify the main view function:

```elm
view : Model -> Html Msg
view _ =
    let
        year =
            2023

        month =
            Time.Jul

        dates =
            getDatesForMonth month year
    in
    H.div [ Attr.class "w-72" ]
        [ H.div [ Attr.class "p-2" ] [ H.text (Date.format "MMMM YYYY" (Date.fromCalendarDate year month 1)) ]
        , viewBox <| List.concat [ viewWeekHeader (Maybe.withDefault [] (List.head dates)), viewMonth dates ]
        ]
```

The main change is that we're now using the `viewBox` function (so we modify the input to it). 

And the other thing is we added this bit:

```elm
H.div [ Attr.class "p-2" ] [ H.text (Date.format "MMMM YYYY" (Date.fromCalendarDate year month 1))
```

which adds a month-year header.

Our final result:


![month final](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/iudzghx0x6ega1qhow9n.png)


All that remains is to repeat this for each month in a given year.

To do this, we can just write out all the months of a year, and loop over them:

```elm
view : Model -> Html Msg
view _ =
    let
        year =
            2023

        months =
            [ Time.Jan
            , Time.Feb
            , Time.Mar
            , Time.Apr
            , Time.May
            , Time.Jun
            , Time.Jul
            , Time.Aug
            , Time.Sep
            , Time.Oct
            , Time.Nov
            , Time.Dec
            ]
    in
    H.div [ Attr.class "p-8 grid grid-cols-4 gap-4 items-stretch" ]
        (List.map (\month -> viewMonthBox month year) months)
```

This produces:


![full year but with bug](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/du72s76y34mnkyewcex1.png)


Oh no! Here's a problem: the first month reads `January 2022`. 

Turns out, the formatting string I was using is wrong:

Instead of `MMMM YYYY`, I need to be using `MMMM y`. ([More info about these format strings here](http://www.unicode.org/reports/tr35/tr35-43/tr35-dates.html#Date_Format_Patterns).)

```elm
[ H.div [ Attr.class "p-2 text-center" ] [ H.text (Date.format "MMMM y" (Date.fromCalendarDate year month 1)) ]
```

And that fixes the problem:

![full year final](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/cmitpkrnmhakbvag0pbg.png)

The [full source code can be found here](https://github.com/chandru89new/elm-simple-calendar).


