set export
TYPST_FEATURES:="bundle,html"
TYPST_ROOT:="./src/typst"

clean:
    rm -rf ./out
    rm -f ./src/typst/blog/{_posts.typ,index.typ,main.typ}

build:
    #!/usr/bin/env bash
    set -Eeuo pipefail
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
    #!/usr/bin/env bash
    set -Eeuo pipefail

    cd ./src/typst/blog
    MAIN="./main.typ"
    IDX="./index.typ"
    POSTS="./_posts.typ"
    TYPST_ROOT=../
    HEADER="// This file is auto-generated. Do not modify!"

    # Keep the imported collection valid while querying each post. Metadata is
    # held in memory and all generated files are then written directly.
    printf '%s\n#let posts = ()\n' "$HEADER" > "$POSTS"

    declare -a DOCUMENTS=()
    declare -a POST_RECORDS=()

    parse_item() {
        local json=$1
        local expression=$2
        local filter='
            if . == null then "none"
            elif type == "string" then @json
            else tostring
            end'
        jq -r "$expression | $filter" <<< "$json"
    }

    add_to_idx() {
        local filepath=$1
        local slug="${filepath%.typ}.html"
        local json title description date draft

        if ! json=$(typst eval \
            "query(metadata).first().value" \
            --in "$filepath" \
            --target html
        ); then
            echo "Failed to query metadata: $filepath" >&2
            return 1
        fi

        title=$(parse_item "$json" '.title')
        description=$(parse_item "$json" '.description')
        date=$(jq -r '.date // "none"' <<< "$json")
        draft=$(jq -r '.draft // false' <<< "$json")

        DOCUMENTS+=("\
        #document(
            \"$slug\",
            title: $title,
            description: $description,
            date: $date,
            format: \"html\",
            )[
            #include(\"$filepath\")
        ]")

        POST_RECORDS+=("\
        (
            path: \"$slug\",
            title: $title,
            description: $description,
            date: $date,
            draft: $draft
        ),")
    }

    while IFS= read -r -d '' filepath; do
        add_to_idx "$filepath"
    done < <(
        find . -type f -name '*.typ' \
            -not -name 'main.typ' \
            -not -name 'index.typ' \
            -not -name '_*.typ' \
            -print0 | sort -z
    )

    printf '%s\n' "$HEADER" > "$MAIN"
    cat <<'EOF' >> "$MAIN"
    #document(
        "index.html",
        title: "Index",
        description: "A list of blog posts.",
        format: "html",
        )[
        #include("./index.typ")
    ]
    EOF
    printf '%s\n' "${DOCUMENTS[@]}" >> "$MAIN"

    printf '%s\n#let posts = (\n' "$HEADER" > "$POSTS"
    printf '%s\n' "${POST_RECORDS[@]}" >> "$POSTS"
    echo ")" >> "$POSTS"

    printf '%s\n' "$HEADER" > "$IDX"
    cat <<'EOF' >> "$IDX"
        #import("_template.typ"): index_list
        #import("_posts.typ"): posts
        #import("../_template.typ"): conf
        #show: conf
        = /blog
        #index_list(posts)
    EOF
