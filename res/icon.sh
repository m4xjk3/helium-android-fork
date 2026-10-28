#!/bin/sh

# Renders the Helium icon at the exact size of each target PNG.
# Requires ImageMagick (identify) and librsvg (rsvg-convert).

dir=$(dirname "$0")
tpl="$dir/icon.svg"

case $(basename "$1") in
  layered_app_icon_background*) tpl="$dir/icon_bg.svg" ;;
  layered_app_icon*)            tpl="$dir/icon_fg.svg" ;;
esac

w=$(identify -format %w "$1")
rsvg-convert -w "$w" -h "$w" -o "$1" "$tpl"
echo "$1 ($w px, $(basename "$tpl"))"
