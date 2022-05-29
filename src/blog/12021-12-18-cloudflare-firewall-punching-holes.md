# punching holes in cloudflare firewall

## authz in with just the firewall?

### _cloudflare_ firewall

So Cloudflare has a variety of ways to lock down access to your site.
One of those is [Zone Lockdown](https://support.cloudflare.com/hc/en-us/articles/115001595131-Understanding-Cloudflare-Zone-Lockdown),
limiting access based on source IP address.
If you more fine grained access control,
that's where [firewall rules](https://developers.cloudflare.com/firewall/cf-firewall-rules)
(and the upsell) comes in.
Here you get access to more data points to decide access.

#### _authz_

Usually, you put authentication / authorization tokens in a header,
your firewall might check for the existence
and your backend checks the validity.

#### _problem_

But what if you had a dumb backend?
And your request comes from a third party where you can't pass headers,
like [Cloudflare images](https://www.cloudflare.com/products/cloudflare-images/)
which relies on shared infrastructure between different tenants.
All you have now is the url.

#### _api_ key

One way to do this is an apikey in a query param.
AWS [supports this](https://aws.amazon.com/blogs/compute/accepting-api-keys-as-a-query-string-in-amazon-api-gateway/),
even though it isn't best practice.

Problems with this include:

- the single api key grants access to everything
- if you don't name it properly, your developers might just share it publicly :facepalm:

#### _hmac_

Cloudflare offers an alternative:
[HMAC Tokens](https://developers.cloudflare.com/firewall/recipes/require-valid-hmac-token).
At first glance it might not seem too different from the api key,
but importantly, it's computed dynamically from the request which means we can scope it.

`is_timed_hmac_valid_v0` essentially takes:

- `secretKey`
- `message`
- `issuedTimestamp`
- `checkTimestamp`
- `validityPeriod`
- `mac`

Which means the `mac` passed in the query param is only valid for passed message,
and you can use the path as the message,
scoping the `mac` to just the single resouce
instead of all resources like with a static api key.

Now you do have to somehow pass the signature time as well,
and if it (and the mac) changes for every request,
then you'd thrash your caches,
so you could just bypass the timed section by using a fixed time.
