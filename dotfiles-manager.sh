#!/usr/bin/env bash

# Script to manage dotfiles

allowed_commands=("status" "add" "commit" "push" "pull" "log" "diff" "checkout")

if [[ " ${allowed_commands[@]} " =~ " $1 " ]]; then
    /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $@
else
    echo "Error: Command '$1' is not allowed for the dotfiles repository."
    echo "Allowed commands: ${allowed_commands[@]}"
    exit 1
fi
