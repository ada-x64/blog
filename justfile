set export
TYPST_FEATURES:="bundle,html"
TYPST_ROOT:="./src/typst"

build:
    #!/bin/bash
    rsync -r ./src/static ./out/
    typst c ./src/typst/main.typ ./out/ --format=bundle

dev:
    #!/bin/bash
    which inotifywait 1>/dev/null 2>/dev/null
    which bunx 1>/dev/null 2>/dev/null
    if [ $? != 0 ]; then
        echo "Install inotify-tools and bun before running this script."
        exit 1
    fi
    bunx http-server ./out -a localhost -o &
    PID=$!
    cleanup() {
        echo "Quitting..."
        kill $PID 2>/dev/null
        exit 0
    }
    trap cleanup SIGINT SIGTERM
    while true; do
        just build
        inotifywait -q -r -e modify,move,create,delete ./src
    done
