#!/bin/bash
# Copyright (c) 2022, Andrew Smith <aws@awsmith.us> :::::::::::: SOLI DEO GLORIA
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This script performs one-time setup tasks that are only necessary for fresh
# operating system installations.  In order to prevent these tasks from being
# executed multiple times, it creates an empty file "~/.awsmith-setup": if this
# file exists, this script will refuse to run.

if [ -e $HOME/.awsmith-setup ]; then
    echo "This system is already set up!"
    exit 1
fi

# Install VSCod{e,ium} extensions.
vscode_extension_ids=(
    EditorConfig.EditorConfig
    GitHub.github-vscode-theme
    Gruntfuggly.todo-tree
    iocave.customize-ui
    iocave.monkey-patch
    jeandeaual.lilypond-syntax
    jeandeaual.scheme
    ms-python.python
    ocamllabs.ocaml-platform
    sainnhe.gruvbox-material
    vscodevim.vim
)
for id in "${vscode_extension_ids[@]}"; do
    if hash codium; then
        codium --install-extension $id
    else
        code --install-extension $id
    fi
done

touch $HOME/.awsmith-setup
