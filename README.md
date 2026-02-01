# Dotfiles setup

Scripts to setup dotfiles and install some software on a new machine.

## Installation

Run the main install script to set up a fresh Mac:

```sh
curl -L https://raw.githubusercontent.com/en9inerd/dotfiles-setup/master/install.sh | bash
```

This installs:
- Homebrew (if not present)
- CLI tools: tmux, jq, go, fnm, gpg, tree-sitter-cli, pinentry-mac, pyenv, webp, rg, zola, fd, fzf
- AeroSpace (tiling window manager)
- Ghostty (terminal emulator)
- Neovim (nightly build)
- sdfm (dotfiles manager)

## Standalone Scripts

### Neovim

Install or update Neovim nightly to `~/.nvim`:

```sh
curl -fsSL https://raw.githubusercontent.com/en9inerd/dotfiles-setup/master/install-neovim.sh | bash
```

### Ghostty

Install or update Ghostty terminal emulator:

```sh
curl -fsSL https://raw.githubusercontent.com/en9inerd/dotfiles-setup/master/install-ghostty.sh | bash
```

### Zig and ZLS

Install or update Zig compiler and ZLS language server:

```sh
curl -fsSL https://raw.githubusercontent.com/en9inerd/dotfiles-setup/master/install-zig.sh | bash
```

Optionally specify a target directory:

```sh
curl -fsSL https://raw.githubusercontent.com/en9inerd/dotfiles-setup/master/install-zig.sh | bash -s -- /path/to/dir
```

### Enable Undercurl

Add undercurl support to your terminal's terminfo:

```sh
curl -sL https://raw.githubusercontent.com/en9inerd/dotfiles-setup/master/enable-undercurl.sh | bash
```
