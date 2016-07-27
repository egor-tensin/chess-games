#!/usr/bin/env bash

# Copyright 2016 Egor Tensin <Egor.Tensin@gmail.com>
# This file is licensed under the terms of the MIT License.
# See LICENSE.txt for details.

# Utility functions and aliases for "prettifying" PGN files (mostly those
# downloaded from Chess.com).

# You can use the functions and aliases from this file by "sourcing" it in
# `bash` (other shells might work as well):
#
#     > source setenv.sh
#
# `bash` 4.3.42, distributed by the Cygwin project, has been verified to work
# properly.
# The dependencies, along with their respective versions that were verified to
# work properly (also provided by the Cygwin project), are
#
# * `coreutils` 8.25,
# * `sed` 4.2.2.
#
# Any Cygwin installation must already have the corresponding packages
# installed.

# I consider a PGN file to be "pretty" if it
#
# 1. has Windows-style newlines (\r\n),
# 2. places the main line moves on separates lines,
# 3. doesn't have [%clk] tags after the moves, as those are redundant for
# storage and analysis (at least that's my opinion currently).
#
# The list above is highly subjective of course.

# A word of warning: be very careful when trying to apply the routines from
# this file to your PGNs, as the result might be disastrous if a PGN is
# formatted in an unexpected way.
# You definitely should backup the files prior to trying to "prettify" them.
#
# Those precautions aside, if you do want to format PGNs downloaded from
# Chess.com in a manner I described above, call the `normalize_pgn` function
# by passing the paths to the PGN files you want to "prettify".
# For example,
#
#     > normalize_pgns Kasparov_vs_Karpov.pgn MyCrushingWin.pgn
#
# You can also compress a bunch of PGNs into a single PGN file:
#
#     > join_pgns Kasparov_vs_Karpov.pgn MyCrushingWin.pgn > MemorableGames.pgn
#
# Or you might want to add a game from a PGN file to a database of games:
#
#     > append_pgn MemorableGames.pgn MyCrushingDefeat.pgn

# "Lints" PGN files.
# Each PGN
#
# * has its Unix-style newlines (\n) replaced by Windows-style newlines (\r\n),
# * gets whitespace characters trimmed from the end of each line,
# * gets trailing newlines trimmed from the end of the file,
# * gets a single newline (\r\n) appended at the end of the file.
lint_pgn() {

    sed --binary --in-place 's/\r\?$/\r/' "$@" \
        && sed --binary --in-place 's/[[:blank:]]*\(\r\?\)$/\1/' "$@" \
        && sed --binary --in-place -e :a -e '/^\(\r\n\)*\r$/{$d;N;ba}' "$@" \
        && sed --binary --in-place '$s/\r\?$/\r/;a\' "$@"
}

# Strips [%clk] tags from PGN files.
alias strip_pgn_clk='sed --binary --in-place '"'"'s/ {\[%clk [[:digit:]]\+:[[:digit:]]\+\(:[[:digit:]]\+\)*\]}//g'"'"

# Places main line moves at separate lines.
alias slice_pgn_moves='sed --binary --in-place '"'"'s/ \([[:digit:]]\+\.\)/\r\n\1/g'"'"

# "Prettifies" PGN files by (see above)
#
# * "linting" them,
# * stripping [%clk] tags,
# * placing main line moves at separate lines.
normalize_pgn() {
    lint_pgn "$@" \
        && strip_pgn_clk "$@" \
        && slice_pgn_moves "$@"
}

append_pgn() {
    if [ "$#" -ne 2 ]; then
        echo "usage: $FUNCNAME DEST_PGN SRC_PGN" >&2
        return 1
    fi

    printf '\r\n' >> "$1" \
        && cat "$2" >> "$1"
}

join_pgns() (
    if [ "$#" -eq 0 ]; then
        echo "usage: $FUNCNAME [PGN_FILE]"
        return 0
    fi

    set -o errexit

    cat "$1"

    local i
    for i in "${@:2}"; do
        printf '\r\n'
        cat "$i"
    done
)
