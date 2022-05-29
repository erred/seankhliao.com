# prometheus and alertmanager end 2 end alerting delay

## how long does it take to get an alert?


### _alertmanager_

[alertmanager](https://github.com/prometheus/alertmanager)
the alerting component of [prometheus](https://github.com/prometheus/prometheus).
So how long can it take between an event happening and you getting notified about it?
Since they're both written by the same team, they work more or less the same way:
timer based event loops.

#### _timer_ event loop

So what triggers things to happen?

- prometheus scrape is [ticker based](https://github.com/prometheus/prometheus/blob/bb05485c79084fecd3602eceafca3d554ab88987/scrape/scrape.go#L1109)
- prometheus rules is [ticker based](https://github.com/prometheus/prometheus/blob/c0c22ed04200a8d24d1d5719f605c85710f0d008/rules/manager.go#L355)
- alertmanager dispatch/group wait is [reset timer based](https://github.com/prometheus/alertmanager/blob/75932c7e40ff6a55349946666fec7c76ad2bed86/dispatch/dispatch.go#L410)

#### _delay_

In the most unfortunate case:

- wait up to `$scrape_interval` to get the initial data
- wait up to `$evaluation_interval` to check if alert is firing
- wait up to `$for` (round up to nearest `$evaluation_interval`) to trigger the alert
- wait up to `$group_wait` to send initial notification
  - updates are sent at `$group_wait` ticks


Now say you have another on call system layered on top.
It too is likely to be evaluation_interval / delay based,
so your total delay is even longer....
