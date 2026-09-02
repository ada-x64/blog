set export
TYPST_FEATURES:="bundle,html"
TYPST_ROOT:="./src/typst"
SHOW_DRAFTS := env_var_or_default("SHOW_DRAFTS", "false")

check_deps +deps='typst rsync jq':
    MISSING=()
    for DEP in {{deps}}; do
        which $DEP 2>/dev/null 1>/dev/null;
        if [ $? == 0 ]; then
            MISSING+=($DEP)
        fi
    done
    if [ ${#MISSING[@]} != 0 ]; then
        echo "Missing dependencies detected."
        for item in "${MISSING[@]}"; do
            echo "- $item";
        done;
    fi

clean:
    #!/bin/bash
    rm -rf \
        ./src/typst/blog/{_posts,index,main}.typ \
        ./src/typst/blog/.cache \
        ./out ./bin

build:
    #!/usr/bin/env bash
    set -Eeuo pipefail
    just check_deps
    rsync -r ./src/static ./out/
    just _generate_blog_idx
    typst c ./src/typst/main.typ ./out/ --format=bundle
    typst c ./src/typst/blog/main.typ ./out/blog --format=bundle
    just build-resume

build-resume:
    TYPST_ROOT=. typst c ./resume/resume/main.typ ./out/static/resume.pdf

dev:
    check_deps bun
    bunx vite

# With no argument, refresh every cached metadata record. Passing a changed
# post path only evaluates and replaces that post's record.
_generate_blog_idx changed="":
    #!/usr/bin/env bash
    set -Eeuo pipefail
    shopt -s nullglob

    cd ./src/typst/blog
    MAIN="./main.typ"
    IDX="./index.typ"
    POSTS="./_posts.typ"
    CACHE="./.cache"
    TYPST_ROOT=../
    HEADER="// This file is auto-generated. Do not modify!"
    changed='{{changed}}'
    mkdir -p "$CACHE"/{published,drafts}

    # A failed clean metadata pass can leave a partial cache. Retry the clean
    # pass before accepting incremental updates.
    if [[ -n "$changed" && ! -f "$CACHE/.complete" ]]; then
        changed=""
    fi

    # Concatenate one kind of cached fragment into a generated Typst file.
    # `nullglob` above makes `fragments` empty when the cache has no matches.
    append_cached_fragments() {
        local output_file=$1
        local publication_status=$2
        local fragment_kind=$3
        local fragments=("$CACHE/$publication_status"/*."$fragment_kind".typ)

        if (( ${#fragments[@]} > 0 )); then
            cat "${fragments[@]}" >> "$output_file"
        fi
    }

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

    cache_post() {
        local filepath=$1
        local slug="${filepath%.typ}.html"
        local key="${filepath#./}"
        local json title description date draft destination
        key="${key//\//__}"
        key="${key%.typ}"

        # Remove both possible records when a post is deleted or changes its
        # draft status.
        if [[ ! -f "$filepath" ]]; then
            rm -f "$CACHE"/{published,drafts}/"$key".{document,post}.typ
            return
        fi

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
        destination="$CACHE/$([[ "$draft" == "true" ]] && echo drafts || echo published)"

        rm -f "$CACHE"/{published,drafts}/"$key".{document,post}.typ
        cat > "$destination/$key.document.typ" <<EOF
    #document(
        "$slug",
        title: $title,
        description: $description,
        date: $date,
        format: "html",
        )[
        #include("$filepath")
    ]
    EOF
        cat > "$destination/$key.post.typ" <<EOF
    (
        path: "$slug",
        title: $title,
        description: $description,
        date: $date,
        draft: $draft
    ),
    EOF
    }

    if [[ -z "$changed" ]]; then
        rm -rf "$CACHE"
        mkdir -p "$CACHE"/{published,drafts}

        # Keep imports valid while each post is queried during a clean build.
        printf '%s\n#let posts = ()\n' "$HEADER" > "$POSTS"
        while IFS= read -r -d '' filepath; do
            cache_post "$filepath"
        done < <(
            find . -type f -name '*.typ' \
                -not -name 'main.typ' \
                -not -name 'index.typ' \
                -not -name '_*.typ' \
                -print0 | sort -z
        )
        touch "$CACHE/.complete"
    else
        filepath="./${changed#src/typst/blog/}"
        cache_post "$filepath"
    fi

    printf '%s\n' "$HEADER" > "$MAIN"
    append_cached_fragments "$MAIN" published document
    if [[ "$SHOW_DRAFTS" == "true" ]]; then
        append_cached_fragments "$MAIN" drafts document
    fi

    printf '%s\n#let posts = (\n' "$HEADER" > "$POSTS"
    append_cached_fragments "$POSTS" published post
    if [[ "$SHOW_DRAFTS" == "true" ]]; then
        append_cached_fragments "$POSTS" drafts post
    fi
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
