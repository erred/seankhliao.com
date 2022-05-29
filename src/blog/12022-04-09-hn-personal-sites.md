# hn personal sites

## a variety of maybe handcrafted things

### _hn_ personal sites

While I don't really care for the content of the forum,
the [Share your personal site](https://news.ycombinator.com/item?id=30934529)
thread gives us an interesting source of sites,
of which a higher percentage may be handcrafted.
So, how can we analyze them?
Here's the approach I took.

#### _get_ sites

After (not much) thinking, I decided it would be faster to just download the html pages
(there were only 5) and try to pull urls out of them.
So, the pages I put in [src](https://github.com/erred/hn-sites-2022-04/tree/main/src)
and I used a regex `[Hh][Tt]{2}[Pp](s)?://[a-zA-Z0-9-/=?&%\.]+`
to match anything URL-like.
With a bit of
[cleanup and filtering](https://github.com/erred/hn-sites-2022-04/blob/main/cmd/stage1/main.go#L38-L42),
I decided to only keep apexes, ending up with 1109 links.

#### _ping_ sites

In [stage2](https://github.com/erred/hn-sites-2022-04/tree/main/cmd/stage2),
I went with just requesting the page at the root,
recording both timings and responses.
Unsuprisingly, people who posted http links had trouble keeping https running properly.
There were also quite a fre 404/503 responses, error logs below:

```
022/04/09 16:28:25 https adi.onl read body https://adi.onl/: gzip: invalid header
2022/04/09 16:28:25 http adi.onl read body http://adi.onl/: gzip: invalid header
2022/04/09 16:28:28 https art-res.xyz do request https://art-res.xyz/: Get "https://art-res.xyz/": dial tcp: lookup art-res.xyz on 8.8.8.8:53: no such host
2022/04/09 16:28:28 http art-res.xyz do request http://art-res.xyz/: Get "http://art-res.xyz/": dial tcp: lookup art-res.xyz on 8.8.8.8:53: no such host
2022/04/09 16:28:32 https bojanvidanovic.com request https://bojanvidanovic.com/: 503 Service Temporarily Unavailable
2022/04/09 16:28:33 https brajeshwar.com request https://brajeshwar.com/: 503 Service Temporarily Unavailable
2022/04/09 16:28:33 http bojanvidanovic.com request http://bojanvidanovic.com/: 503 Service Temporarily Unavailable
2022/04/09 16:28:33 http brajeshwar.com request http://brajeshwar.com/: 503 Service Temporarily Unavailable
2022/04/09 16:28:37 https dashupdate.com do request https://dashupdate.com/: Get "https://dashupdate.com/": remote error: tls: internal error
2022/04/09 16:28:43 https eweitz.github.io request https://eweitz.github.io/: 404 Not Found
2022/04/09 16:28:43 http eweitz.github.io request http://eweitz.github.io/: 404 Not Found
2022/04/09 16:28:44 https fallingleavescabin.com do request https://fallingleavescabin.com/: Get "https://fallingleavescabin.com/": dial tcp 64.98.145.30:443: connect: connection refused
2022/04/09 16:28:48 https hardestclimbs.com do request https://hardestclimbs.com/: Get "https://hardestclimbs.com/": dial tcp: lookup hardestclimbs.com on 8.8.8.8:53: no such host
2022/04/09 16:28:48 http hardestclimbs.com do request http://hardestclimbs.com/: Get "http://hardestclimbs.com/": dial tcp: lookup hardestclimbs.com on 8.8.8.8:53: no such host
2022/04/09 16:28:49 https hw-ax.github.io request https://hw-ax.github.io/: 404 Not Found
2022/04/09 16:28:49 http hw-ax.github.io request http://hw-ax.github.io/: 404 Not Found
2022/04/09 16:28:52 https jacobhrussell.com request https://jacobhrussell.com/: 404 Not Found
2022/04/09 16:28:52 http jacobhrussell.com request http://jacobhrussell.com/: 404 Not Found
2022/04/09 16:28:54 https johnmathews.is request https://johnmathews.is/: 503 Service Temporarily Unavailable
2022/04/09 16:28:54 http johnmathews.is request http://johnmathews.is/: 503 Service Temporarily Unavailable
2022/04/09 16:28:56 https karthikeshwar.github.io request https://karthikeshwar.github.io/: 404 Not Found
2022/04/09 16:28:56 http karthikeshwar.github.io request http://karthikeshwar.github.io/: 404 Not Found
2022/04/09 16:29:00 https bettermotherfuckingwebsite.com do request https://bettermotherfuckingwebsite.com/: Get "https://bettermotherfuckingwebsite.com/": dial tcp 52.217.47.35:443: i/o timeout
2022/04/09 16:29:02 https bradleybuda.com do request https://bradleybuda.com/: Get "https://bradleybuda.com/": dial tcp 52.219.113.155:443: i/o timeout
2022/04/09 16:29:03 https luke.lol request https://luke.lol/: 403 Forbidden
2022/04/09 16:29:03 http luke.lol request http://luke.lol/: 403 Forbidden
2022/04/09 16:29:04 https char.lol do request https://char.lol/: Get "https://char.lol/": dial tcp 52.217.69.163:443: i/o timeout
2022/04/09 16:29:04 https marvilde.cc do request https://marvilde.cc/: Get "https://marvilde.cc/": dial tcp [2a01:4f9:c010:c662::aa]:443: connect: connection refused
2022/04/09 16:29:06 https midcdorgeek.com do request https://midcdorgeek.com/: Get "https://midcdorgeek.com/": dial tcp: lookup midcdorgeek.com on 8.8.8.8:53: no such host
2022/04/09 16:29:06 http midcdorgeek.com do request http://midcdorgeek.com/: Get "http://midcdorgeek.com/": dial tcp: lookup midcdorgeek.com on 8.8.8.8:53: no such host
2022/04/09 16:29:07 https mmistakes.github.io request https://mmistakes.github.io/: 404 Not Found
2022/04/09 16:29:07 http mmistakes.github.io request http://mmistakes.github.io/: 404 Not Found
2022/04/09 16:29:08 https neil.computer request https://neil.computer/: 503 Service Temporarily Unavailable
2022/04/09 16:29:08 http neil.computer request http://neil.computer/: 503 Service Temporarily Unavailable
2022/04/09 16:29:10 https notes.volution.ro request https://notes.volution.ro/: 503 Service Temporarily Unavailable
2022/04/09 16:29:10 http notes.volution.ro request http://notes.volution.ro/: 503 Service Temporarily Unavailable
2022/04/09 16:29:11 https ohmeadhbh.github.io request https://ohmeadhbh.github.io/: 404 Not Found
2022/04/09 16:29:11 http ohmeadhbh.github.io request http://ohmeadhbh.github.io/: 404 Not Found
2022/04/09 16:29:13 https peterburk.appspot.com request https://peterburk.appspot.com/: 404 Not Found
2022/04/09 16:29:13 http peterburk.appspot.com request http://peterburk.appspot.com/: 404 Not Found
2022/04/09 16:29:13 https peter-burk.rhcloud.com do request https://peter-burk.rhcloud.com/: Get "https://peter-burk.rhcloud.com/": dial tcp: lookup peter-burk.rhcloud.com on 8.8.8.8:53: no such host
2022/04/09 16:29:13 https peterburk.github.com request https://peterburk.github.com/: 404 Not Found
2022/04/09 16:29:13 http peter-burk.rhcloud.com do request http://peter-burk.rhcloud.com/: Get "http://peter-burk.rhcloud.com/": dial tcp: lookup peter-burk.rhcloud.com on 8.8.8.8:53: no such host
2022/04/09 16:29:14 http peterburk.github.com request http://peterburk.github.com/: 404 Not Found
2022/04/09 16:29:19 https hw.ax do request https://hw.ax/: Get "https://hw.ax/": dial tcp 185.26.105.244:443: i/o timeout
2022/04/09 16:29:21 https rad.as request https://rad.as/: 503 Service Temporarily Unavailable
2022/04/09 16:29:21 http rad.as request http://rad.as/: 503 Service Temporarily Unavailable
2022/04/09 16:29:24 https johnnatan.me do request https://johnnatan.me/: Get "https://johnnatan.me/": dial tcp 15.197.142.173:443: i/o timeout
2022/04/09 16:29:27 https kavitareader.com request https://kavitareader.com/: 522
2022/04/09 16:29:33 https lukeseelenbinder.com do request https://lukeseelenbinder.com/: Get "https://lukeseelenbinder.com/": dial tcp [2001:1b54:9001:5d10::1]:443: connect: no route to host
2022/04/09 16:29:40 https nywkap.com do request https://nywkap.com/: Get "https://nywkap.com/": dial tcp 52.217.111.115:443: i/o timeout
2022/04/09 16:29:41 https squidfunk.github.io request https://squidfunk.github.io/: 404 Not Found
2022/04/09 16:29:41 http squidfunk.github.io request http://squidfunk.github.io/: 404 Not Found
2022/04/09 16:29:43 https symbolflux.com request https://symbolflux.com/: 403 Forbidden
2022/04/09 16:29:43 https peterburk.free.fr do request https://peterburk.free.fr/: Get "https://peterburk.free.fr/": dial tcp 212.27.63.169:443: i/o timeout
2022/04/09 16:29:43 https syradar.github.io request https://syradar.github.io/: 404 Not Found
2022/04/09 16:29:43 http syradar.github.io request http://syradar.github.io/: 404 Not Found
2022/04/09 16:29:44 https petrustheron.com do request https://petrustheron.com/: Get "https://petrustheron.com/": dial tcp 52.218.112.140:443: i/o timeout
2022/04/09 16:29:44 https taoofmac.com request https://taoofmac.com/: 503 Service Temporarily Unavailable
2022/04/09 16:29:44 http taoofmac.com request http://taoofmac.com/: 503 Service Temporarily Unavailable
2022/04/09 16:29:44 https tedium.co request https://tedium.co/: 503 Service Temporarily Unavailable
2022/04/09 16:29:45 http tedium.co request http://tedium.co/: 503 Service Temporarily Unavailable
2022/04/09 16:29:47 https theprojectmanagement.expert request https://theprojectmanagement.expert/: 401 Unauthorized
2022/04/09 16:29:47 https theroadchoseme.com do request https://theroadchoseme.com/: Get "https://theroadchoseme.com/": dial tcp 184.106.149.42:443: connect: connection refused
2022/04/09 16:29:47 https pnathan.com do request https://pnathan.com/: Get "https://pnathan.com/": dial tcp 52.218.181.34:443: i/o timeout
2022/04/09 16:29:47 http theprojectmanagement.expert request http://theprojectmanagement.expert/: 401 Unauthorized
2022/04/09 16:29:50 https qedlaboratory.com do request https://qedlaboratory.com/: Get "https://qedlaboratory.com/": dial tcp 35.238.188.116:443: i/o timeout
2022/04/09 16:29:57 https www.billhartzer.com request https://www.billhartzer.com/: 403 Forbidden
2022/04/09 16:29:57 http www.billhartzer.com request http://www.billhartzer.com/: 403 Forbidden
2022/04/09 16:29:58 http kavitareader.com request http://kavitareader.com/: 522
2022/04/09 16:29:58 https www.circuitbored.com do request https://www.circuitbored.com/: Get "https://www.circuitbored.com/": remote error: tls: internal error
2022/04/09 16:30:03 http lukeseelenbinder.com do request http://lukeseelenbinder.com/: Get "http://lukeseelenbinder.com/": dial tcp [2001:1b54:9001:5d10::1]:80: connect: no route to host
2022/04/09 16:30:06 https www.ruffandtuffrecordings.com do request https://www.ruffandtuffrecordings.com/: Get "https://www.ruffandtuffrecordings.com/": remote error: tls: internal error
2022/04/09 16:30:07 https www.smashcompany.com do request https://www.smashcompany.com/: Get "https://www.smashcompany.com/": dial tcp 148.251.153.51:443: connect: connection refused
2022/04/09 16:30:08 https www.tmd.io do request https://www.tmd.io/: Get "https://www.tmd.io/": dial tcp: lookup www.tmd.io on 8.8.8.8:53: no such host
2022/04/09 16:30:08 http www.tmd.io do request http://www.tmd.io/: Get "http://www.tmd.io/": dial tcp: lookup www.tmd.io on 8.8.8.8:53: no such host
2022/04/09 16:30:17 https thiagocafe.com do request https://thiagocafe.com/: Get "https://thiagocafe.com/": dial tcp 44.234.104.162:443: i/o timeout
2022/04/09 16:30:31 https www.iblaine.com do request https://www.iblaine.com/: Get "https://www.iblaine.com/": dial tcp 15.197.142.173:443: i/o timeout
2022/04/09 16:30:39 https www.yuyaykuna6.com do request https://www.yuyaykuna6.com/: Get "https://www.yuyaykuna6.com/": dial tcp 78.138.24.108:443: i/o timeout
2022/04/09 16:30:39 https xeny.net do request https://xeny.net/: Get "https://xeny.net/": dial tcp 159.69.20.219:443: i/o timeout
```

### _analysis_ on headers

_server_, based on the `Server` header, the more interesting numbers might be:

- 2 BunnyCDN
- 3 Microsoft IIS
- 3 OpenBSD httpd
- 5 fly.io
- 14 Litespeed
- 16 caddy
- 30 Amazon S3
- 76 Vercel
- 112 Apache
- 121 Netlify
- 161 Github
- 193 nginx (14 openresty)
- 219 cloudflare

Only Ubuntu included the OS for nginx,
while Apache included OSes for Ubuntu, Debian, FreeBSD, and CentOS.
65 didn't include any `Server` header, these seem more likely to be custom written ones
(not counting the ones behind a CDN)

_Content-Type_, _Date_
These seem to be universal. Everyone includes them.

_X-Achievement_

www.maxlaumeister.com is apparently a site with achievements for finding various things,
one of which is this header.

_X-Gay-Clown-Putin_, _X-Kremlin-Surrender-Now_, _X-Support-Ukraine_

petergarner.net includes an interesting set of headers relating to current world events:

- X-Gay-Clown-Putin: ["Иди на хуй, маленький Путин"]
- X-Kremlin-Surrender-Now: ["Putin is mad: he will kill you all. Give up now and live"]
- X-Support-Ukraine: ["go fuck yourself putin"]

_Heartbleed_
honeypot.net has a [Heartbleed header](https://heartbleedheader.com/),
not sure if it's still relevant these days.

_Traceparent_
hypothes.is is the only site including the Traceparent header from [OpenTelemetry](https://opentelemetry.io/).

_X-Ipfs-Path_
karmanyaah.malhotra.cc spports IPFS via IPNS

_X-Adblock-Key_
bluocms.com pays(?) to bypass adblock

_X-Clacks-Overhead_
[X-Clacks-Overhead][https://xclacksoverhead.org/home/about] exists, referencing something Terry Prachet related?

_X-Hacker_
Either a automattic thing, or one other person uses this.

_X-Pingback_
Seems some things are still powered by RPC over XML...
