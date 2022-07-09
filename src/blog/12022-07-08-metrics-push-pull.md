# metrics push or pull

## yeeting metrics data from many internet boxen to one

### _metrics_

Things happen, in the world, in computers, in the software you write.
Those are _events_.
In a perfect world,
you would be able to time travel and inspect those events.
In a less perfect world,
you'd have a record of each event that you can inspect after the fact.
In our world, doing that quickly becomes expensive and infeasible at scale,
so you need to downsample.
Group data together by a few important labels,
group them up into distinct time intervals,
and now you have _metrics_.
A low(er) cost, low resolution view into the state of things,
hopefully the useful parts of the state.

#### _shipping_ metrics

Your code has done its calculations and given you a number,
or more likely a new set of numbers every few seconds.
And you have many copies of your code running,
so many sets of numbers.
You want to put them all in the same place so you can watch those numbers,
and make dashboards.

#### _pulling_ metrics

One way of doing it is the _pull_ model,
most commonly seen in [prometheus](https://prometheus.io/)
compatible software exposing a `/metrics` endpoint.

##### _pull_ pros

- Easy to add on for web services
- No need to predetermine push destination/clients
- Easy to observe and debug individual instances
- Observers in direct control over their own load

##### _pull_ cons

- Needs service discovery to know which hosts to pull from
- Needs every service to have an exposed semi-persistent endpoint to pull from
- Can't handle short lived services
- Low(er) time resolution, costly to transfer entire state every time
- Unaligned data between different observers

#### _push_ metrics

What is old is new again.
Google built borgmon and the world got prometheus.
Google then built monarch and the world...
is still waiting for a few more engineers to leave Google and clone it.

##### _push_ pros

- No need for exposed endpoints/servers
- Less end-to-end delay between event happening and it being recorded
- Applicable to almost all scenarios
- Same data ends up everywhere

##### _push_ cons

- Need to have system set up in place first to receive data
- Receivers may have to handle uncontrolled load (if you don't build in backressure)
- Need to push configuration (auth?) into every endpoint to contact receiver
- SDK more complicated to write

#### _summary_

Does it matter which model you go with?
Not really, each one will sort-of work,
and you still have more work to do to align the disparate systems.

If you're a SaaS, you probably want the push model,
there's a reason why approx. noone offered hosted prometheus until recently,
and even that is either based on remote_write api compatibility (eg grafana cloud),
or an agent converting to some other protocol and pushing (everyone else).

If you're looking to the future,
hopefully more people will adopt the [OpenTelemetry](https://opentelemetry.io/) model.
It's configurable, but for now primarily push based,
with the greatest value being a single standard to rule them all...
