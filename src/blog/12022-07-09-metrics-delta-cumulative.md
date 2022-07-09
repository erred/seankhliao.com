# metrics cumulative vs delta

## so how many aggregations do i need?

### _metrics_ data model

Metrics are [downsampled events](/blog/12022-07-09-metrics-delta-cumulative/),
with individual data points tied to points in time.
Now comes the problem, how do you report those data points?

#### _cumulative_

You keep a single counter (for each series),
you add to it, and you report whatever it's value is when queried.
This model seems intuitive for the most basic applications that never restart.
It seems questionable when you start to scale,
and think about "what does the value actually mean",
"what happens when it restarts",
and "how do I aggregate this with other counters".
But if you think about it some more,
it's one of the more reliable models.

The absolute value isn't important,
what is, is how much it changed by.
Like monotonic clocks,
which don't report any real meaningful time,
only that it has changed and the magnitude matters.
It's reliable because you can miss/drop data in between,
but as long as you have both a starting point and and ending point,
you'll have all the events, just at a slightly lower (time) resolution.

And since the number only goes up,
it's easy to detect when it goes down compensate for a counter reset,
though if combined with a pull-based collection system,
short lived crashes (+spikes) might be undetectable.

#### _delta_

You report new events only,
maybe batched over a short interval.
It's what you think should happen,
but this requires near-perfect delivery guarantees,
as missing a delivery means the data is just gone,
and maybe your monitoring system slowly drifts out of sync.

Once you have the data though,
it's easy to work with,
as the data value correlates directly to the time box it was reported in.
No more filling every query with `rate()` and guestimating what actually happened in that time.
