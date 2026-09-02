set export
TYPST_FEATURES:="bundle,html"
TYPST_ROOT:="./src/typst"
SHOW_DRAFTS := env_var_or_default("SHOW_DRAFTS", "false")

clean:
    rm ./src/typst/blog/{_posts,index,main}.typ
    rm ./out ./bin -rf

build:
    #!/usr/bin/env bash
    set -Eeuo pipefail
    rsync -r ./src/static ./out/
    just _generate_blog_idx
    typst c ./src/typst/main.typ ./out/ --format=bundle
    typst c ./src/typst/blog/main.typ ./out/blog --format=bundle
    just build-resume

serve:
    bunx vite ./out --host localhost --open --port 3030

build-resume:
    TYPST_ROOT=. typst c ./resume/resume/main.typ ./out/static/resume.pdf

dev:
    #!/usr/bin/env bash
    set -Eeuo pipefail

    check_tool() {
        if ! command -v "$1" >/dev/null 2>&1; then
            echo "Install $1 before running this script."
            exit 1
        fi
    }
    check_tool typst
    check_tool bun
    check_tool inotifywait

    # Build everything once, then only rebuild the output affected by a change.
    SHOW_DRAFTS=true just build

    just serve &
    PID=$!
    cleanup() {
        echo "Quitting..."
        kill "$PID" 2>/dev/null || true
        wait "$PID" 2>/dev/null || true
    }
    trap cleanup EXIT SIGINT SIGTERM

    rebuild_blog_indexes() {
        SHOW_DRAFTS=true just _generate_blog_idx

        # Rebuild the two blog indexes and the home page's recent-post list,
        # but leave unrelated pages and posts alone.
        printf '%s\n' \
            '#document("index.html", title: "Home", format: "html")[#include("src/typst/index.typ")]' \
            '#document("blog.html", title: "Blog", description: "An index of blog posts.", format: "html")[#include("src/typst/blog/index.typ")]' \
            '#document("blog/index.html", title: "Index", description: "A list of blog posts.", format: "html")[#include("src/typst/blog/index.typ")]' \
            | TYPST_ROOT=. typst c - ./out/ --format=bundle
    }

    while true; do
        changed=$(inotifywait -q -r \
            -e close_write,moved_to,delete \
            --format '%w%f' ./src)
        changed=${changed#./}

        case "$changed" in
            src/static/*)
                # Vite watches out/. Sync assets (including bursty moves/deletes)
                # and let it reload; no Typst work is needed. Keep the generated
                # résumé, which does not have a counterpart in src/static/.
                rsync -r --delete --exclude resume.pdf ./src/static/ ./out/static/
                ;;
            src/typst/blog/*.typ)
                filename=${changed##*/}
                case "$filename" in
                    main.typ|index.typ|_*.typ)
                        # Shared and generated blog files can affect every post.
                        SHOW_DRAFTS=true just build
                        ;;
                    *)
                        rebuild_blog_indexes
                        output="out/blog/${filename%.typ}.html"
                        if [[ -f "$changed" ]]; then
                            typst c "$changed" "$output" --format=html
                        else
                            rm -f "$output"
                        fi
                        ;;
                esac
                ;;
            *)
                # Main pages, templates, and Typst assets have wider dependency
                # graphs, so retain the safe full build for those changes.
                SHOW_DRAFTS=true just build
                ;;
        esac
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

        if [[ "$draft" == "true" && "$SHOW_DRAFTS" != "true" ]]; then
            return
        fi

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
