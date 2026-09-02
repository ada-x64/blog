#!/bin/bash

curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ./bin/
export PATH="$(pwd)/bin/:$PATH"
just build
