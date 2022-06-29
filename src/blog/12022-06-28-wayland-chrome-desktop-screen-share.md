# desktop screen sharing with chrome on wayland

## see everything

### _linux_

Linux has a mish mash of evolving protocols,
the two which concern us today are Wayland and Pipewire.

_chrome:_ right now,
chrome should just need `-ozone-platform=wayland` to natively run under wayland.
It also needs
[WebRTC PipeWire support](chrome://flags/#enable-webrtc-pipewire-capturer)
to capture the desktop.

[xdg-desktop-portal-wlr](https://github.com/emersion/xdg-desktop-portal-wlr)
is a [desktop-portal](https://github.com/flatpak/xdg-desktop-portal)
for wlroots based desktop environments such as [Sway](https://swaywm.org/).
Basically, a way for applications to access generic desktop functionality over a well known API.
You'll want `systemctl --user enable xdg-desktop-portal-wlr`,
this has activation conditions based on the environment.

`sway` needs to trigger the start of `xdg-desktop-portal-wlr`,
`exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway`
should be enough.

And magic.
