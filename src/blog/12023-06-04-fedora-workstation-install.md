# fedora workstation install

## new distro

### _fedora_ workstation

For work, we can install some flavor of linux,
I think the only hard requirement is that it runs the corporate spy agent made by jumpcloud.
Previously, I ran Ubuntu 22.04 but that installation slowly decayed over time.
So what better thing to do than to start fresh?

#### _install_

After a bit of head scratching and experimentation,
I went ahead an installed [Fedora Workstation 38](https://fedoraproject.org/workstation/).
The [jumpcloud](https://jumpcloud.com/) agent we were required to install technically only supported 37,
but I couldn't find a suitable download link easily.
The default setup of Fedora Workstation comes with GNOME,
but I sort of knew I wanted Sway.
I attempted to install using their [Sway spin](https://fedoraproject.org/spins/sway/)
but couldn't get the installer to actually do anything.

The installer is pretty straightforward.
Select language, timezone, disk, disk encryption,
and just wait a bit.

#### _first_ boot

On first boot, you create a user from the ui.
Once in, connect to the internet!
Finally, update the system and reboot.

```sh
$ sudo dnf update
$ sudo dnf upgrade
```

#### _installing_ tools

Now for setting up my preferred dev environment.

##### _system_ setup

Set the machine name and enable a few repos,
plus the most basic of tools.

```sh
# choose a name for the computer
$ hostnamectl hostname luna

# add/enable some third party repos
$ sudo dnf config-manager --set-enabled google-chrome
$ sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
$ sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
$ sudo dnf config-manager --add-repo "$(rpm --eval "https://yum.releases.teleport.dev/rhel/9/Teleport/%{_arch}/stable/v13/teleport.repo")"
$ sudo dnf install \
  google-chrome-stable \
  kitty \
  neovim \
  zsh
$ usermod --shell /usr/bin/zsh user
```

Grab a copy of my dotfiles

```sh
$ mkdir .ssh && cd .ssh
$ ssh-keygen -t ed25519
$ git clone git@github.com:seankhliao/config.git
$ mv config/* config/.git config/.gitignore -t .config
$ rmdir config
```

and relog / reboot

##### _desktop_ switch

Now to switch over to sway.

```sh
# switch out the desktop environment
$ sudo dnf install \
  akmod-nvidia \
  grim \
  mako \
  slurp \
  sway \
  sway \
  swaybg \
  swayidle \
  swaylock \
  sway-systemd \
  wf-recorder \
  wireplumber \
  wofi \
  xdg-desktop-portal-wlr
# edit to set --unsupported-gpu for nvidia
$ nvim /usr/share/wayland-sessions/sway.desktop
$ systemctl enable --user --now mako
```

##### _quality_ of life

Power management

```sh
$ sudo dnf install \
  powertop \
  tlp \
  tlp-rdw
$ sudo systemctl enable tlp tlp-sleep powertop
```

yubikey setup for sudo / unlock

```sh
# for the first key
$ pamu2fcfg -o pam://luna -i pam://luna > u2f_keys
# for subsequent keys
$ pamu2fcfg -o pam://luna -i pam://luna -n >> u2f_keys
$ sudo cp u2f_keys /etc/u2f_keys

# add it to the auth flows
#   auth 	    sufficient  				 pam_u2f.so origin=pam://luna appid=pam://luna authfile=/etc/u2f_keys cue [cue_prompt=touche]
$ nvim /etc/pam.d/system-auth
```

##### _dev_ tools

Some tools are in the fedora repos

```sh
# dev tools that are in the repo.
$ sudo dnf install \
  bat \
  containerd.io \
  docker-buildx-plugin \
  docker-ce \
  docker-ce-cli \
  docker-compose \
  docker-compose-plugin \
  docker-distribution \
  exa \
  fzf \
  git-delta \
  go \
  helm \
  htop \
  i3status \
  pre-commit \
  ripgrep \
  shellcheck \
  teleport-ent \
  terraform
```

Others can be built from source with Go

```sh
$ go env -w GOPROXY=https://proxy.golang.org,direct
$ go env -w GOPRIVATE=github.com/snyk
$ go install github.com/ankitpokhrel/jira-cli/cmd/jira@latest
$ go install github.com/derailed/k9s@latest
$ go install github.com/gokcehan/lf@latest
$ go install github.com/GoogleCloudPlatform/docker-credential-gcr@latest
$ go install github.com/google/go-containerregistry/cmd/gcrane@latest
$ go install github.com/google/ko@latest
$ go install github.com/hashicorp/terraform-ls@latest
$ go install github.com/mikefarah/yq/v4@latest
$ go install github.com/sigstore/cosign/v2/cmd/cosign@latest
$ go install github.com/wagoodman/dive@latest
$ go install golang.org/x/tools/gopls@latest
$ go install golang.org/x/vuln/cmd/govulncheck@latest
$ go install go.seankhliao.com/repos@latest
$ go install go.seankhliao.com/t@latest
$ go install honnef.co/go/tools/cmd/staticcheck@latest
$ go install mvdan.cc/gofumpt@latest
$ go install mvdan.cc/sh/v3/cmd/shfmt@latest
```

Some just are binary releases installed into `/usr/local/bin`:

- argocd
- aws
- circleci-cli
- gcloud
- istioctl
- krew
- kubens
- kustomize
- otelcol-contrib
- skaffold
- snyk
- vector

And then we have the little ecosystem of extra plugin managers

- gcloud components remove bq gsutil
- gcloud components install alpha beta kubectl
- kubectl krew install get-all view-secret
- nvim +PackerUpdate

And some dev tools from npm

```sh
$ sudo npm i -g bash-language-server
$ sudo npm i -g dockerfile-language-server-nodejs
$ sudo npm i -g prettier
$ sudo npm i -g typescript-language-server
$ sudo npm i -g vscode-langservers-extracted
$ sudo npm i -g yaml-language-server
```

##### _config_ tweaks

###### _completions_

For the non repo tools, some have zsh completions that can be generated:

```sh
$ tool completion zsh > ~/.config/zsh/_tool
```

###### _zsh_ functions

copy over my tree of login configs and the functions for switching

- argocd logins
- kube logins
- aws logins

```sh
function ctx() {
    local config="${1}"
    if [[ -z "${config}" ]]; then
        config=$(cd ~/.config/argocd/  && rg --files | rg -v .prex-ctx | sort | fzf)
    fi
    if [[ -n "${config}" ]]; then
        export ARGOCD_OPTS="--config ${XDG_CONFIG_HOME}/argocd/${config}"
        export KUBECONFIG="${XDG_CONFIG_HOME}/kube/${config}"
        echo "ctx ${config}"
    fi
}

function actx() {
    local aws_profile="${1}"
    if [[ -z "${aws_profile}" ]]; then
        aws_profile=$(rg '^\[profile (.*)\]$' -r '$1' -N ~/.aws/config | sort | fzf)
    fi
    if [[ -n "${aws_profile}" ]]; then
        export AWS_PROFILE="${aws_profile}"
        echo "actx ${aws_profile}"
    fi
}
```

###### _repos_

copy over my [chrome-newtab](https://github.com/seankhliao/chrome-newtab) fork

###### _history_

copy over zsh history

###### _git_

Change `.config/git/local.conf`

```gitconfig
[commit]
    gpgSign = true

[gpg]
    format = ssh

[gpg "ssh"]
    allowedSignersFile = ~/.ssh/git/allowed_signers

[tag]
    gpgSign = true

[user]
    email = me@example.com
    name  = me
    signingKey = ~/.ssh/id_ed25519
```
