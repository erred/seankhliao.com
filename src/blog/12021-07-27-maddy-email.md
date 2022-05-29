# maddy email

## finally a decent way of hosting email


### _email_ hosting

I'm not crazy enough to host my own email for my main account,
deliverability issues are too much of pain to be worth it.
But I do want to host an email server for transactional / notification things
for the services I run.

Traditionally this would have been the job of `sendmail`, `exim`, `postfix`, ...
But these were written for a different age,
being a pain to configure and manage (who want to tie accounts to linux accounts...).

Anyway, [maddy](https://maddy.email/) is a promising project where everything
is just a single process.

#### _dns_

Email and DNS are... not very separable.

To deliver mail to an address like `foo@seankhliao.com`,
you look up _MX_ records for `seankhliao.com`
and try to connect to one of the hosts listed there
(traditionally something like `mx1.seankhliao.com`)
over port 25 and do _SMTP(S)_.
The only security improvement you can do over this is
[MTA-STS](https://datatracker.ietf.org/doc/html/rfc8461):
check for a `_mta-sts.seankhliao.com` _DNS TXT_ record
and then check for a policy file over _HTTPS_
from `mta-sts.seankhliao.com/.well-known/mta-sts.txt`.
Don't ask why it needs 2 different subdomains.

Technically there's also _DANE_ using _DNS TLSA_ records
to pin TLS certs to domains but support is lacking for the big providers.

To receive mail from `foo@seankhliao.com`,
basically have port 25 open and wait.
Since mail is relay based, anyone could hand you mail claiming to be from someone else.
_SPF_ sort of breaks the relaying by saying it has to come from the listed servers,
_DKIM_ signs the messages so they can actually be verified,
and _DMARC_ standardizes reporting for failed checks.

#### _maddy_

Setup is pretty straightforward,
set `primary_domain` to the domain you want in your address,
`hostname` to where maddy is running,
get a tls cert and that's more or less it.
The rest of the config can just be default.
I also stripped out the non TLS ports.

User management is through a CLI `maddyctl`,
unfortunately not declarative,
but not the end of the world.

#### _testing_

[curl](https://curl.se/) ftw.

`.netrc` can be used to skip passing a user/pass every time.

##### _receiving_ mail

This uses port 993

1. Create account and imap mailbox
2. Send email from some other provider
3. get mails in _INBOX_, not sure why a plain request doesn't work. `curl -u your@account.com:password imaps://mx1.account.com/INBOX` -X `FETCH 1:10 ALL`
4. get a specific mail `curl -u your@account.com:password imaps://mx1.account.com/INBOX;UID=1`

##### _sending_ mail

Port 465

1. write message in `hello.txt`
   - `From: ...`
   - `To: ...`
   - `Subject: ...`
2. `curl smtps://mx1.account.com:465 --mail-from your@account.com --mail-rcpt foo@example.com -u your@account.com:password --upload-file hello.txt`
3. wait to see if you get it

#### _config_ dump

##### _k8s_ container

```yaml
containers:
- name: maddy
  image: docker.io/foxcpp/maddy:latest
  ports:
  - name: smtp
    containerPort: 25
    hostPort: 25
  - name: submittls
    containerPort: 465
    hostPort: 465
  - name: imaptls
    containerPort: 993
    hostPort: 993
  - name: metrics
    containerPort: 9749
  volumeMounts:
    - name: config
      mountPath: /data/maddy.conf
      subPath: maddy.conf
    - name: data
      mountPath: /data
    - name: tls
      mountPath: /var/run/secrets/tls
```

##### _maddy.conf_

```
## Maddy Mail Server - default configuration file (2021-03-07)
# Suitable for small-scale deployments. Uses its own format for local users DB,
# should be managed via maddyctl utility.
#
# See tutorials at https://maddy.email for guidance on typical
# configuration changes.
#
# See manual pages (also available at https://maddy.email) for reference
# documentation.

# ----------------------------------------------------------------------------
# Base variables

$(hostname) = mx1.medea.seankhliao.com
$(primary_domain) = medea.seankhliao.com
$(local_domains) = $(primary_domain)

tls file /var/run/secrets/tls/tls.crt /var/run/secrets/tls/tls.key

#
openmetrics tcp://0.0.0.0:9749 { }

# ----------------------------------------------------------------------------
# Local storage & authentication

# pass_table provides local hashed passwords storage for authentication of
# users. It can be configured to use any "table" module, in default
# configuration a table in SQLite DB is used.
# Table can be replaced to use e.g. a file for passwords. Or pass_table module
# can be replaced altogether to use some external source of credentials (e.g.
# PAM, /etc/shadow file).
#
# If table module supports it (sql_table does) - credentials can be managed
# using 'maddyctl creds' command.

auth.pass_table local_authdb {
    table sql_table {
        driver sqlite3
        dsn credentials.db
        table_name passwords
    }
}

# imapsql module stores all indexes and metadata necessary for IMAP using a
# relational database. It is used by IMAP endpoint for mailbox access and
# also by SMTP & Submission endpoints for delivery of local messages.
#
# IMAP accounts, mailboxes and all message metadata can be inspected using
# imap-* subcommands of maddyctl utility.

storage.imapsql local_mailboxes {
    driver sqlite3
    dsn imapsql.db
}

# ----------------------------------------------------------------------------
# SMTP endpoints + message routing

hostname $(hostname)

msgpipeline local_routing {
    # Insert handling for special-purpose local domains here.
    # e.g.
    # destination lists.example.org {
    #     deliver_to lmtp tcp://127.0.0.1:8024
    # }

    destination postmaster $(local_domains) {
        modify {
            replace_rcpt regexp "(.+)\+(.+)@(.+)" "$1@$3"
            replace_rcpt file /etc/maddy/aliases
        }

        deliver_to &local_mailboxes
    }

    default_destination {
        reject 550 5.1.1 "User doesn't exist"
    }
}

smtp tcp://0.0.0.0:25 {
    limits {
        # Up to 20 msgs/sec across max. 10 SMTP connections.
        all rate 20 1s
        all concurrency 10
    }

    dmarc yes
    check {
        require_mx_record
        dkim
        spf
    }

    source $(local_domains) {
        reject 501 5.1.8 "Use Submission for outgoing SMTP"
    }
    default_source {
        destination postmaster $(local_domains) {
            deliver_to &local_routing
        }
        default_destination {
            reject 550 5.1.1 "User doesn't exist"
        }
    }
}

submission tls://0.0.0.0:465 {
    limits {
        # Up to 50 msgs/sec across any amount of SMTP connections.
        all rate 50 1s
    }

    auth &local_authdb

    source $(local_domains) {
        destination postmaster $(local_domains) {
            deliver_to &local_routing
        }
        default_destination {
            modify {
                dkim $(primary_domain) $(local_domains) default
            }
            deliver_to &remote_queue
        }
    }
    default_source {
        reject 501 5.1.8 "Non-local sender domain"
    }
}

target.remote outbound_delivery {
    limits {
        # Up to 20 msgs/sec across max. 10 SMTP connections
        # for each recipient domain.
        destination rate 20 1s
        destination concurrency 10
    }
    mx_auth {
        dane
        mtasts {
            cache fs
            fs_dir mtasts_cache/
        }
        local_policy {
            min_tls_level encrypted
            min_mx_level none
        }
    }
}

target.queue remote_queue {
    target &outbound_delivery

    autogenerated_msg_domain $(primary_domain)
    bounce {
        destination postmaster $(local_domains) {
            deliver_to &local_routing
        }
        default_destination {
            reject 550 5.0.0 "Refusing to send DSNs to non-local addresses"
        }
    }
}

# ----------------------------------------------------------------------------
# IMAP endpoints

imap tls://0.0.0.0:993 {
    auth &local_authdb
    storage &local_mailboxes
}
```
