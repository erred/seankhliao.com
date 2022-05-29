# certificate transparency at work

## public logs of things...

### _certificate_ transparency

[certificate transparency](https://certificate.transparency.dev/)
is the requirement that all TLS certs trusted by
[browsers](https://certificate.transparency.dev/useragents/)
be submitted to public [logs](https://certificate.transparency.dev/logs/)
which are [monitored](https://certificate.transparency.dev/monitors/)
The primary purpose is to detect misissued certs.

#### _data_

There are 2 main ways we use CT information:

We get emails from Cloudflare everytime a cert is issued.
This is received in a MS Teams channel, which unfortunately displays the html email
and hides half the content, making it less than useful.
Other options would be api searches, via
[censys](https://search.censys.io/),
[crt.sh rss](https://crt.sh/).
Facebook, sslmate, and others also have apis but they seem more limited.

We manually search for records,
usually from [crt.sh](https://crt.sh/) by Sectigo (high information density)
or [transparencyreport](https://transparencyreport.google.com/https/certificates) by Google.

#### _use_

How do we actually use this info?
Usually this centers around our wildcard certificates,
which have been handed out like candy before...
Anyway, this is the best way to know which ones are valid/expiring
and we can point to it when some third party claims "some" certificate is expiring.

#### _logs_

There's a list of [Google trusted logs](https://www.gstatic.com/ct/log_list/log_list.json),
Which can be accessed through API
specified in [RFC 6962](https://datatracker.ietf.org/doc/html/rfc6962).

_note:_ this api only provides head + numeric ranges of log entries.
