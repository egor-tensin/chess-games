#!/usr/bin/env bash

# Copyright (c) 2016 Egor Tensin <Egor.Tensin@gmail.com>
# This file is part of the "Chess games" project.
# For details, see https://github.com/egor-tensin/chess-games.
# Distributed under the MIT License.

# Utility functions and aliases for "prettifying" PGN files (mostly those
# downloaded from Chess.com).

# I consider a PGN file to be "pretty" if it
#
# 1. has Unix-style newlines (\n),
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
#     > pgn_normalize Kasparov_vs_Karpov.pgn MyCrushingWin.pgn
#
# You can also compress a bunch of PGNs into a single PGN file:
#
#     > pgn_join Kasparov_vs_Karpov.pgn MyCrushingWin.pgn > MemorableGames.pgn
#
# Or you might want to add a game from a PGN file to a database of games:
#
#     > pgn_append MemorableGames.pgn MyCrushingDefeat.pgn

alias pgn_dos2eol='sed --binary --in-place -- '"'"'s/\(\r\?\)$//'"'"
alias pgn_eol2dos='sed --binary --in-place -- '"'"'s/\r\?$/\r/'"'"

alias pgn_trim='sed --binary --in-place -- '"'"'s/[[:blank:]]*\(\r\?\)$/\1/'"'"

alias pgn_trimeol='sed --binary --in-place -e :a -e '"'"'/^\n*$/{$d;N;ba}'"'"' --'
alias pgn_trimdoseol='sed --binary --in-place -e :a -e '"'"'/^\(\r\n\)*\r$/{$d;N;ba}'"'"' --'

alias pgn_eol='sed --binary --in-place -- '"'"'$a\'"'"
alias pgn_doseol='sed --binary --in-place -- '"'"'$s/\r\?$/\r/;a\'"'"

# "Lints" PGN files.
# Each PGN
#
# * has Windows-style newlines (\r\n) replaced by Unix-style newlines (\n),
# * gets whitespace characters trimmed from the end of each line,
# * gets trailing newlines trimmed from the end of the file,
# * is ensured to have a newline at the end.
pgn_lint() {
    pgn_dos2eol "$@" \
        && pgn_trim "$@" \
        && pgn_trimeol "$@" \
        && pgn_eol "$@"
}

# Strips [%clk] tags from PGN files.
alias pgn_strip_clk='sed --binary --in-place -- '"'"'s/ {\s*\[%clk [[:digit:]]\+:[[:digit:]]\+\(:[[:digit:]]\+\)*\]\s*}//g'"'"

# Places main line moves on separate lines.
alias pgn_slice_moves='sed --binary --in-place -- '"'"'s/ \([[:digit:]]\+\.\)/\n\1/g'"'"

# "Prettifies" PGN files by (see above)
#
# * "linting" them,
# * stripping [%clk] tags,
# * placing main line moves on separate lines.
pgn_normalize() {
    pgn_lint "$@" \
        && pgn_strip_clk "$@" \
        && pgn_slice_moves "$@"
}

pgn_append() (
    set -o errexit -o nounset -o pipefail

    if [ "$#" -lt 2 ]; then
        echo "usage: ${FUNCNAME[0]} DEST_PGN SRC_PGN..." >&2
        return 1
    fi

    local dest="$1"
    shift

    local src
    for src; do
        echo >> "$dest"
        cat -- "$src" >> "$dest"
    done
)

pgn_join() (
    set -o errexit -o nounset -o pipefail

    if [ "$#" -eq 0 ]; then
        echo "usage: ${FUNCNAME[0]} PGN_FILE..."
        return 0
    fi

    cat -- "$1"
    shift

    local pgn
    for pgn; do
        echo
        cat -- "$pgn"
    done
)
