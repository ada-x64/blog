set export
TYPST_FEATURES:="bundle,html"
TYPST_ROOT:="./src/typst"

clean:
    rm -rf ./out
    rm ./src/typst/blog/{_posts.typ,index.typ,main.typ}

build:
    #!/bin/bash
    rsync -r ./src/static ./out/
    just _generate_blog_idx
    typst c ./src/typst/main.typ ./out/ --format=bundle
    typst c ./src/typst/blog/main.typ ./out/blog --format=bundle

serve:
    bunx vite ./out --host localhost --open --port 3030

dev:
    #!/bin/bash
    which inotifywait 1>/dev/null 2>/dev/null
    which bunx 1>/dev/null 2>/dev/null
    if [ $? != 0 ]; then
        echo "Install inotify-tools and bun before running this script."
        exit 1
    fi
    just serve &
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
    # set up
    cd ./src/typst/blog
    export MAIN="./main.typ"
    export IDX="./index.typ"
    export POSTS="./_posts.typ"
    export POSTS_TMP=$(mktemp)
    trap 'rm -f "$POSTS_TMP"' EXIT
    TYPST_ROOT=../
    HEADER="// This file is auto-generated. Do not modify!"

    # Posts import the previously generated collection while their metadata is
    # queried. Bootstrap it on the first run, then replace it atomically below.
    if [ ! -f "$POSTS" ]; then
        printf '%s\n#let posts = ()\n' "$HEADER" > "$POSTS"
    fi
    printf '%s\n#let posts = (\n' "$HEADER" > "$POSTS_TMP"

    # set up main.typ
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

    # set up index.typ
    echo "$HEADER" > "$IDX"
    cat <<EOF >> "$IDX"
        #import("_template.typ"): index_list
        #import("_posts.typ"): posts
        #import("../_template.typ"): conf
        #show: conf
        = /blog
    EOF

    function add_to_idx() {

        function parse_item() {
            local filter='
                if . == null then "none"
                elif type == "string" then @json
                else tostring
                end'
            echo "$JSON" | jq -r "$1 | $filter"
        }

        # Collect data
        FILEPATH=$1
        SLUG=$(echo $FILEPATH | sed -e "s/\.typ/\.html/gi")
        JSON=$(typst eval "query(metadata).first().value" --in "$FILEPATH" --target html)
        TITLE=$(parse_item '.title')
        DESCRIPTION=$(parse_item '.description')
        DATE=$(echo "$JSON" | jq -r '.date // "none"')
        DRAFT=$(echo "$JSON" | jq -r '.draft // false')

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

        # Add to the shared post collection used by the index and post navigation.
        echo "\
        (
            path: \"$SLUG\",
            title: $TITLE,
            description: $DESCRIPTION,
            date: $DATE,
            draft: $DRAFT
        )," >> "$POSTS_TMP"
    }
    export -f add_to_idx;

    # main
    find . -type f -name '*.typ' -a -not -name 'main.typ' -a -not -name 'index.typ' -a -not -name '_*.typ' -exec bash -c 'add_to_idx "{}"' \;
    echo ")" >> "$POSTS_TMP"
    mv "$POSTS_TMP" "$POSTS"
    echo "#index_list(posts)" >> "$IDX"
