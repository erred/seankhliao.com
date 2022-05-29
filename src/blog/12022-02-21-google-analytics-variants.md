# google analytics variants

## different ways of setting up google analytics


### _analytics_

Who doesn't want to know what's happening on their web pages?
But why are there so many options of setting things up??

#### _Universal_ Analytics

This has been the standard Google Analytics you know for the past few years.
Comes with a set of default analytics based around sessions and views,
with a heirarchical category, action, label, value setup for events.
IDs look like `UA-XXXXXX-Y`,
and the current recommendation for loading the tracking code is via gtag.js:
`https://www.googletagmanager.com/gtag/js?id=UA-XXXXXX-Y`.

#### _Google_ Analytics 4

GA4 is the latest version of Google Analytics.
Now you have a single stream of  _event_,
with key-value attributes to cover the details.
Nicer dashboard, covers more platforms.
IDs look like `G-XXXXXX`,
and the implementation is also via gtag.js:
`https://www.googletagmanager.com/gtag/js?id=G-XXXXXX`.

#### _Google_ Tag Manager

So, you want to load tracking code for lots of different platforms.
Or you want to update the tracking setup dynamically.
Or you just want some extra builtin events.
GTM allows you to setup a single entrypoint on your website
and load the actual code dynamically (configured witin the GTM UI).
The implementation is via gtm.js
with a block of javascript that inserts itself as the first javascript element:
`https://www.googletagmanager.com/gtm.js?id=GTM-XXXXXX&l=dataLayer`

#### _Server_ Google Tag Manager

So `www.googletagmanager.com` gets blocked occasionally or you think you load too many trackers.
Now you can run a server side component (docker container) on your own subdomain
which dynamically pulls its config from GTM.
Why?
You can load the gtag.js or gtm.js scripts through it, and send the data to it.
Within the server GTM setup,
add clients which will parse the incoming data,
and tags will route the data to the various backends (eg UA, GA4).
The generated `GTM-XXXXXX` id is only for use by the server component,
which has its config hidden inside a base64 block.

This also has a single stream event model,
so in theory, you could write you own tracking code sending events.
write your own client (to be run in the server container) to process those events,
then route them to the various backends.

#### _Measurement_ Protocol

When you want to send your own events,
such as from the backend, use this.
