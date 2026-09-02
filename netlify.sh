#!/bin/bash

curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ./bin/
export TYPST_INSTALL="./bin"
curl -fsSL https://install.typst.community/install.sh | sh
export PATH="$(pwd)/bin/:$PATH"
just build
