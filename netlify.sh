#!/bin/bash

curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ./bin/
export TYPST_INSTALL="./"
curl -fsSL https://install.typst.community/install.sh | sh
curl -fsSL https://bun.sh/install | bash
export PATH="$(pwd)/bin/:$HOME/.bun/bin:$PATH"

FONT_HOME="$HOME/.local/share/fonts"
echo "Installing fonts to $FONT_HOME"
mkdir -p "$FONT_HOME"
find ./resume/ ./src/public/fonts -type f \
  \( -name '*.ttf' -o -name '*.otf' \) \
  -exec cp -t "$FONT_HOME" {} +
ls -l "$FONT_HOME"
fc-cache -f -v
just build
