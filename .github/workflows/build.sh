#!/usr/bin/env bash
set -Eeuo pipefail

# Usage: build.sh <book-lang> <dest-dir>
#
# Build the course as of the date specified specified in the
# POT-Creation-Date header of po/$book_lang.po. The output can be
# found in $dest_dir.
#
# The src/ and third_party/ directories are left in a dirty state so
# you can run `mdbook test` and other commands afterwards.

book_lang=${1:?"Usage: $0 <book-lang> <dest-dir>"}
dest_dir=${2:?"Usage: $0 <book-lang> <dest-dir>"}

if [ "$book_lang" = "zh-CN" ]; then
    echo "::group::Building Chinese version"
else
    pot_creation_date=$(grep --max-count 1 '^"POT-Creation-Date:' "po/$book_lang.po" | sed -E 's/".*: (.*)\\n"/\1/')
    pot_creation_date=${pot_creation_date:-now}
    echo "::group::Building $book_lang translation as of $pot_creation_date"

    # Back-date the sources to POT-Creation-Date. The content lives in two
    # directories:
    rm -r src/
    git restore --source "$(git rev-list -n 1 --before "$pot_creation_date" @)" src/
    # Set language and adjust site URL. Clear the redirects since they are
    # in sync with the source files, not the translation.
    export MDBOOK_BOOK__LANGUAGE=$book_lang
    export MDBOOK_OUTPUT__HTML__SITE_URL=/phira-doc/$book_lang/
    export MDBOOK_OUTPUT__HTML__REDIRECT='{}'

    # Include language-specific Pandoc configuration
    # if [ -f ".github/pandoc/$book_lang.yaml" ]; then
    #     export MDBOOK_OUTPUT__PANDOC__PROFILE__PDF__DEFAULTS=".github/pandoc/$book_lang.yaml"
    # fi
fi

mdbook build -d "$dest_dir"
# if [ -f "$dest_dir/pandoc/pdf/phira-doc.pdf" ]; then
#     mv "$dest_dir/pandoc/pdf/phira-doc.pdf" "$dest_dir/html/"
# fi

echo "::endgroup::"
