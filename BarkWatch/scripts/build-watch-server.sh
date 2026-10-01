#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)
build_dir="$repo_root/build/watch-server"
source_dir="$build_dir/source"
revision=5ea5486d8e4fe2fff0b4b170a89b2457e808c9c3

if [ ! -d "$source_dir/.git" ]; then
    mkdir -p "$source_dir"
    git -C "$source_dir" init -q
fi
if ! git -C "$source_dir" rev-parse --verify HEAD >/dev/null 2>&1; then
    git -C "$source_dir" fetch --depth 1 https://github.com/Finb/bark-server.git "$revision"
    git -C "$source_dir" checkout --detach FETCH_HEAD
fi
test "$(git -C "$source_dir" rev-parse HEAD)" = "$revision"

if git -C "$source_dir" apply --check "$script_dir/watch-server.patch" 2>/dev/null; then
    git -C "$source_dir" apply "$script_dir/watch-server.patch"
else
    git -C "$source_dir" apply --reverse --check "$script_dir/watch-server.patch"
fi

cd "$source_dir"
go build -trimpath -o "$build_dir/bark-server" .
printf 'Built %s\n' "$build_dir/bark-server"
