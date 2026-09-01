set export
TYPST_FEATURES:="bundle,html"
TYPST_ROOT:="./src/typst"

clean:
    rm -rf ./out

build:
    #!/bin/bash
    rsync -r ./src/static ./out/
    typst c ./src/typst/main.typ ./out/ --format=bundle
    just _generate_blog_idx
    typst c ./src/typst/blog/main.typ ./out/blog --format=bundle

dev:
    #!/bin/bash
    which inotifywait 1>/dev/null 2>/dev/null
    which bunx 1>/dev/null 2>/dev/null
    if [ $? != 0 ]; then
        echo "Install inotify-tools and bun before running this script."
        exit 1
    fi
    bunx vite ./out --host localhost --open --port 3030 &
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

_generate_blog_idx:
    #!/bin/bash
    cd ./src/typst/blog
    export MAIN="./main.typ"
    export IDX="./index.typ"
    TYPST_ROOT=../
    HEADER="// This file is auto-generated. Do not modify!"
    echo "$HEADER" > "$MAIN"
    echo "\
    #document(
        \"index.html\",
        title: \"Index\",
        description: \"A list of blog posts.\",
        format: \"html\",
        )[
        #include(\"./index.typ\")
    ]" >> "$MAIN"
    echo "$HEADER" > "$IDX"
    cat <<EOF >> "$IDX"
        #import("_template.typ"): index_list
        #import("../_template.typ"): conf
        #show: conf
        = /blog
        #let posts = (
    EOF
    function add_to_idx() {
        # Collect data
        FILEPATH=$1
        SLUG=$(echo $FILEPATH | sed -e "s/\.typ/\.html/gi")
        JSON=$(typst eval "query(metadata).first().value" --in "$FILEPATH" --target html)
        TITLE=$(echo "$JSON" | jq ".title")
        DESCRIPTION=$(echo "$JSON" | jq '.description')
        DATE=$(echo "$JSON" | jq -r '.date // "none"')
        echo "$SLUG :: $JSON"

        # Add to bundle
        echo "\
        #document(
            \"$SLUG\",
            title: $TITLE,
            description: $DESCRIPTION,
            date: $DATE,
            format: \"html\",
            )[
            #include(\"$FILEPATH\")
        ]" >> "$MAIN"

        # Add to index
        echo "\
        (
            path: \"$SLUG\",
            title: $TITLE,
            description: $DESCRIPTION,
            date: $DATE
        )," >> "$IDX"
    }
    export -f add_to_idx;
    find . -type f -name '*.typ' -a -not -name 'main.typ' -a -not -name 'index.typ' -a -not -name '_template.typ' -exec bash -c 'add_to_idx "{}"' \;
    echo -e ")\n#index_list(posts)" >> "$IDX"
