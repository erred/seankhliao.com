# incident response management

## keep calm and carry on

### _incident_ response

Part of my work happens to be IRM (Incident Response Management).
Fancy words, but what does that mean?

Let's start with _Incident._
It covers any signicant event which (negatively) impacts the normal operation of the organization's services.
It may be planned downtime,
a showstopping bug that users can see,
or even a security breach.
What's the scope of _significant?_
I think observable by users,
whether internal or external is a good line in the sand to draw.

_Response_ covers
detection, communication, coordination, mitigation, remediation, retrospectives, and any follow up work.
From "how do you know something is broken",
to "who should handle this",
and "what should I do".
You can only dream up of so many scenarios beforehand,
much less remember the perfect course of action for each when you're stressed.
So while there will be runbooks for the common things,
people's judgement will always be needed for the unforeseen
(otherwise we'd just automate it).

_Management_ is interesting.
You want to be in control of the situation.
Or at least appear to be.
And so does everyone above you.
How do you do that?

#### _incident_ lifecycle

##### _starting_ an incident

When does an incident begin?
We start one for planned maintenance events,
which are mostly prepared for ahead of time.
Otherwise, it's a manual process of:
someone notices a (big) problem
and starts the incident flow.
They might notice it because of alerts going off,
or someone reports a problem.
But at the moment there's a human that starts an incident.

##### _incident_ flow

Once kicked off, automation creates a slack channel,
zoom bridge, and announces it.
There are also tickets that are (semi) automatically created,
but that's about it for automation.

Now it's back to the human,
who's now responsible for pulling relevant people in investigate.
Ideally someone should be chosen to lead an incident,
and delegate responsibilities to other people,
such as communication.
We pay people to be "on call" for this.

So people poke at the broken things,
try to keep other people informed with regular updates,
and hopefully find a fix.
At some point,
things go back to "normal",
and the incident is "over/closed".

##### _closing_ an incident

It's over, it's done.
No.
There's still a retrospective form to fill out.
Some of it is about ongoing work triggered by the incident,
others are on preventing a repeat of future similar incidents,
but there's a careful balancing act here to not layer on more process each time,
until you drown in red tape but still don't actually prevent incidents from happening.

#### _owning_ the process

What does it mean for my team to own the process?

We're responsible for specific pieces of tech in here,
mostly third party services as the point of contact / generic config admin,
such as for PagerDuty and FireHydrant.
We should also be responsible for other tech/integrations that make doing the right thing
more obvious for the people running (leading / participating in) the incidents,
but I think we're lacking here.

Other than that, it's defining organizational practices to follow,
shared language to use,
and getting people to adopt the process (correctly).
"Soft" things that center on influencing people to fall in to doing the right thing,
and having the confidence to both respond and lead.
