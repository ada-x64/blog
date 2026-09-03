set export
TYPST_FEATURES:="bundle,html"
TYPST_ROOT:="./src/typst"
SHOW_DRAFTS := env_var_or_default("SHOW_DRAFTS", "false")

check_deps +deps='typst rsync jq xargs nproc':
    #!/bin/bash
    MISSING=()
    for DEP in {{deps}}; do
        which "$DEP" 2>/dev/null 1>/dev/null;
        if [ $? != 0 ]; then
            MISSING+=($DEP)
        fi
    done
    if [ ${#MISSING[@]} != 0 ]; then
        echo "Missing dependencies detected."
        for item in "${MISSING[@]}"; do
            echo "- $item";
        done;
        return 1
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
    mkdir -p ./out/static ./out/blog

    pids=()
    cleanup() {
        if (( ${#pids[@]} > 0 )); then
            kill "${pids[@]}" 2>/dev/null || true
        fi
    }
    trap cleanup EXIT INT TERM

    # These phases do not depend on generated blog metadata.
    just _sync_static &
    pids+=("$!")
    just build-resume &
    pids+=("$!")

    just _generate_blog_idx

    # Both bundles consume the generated metadata, but are independent of one
    # another once it is ready.
    just _compile_main &
    pids+=("$!")
    just _compile_blog &
    pids+=("$!")

    status=0
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            status=1
        fi
    done
    pids=()
    trap - EXIT INT TERM
    exit "$status"

_sync_static:
    rsync -r ./src/static ./out/

_compile_main:
    echo "main.typ"
    typst c ./src/typst/main.typ ./out/ --format=bundle

_compile_blog:
    echo "blog/main.typ"
    typst c ./src/typst/blog/main.typ ./out/blog --format=bundle

build-resume:
    mkdir -p ./out/static
    TYPST_ROOT=. typst c ./resume/resume/main.typ ./out/static/resume.pdf

dev:
    just check_deps bun
    bun run vite

# With no argument, refresh missing or stale metadata records. Passing a
# changed post path always evaluates and replaces that post's record.
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
    CACHE_VERSION=1
    changed='{{changed}}'
    metadata_jobs="${METADATA_JOBS:-$(nproc)}"
    if (( metadata_jobs > 8 )); then
        metadata_jobs=8
    elif (( metadata_jobs < 1 )); then
        metadata_jobs=1
    fi
    mkdir -p "$CACHE"/{published,drafts}

    # A failed metadata pass can leave a partial cache. Retry a complete scan
    # before accepting another incremental update.
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
        echo "caching $1"
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

        printf "%s\n
            #document(
                \"$slug\",
                title: $title,
                description: $description,
                date: $date,
                format: \"html\",
            )[
                #include(\"$filepath\")
            ]" > "$destination/$key.document.typ"

        printf "%s\n
            (
                path: \"$slug\",
                title: $title,
                description: $description,
                date: $date,
                draft: $draft
            )," > "$destination/$key.post.typ"

    }

    post_key() {
        local filepath=$1
        local key="${filepath#./}"
        key="${key//\//__}"
        printf '%s\n' "${key%.typ}"
    }

    record_is_stale() {
        local filepath=$1
        local key record
        local records=()
        key=$(post_key "$filepath")
        records=("$CACHE"/*/"$key".post.typ)
        if (( ${#records[@]} != 1 )); then
            return 0
        fi
        record=${records[0]}
        [[ ! -f "${record%.post.typ}.document.typ" || "$filepath" -nt "$record" ]]
    }

    # Keep imports valid while posts are queried during a clean build.
    if [[ ! -f "$POSTS" ]]; then
        printf '%s\n#let posts = ()\n' "$HEADER" > "$POSTS"
    fi

    if [[ -z "$changed" ]]; then
        force_refresh=false
        if [[ ! -f "$CACHE/.complete" || ! -f "$CACHE/.version" ]] ||
            [[ "$(cat "$CACHE/.version" 2>/dev/null || true)" != "$CACHE_VERSION" ]] ||
            [[ "./_template.typ" -nt "$CACHE/.complete" ]]; then
            force_refresh=true
        fi

        if [[ "$force_refresh" == "true" ]]; then
            rm -rf "$CACHE"
            mkdir -p "$CACHE"/{published,drafts}
        fi
        rm -f "$CACHE/.complete"

        mapfile -d '' filepaths < <(
            find . -type f -name '*.typ' \
                -not -path './.cache/*' \
                -not -name 'main.typ' \
                -not -name 'index.typ' \
                -not -name '_*.typ' \
                -print0 | sort -z
        )

        declare -A current_keys=()
        stale=()
        for filepath in "${filepaths[@]}"; do
            current_keys["$(post_key "$filepath")"]=1
            if [[ "$force_refresh" == "true" ]] || record_is_stale "$filepath"; then
                stale+=("$filepath")
            fi
        done

        # Remove records for posts that no longer exist.
        for record in "$CACHE"/{published,drafts}/*.post.typ; do
            key="${record##*/}"
            key="${key%.post.typ}"
            if [[ -z "${current_keys[$key]+present}" ]]; then
                rm -f "$CACHE"/{published,drafts}/"$key".{document,post}.typ
            fi
        done

        if (( ${#stale[@]} > 0 )); then
            export -f parse_item cache_post
            export CACHE TYPST_ROOT
            printf '%s\0' "${stale[@]}" |
                xargs -0 -r -n 1 -P "$metadata_jobs" \
                    bash -c 'cache_post "$1"' _
        fi
        printf '%s\n' "$CACHE_VERSION" > "$CACHE/.version"
    else
        rm -f "$CACHE/.complete"
        filepath="./${changed#src/typst/blog/}"
        cache_post "$filepath"
    fi

    main_tmp=$(mktemp "$CACHE/main.XXXXXX")
    posts_tmp=$(mktemp "$CACHE/posts.XXXXXX")
    index_tmp=$(mktemp "$CACHE/index.XXXXXX")
    trap 'rm -f "$main_tmp" "$posts_tmp" "$index_tmp"' EXIT

    printf '%s\n' "$HEADER" > "$main_tmp"
    append_cached_fragments "$main_tmp" published document
    if [[ "$SHOW_DRAFTS" == "true" ]]; then
        append_cached_fragments "$main_tmp" drafts document
    fi

    printf '%s\n#let posts = (\n' "$HEADER" > "$posts_tmp"
    append_cached_fragments "$posts_tmp" published post
    if [[ "$SHOW_DRAFTS" == "true" ]]; then
        append_cached_fragments "$posts_tmp" drafts post
    fi
    echo ")" >> "$posts_tmp"

    printf '%s\n' \
        "$HEADER" \
        '    #import("_template.typ"): index_list' \
        '    #import("_posts.typ"): posts' \
        '    #import("../_template.typ"): conf' \
        '    #show: conf' \
        '    = /blog' \
        '    #index_list(posts)' \
        > "$index_tmp"

    mv "$main_tmp" "$MAIN"
    mv "$posts_tmp" "$POSTS"
    mv "$index_tmp" "$IDX"
    touch "$CACHE/.complete"
    trap - EXIT
