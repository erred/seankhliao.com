# Chaos Communication Congress Day 1

## 37c7 Unlocked

### Chaos Communication Congress

After a pause in events over the covid period (36c3 Resource Exhaustion was in 2019),
we finally have 37c3 Unlocked.
This time it's in Hamburg, Germany with a slightly smaller venue.

#### _day_ 0

I flew in from London,
landing earlier than scheduled, but there was a 1 hour passport queue...
Upon entry, I headed straight to the (Federal) Police desk
and registered for Germany's EasyPass-RTP Registered Traveller's Program,
hopefully next time I enter Germany I can go through the automatic gates.

What I didn't really anticipate was the lack of food options at 10pm
on the second day of christmas near my hotel.

#### _day_ 1

We start with coffee,
_Public Coffee Roasters_ was on the way to the conference center, it was fine.
Upon arrival at _Congress Center Hamburg_,
there was a long, but fast moving queue to get the wristband and get in.

Engrossed by the shiny lights in dark rooms,
I wandered around the assembly areas and suddenly an hour had passed.
Of course, before every talk, there's the reminder of the 6-2-1 rule:
every day, you should get: 6 hours of sleep, 2 meals, and 1 shower.

A few environmental observations:
There were a lot of _Framework_ laptops, which I guess is expected for a hacker conf
There were a lot of platic cat ear frames? not sure where they came from,
but also quite a few actual furry cat ears,
and one LED cat ears headphone.
I guess I can sort of find out what I'd look like to others here....

Wifi was partly available,
I think it was only in the afternoon that they discovered the setting to allow more than 2048 users.
IWD config was documented as:

```
# /var/lib/iwd/37C3.8021x
[Security]
EAP-Method=PEAP
EAP-Identity=anonymous@37C3
EAP-PEAP-CACert=/etc/ssl/certs/ISRG_Root_X1.pem
EAP-PEAP-ServerDomainMask=radius.c3noc.net
EAP-PEAP-Phase2-Method=MSCHAPV2
EAP-PEAP-Phase2-Identity=37C3
EAP-PEAP-Phase2-Password=37C3

[Settings]
AutoConnect=true
```

##### Place & route on silicon

A gentle intro into the parts that go into laying out a circuit onto a pcb:
force simulating graphs, power grids, and filling with capacitators?

##### Apple's iPhone 15: Under the C

USB pins and debugging interfaces.

##### Please Identify Yourself!

Lessons learned from India's Aadhaar digital identity system
and maybe the future of Europe's eIDAS.

##### YOU’VE JUST BEEN FUCKED BY PSYOPS

Your mind is weak and susceptible to misinformation campaigns,
like the CIA's involvement with aliens.

##### Unlocked! Recovering files taken hostage by ransomware

Hackers use a fixed 64bit key to encrypt files (mostly vm disk images).
Find 0-block, get key, decrypt.

##### Bifröst: Apple's Rainbow Bridge for Satellite Communication

Sprinle magic dust to combine an apple provided security testing device of the previous generation
(no satellite comm hardware) with current gen device to look into Find My's satellite positioning.
Also, get locked out because of abuse prevention?

##### SMTP Smuggling – Spoofing E-Mails Worldwide

Text protocols bad and the endless lf/cr debates are bad.
Binary data all the things

##### Sucking dust and cutting grass: reversing robots and bypassing security
