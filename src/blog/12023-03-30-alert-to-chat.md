# alert to chat

## what i actually want from a chat integration

### _alert_ to chat notification

I recently just wrote and deployed a service at work,
and I realized it was the second time I've written a service to do the same thing,
but different company, different tech stack.

_Problem:_ Whether you have Prometheus/Alertmanager, OpsGenie, Datadog, Pagerduty
driving your monitoring alerts system,
most of them come with integrations with your business chat platform of choice,
be it MS Teams, Slack, or somethign else.
But these integrations always use the fancy rich text/interactive blocks format,
which take up a lot of space, and you might only ever see 2 notifications at once per screen.
Plus, resolved notifications are sent as a separate message,
so it could be quite confusing on what the state of an alert is if you have more than 1.

_Solution:_ other than making the alerts fire less,
what I want is a compact, updated display,
a bit like a dashboard.
So you get a short, 1 line message with a link if it fires,
and it's updated when it's resolved.
Example:

> ✅ Resolved 💛 P3 X is broken - tag1 (edited)
> ❌ Firing ❤️ P1 Y is broken - tag1, tag2

#### _solutions_

What I need for this is:

- A webhook endpoint to receive alert events
- An app in the chat system (usually required to update prior messages)
- A data store to map alert IDs to sent chat IDs

#### _iterations_

##### _1_

My first iteration was with OpsGenie + MS Teams.
As the company ran on Google Cloud,
I used Firestore as the backing store.
The service received all notifications,
while channels had to message the bot with subscription filters.

##### _2_

This time, Datadog + Slack on AWS.
DynamoDB was the backing store of choice,
I was annoyed to disover you can't update a nested key if the previous level didn't exist.
This time, it had the alert specify the channels it wanted to notify directly,
I think as a consequence of not having access to all alerts,
and to simplify the filtering logic.

I did notice slack has [datastores] in beta,
might be a good choice to look into that in the future.

[datastores]: https://api.slack.com/future/datastores
