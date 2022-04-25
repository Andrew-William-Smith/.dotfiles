#!/bin/bash
# Copyright (c) 2022, Andrew Smith <aws@awsmith.us> :::::::::::: SOLI DEO GLORIA
# SPDX-License-Identifier: GPL-3.0-or-later
#
# SUMMARY
# =======
# This script performs one-time setup tasks that are only necessary for fresh
# operating system installations.  In order to prevent these tasks from being
# executed multiple times, it creates an empty file "~/.awsmith-setup": if this
# file exists, this script will refuse to run.
#
# OPTIONAL PROCEDURES
# ===================
# - Cinnamon
#   - To load a full dump of the Cinnamon settings, run:
#       $ dconf load /org/cinnamon/ < optional-setup-do-not-stow/cinnamon/cinnamon.ini
#       $ dconf load /org/gnome/ < optional-setup-do-not-stow/cinnamon/gnome.ini
#       $ dconf load /org/gtk/ < optional-setup-do-not-stow/cinnamon/gtk.ini
#       $ dconf load /org/nemo/ < optional-setup-do-not-stow/cinnamon/nemo.ini
#     Cinnamon will likely need to be restarted once these commands are run.
#   - The directory referenced above also contains a number of JSON files.  Each
#     of these files contains the configuration for a single applet: these
#     configurations will need to be restored manually through each applet's
#     settings.

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

echo "Done! See the source of this script for more setup actions that cannot be automated."
touch $HOME/.awsmith-setup
