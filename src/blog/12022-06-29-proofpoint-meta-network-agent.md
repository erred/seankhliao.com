# proofpoint meta network agent

## is this really zero trust?

### _proofpoint_ meta agent

[proofpoint](https://www.proofpoint.com/)
has a "Zero Trust Network Access" (ZTNA) product (Proofpoint SSP)
from their Meta Networks [acquisition](https://www.proofpoint.com/us/newsroom/press-releases/proofpoint-enters-definitive-agreement-acquire-meta-networks-boosting-cloud).

So, what does it take to get their agent running on an Arch Linux machine?

#### _get_ the agent.

As far as I can tell, the download listing is only available from a logged in console,
at `https://<orgid>.metanetworks.com/ssp/home`.
That links to a download, ex at:
`https://clients.metanetworks.com/zero/linux/releases/meta-agent-4_1_11.run`.
This is a self extracting archive created via
[makeself](https://makeself.io/).

_note:_ There are 2 options, full and CLI only,
so far I've only gotten the full version (with gui) to work.

Of course the script only really supports Debian-based distros,
and I'm on Arch Linux,
so we get to do it by hand.
`chmod +x ./meta-agent.run` to make it runnable,
`./meta-agent --list` to list out the archive contents.
Then we can get the individual files with `./meta-agent --tar xf $file1 $file2...`
The important ones are: the strongswan, agent and zerp-gui snaps

#### _installing_

- `sudo snap install ./meta-agent-strongswan_amd64.snap --classic --dangerous`
- `sudo snap install ./meta-service_amd64.snap --classic --dangerous`
- `sudo snap install ./zero-gui --dangerous`
- `sudo snap alias meta-service.cli meta`

There are also system dependencies on openvpn (I think).

_note:_ the meta-client uses X11, if on wayland (eg sway),
you'll want the xorg-xwayland and dependencies.

#### _run_

Once that's setup,
`meta-client` will start the little ui app, where you can log in via its embedded browser,
and it can start the tunnel.
If it's stuck, it might be dumb and you need to go to profiles to force renew it.

It apparently takes over all of IPv6 networking, hope you didn't need it for anything else.
Also, if you have a `resolvconf` installed, it will add its nameserver,
if not, you'll probably want to add it manually (`nameserver 2a0a:4b00::`)
