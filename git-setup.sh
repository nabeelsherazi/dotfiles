#!/bin/bash

read -r -p "Enter name: " NAME
read -r -p "Enter email: " EMAIL

# Setup git

echo "Setting up with name '${NAME}' and email '${EMAIL}'"

git config --global user.name "${NAME}"
git config --global user.email "${EMAIL}"

# Convenience

echo "Adding auto URL rewrite to SSH"
git config --global --replace-all url."git@github.com:".insteadOf https://github.com/
git config --global --add         url."git@github.com:".insteadOf http://github.com/

echo "Setting default reconciliation strategy to rebase"
git config --global pull.rebase true

# Generate key
ssh-keygen -t ed25519 -C "${EMAIL}"

# Start SSH agent
eval "$(ssh-agent -s)"

# Add key to SSH agent
ssh-add ~/.ssh/id_ed25519

# Print key
echo "Enter this SSH key into GitHub"
cat ~/.ssh/id_ed25519.pub
