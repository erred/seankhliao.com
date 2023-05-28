# spotify earbug datastudio

## visualizing my listening history in data studio

### _spotify_ listening history

A while back, I made [earbug],
a little task to record my Spotify listening history
using the [recently played] api.
Amazingly, I've managed to keep it running for another whole year,
so I have data to play around with.

#### _data_

I store the data as a zstandard compressed protobuf message containing maps,
store on object storage (Google Cloud Storage).
Should I maybe have used a proper database? or even sqlite?
Perhaps, but this works well enough for now,
and I prefer not writing SQL...

Pulling down the data, I just need to pull in the protobuf defs,
and reshape the data into CSV before uploading to my analytics platform of choice:
this time it's [Looker Studio], formerly Data Studio.

#### _results_

![consistency](/static/earbug-2022-consistency.png)

I think I was quite consistent in the type/energy of songs I listened to over the year.

![start time](/static/earbug-2022-time.png)

With listening (starting) times quite reflective of my schedule.

![artist](/static/earbug-2022-artist.png)

My favorite artists were no big surprise, though different from the ones that I say out loud.

![tracks](/static/earbug-2022-track.png)

While the tracks I listened to seemed to have quite the selection of vengeful(?) titles.

#### _final_ thoughts

Next time, I might consider doing the graphing in code.
Data/Looker Studio isn't as flexible as I want in terms of reshaping the data
and adding some more interesting derived data points.

[earbug]: https://github.com/seankhliao/earbug
[recently played]: https://developer.spotify.com/console/get-recently-played/
[looker studio]: https://datastudio.google.com/
