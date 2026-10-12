#!/bin/zsh
# Renders every icon PNG from scripts/icon.swift.
set -euo pipefail
cd "${0:A:h}/.."

bin=$(mktemp -d)/icon
swiftc -O scripts/icon.swift -o "$bin"

appicon=PlayingTab/Assets.xcassets/AppIcon.appiconset
for size in 16 32 128 256 512; do
  "$bin" $size $appicon/icon_${size}x${size}.png
  "$bin" $((size * 2)) $appicon/icon_${size}x${size}@2x.png
done

"$bin" 384 PlayingTab/Resources/Icon.png

mkdir -p "PlayingTab Extension/Resources/images"
for size in 48 64 96 128 256 512; do
  "$bin" $size "PlayingTab Extension/Resources/images/icon-$size.png"
done
