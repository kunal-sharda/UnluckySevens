#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/unlucky-sevens-icons.XXXXXX")"
trap 'rm -rf "$temp_dir"' EXIT

square_source="$repo_root/scripts/assets/unlucky-sevens-icon.svg"
wide_source="$repo_root/scripts/assets/unlucky-sevens-imessage-icon.svg"
app_dir="$repo_root/App/Resources/Assets.xcassets/AppIcon.appiconset"
message_dir="$repo_root/MessagesExtension/Resources/Assets.xcassets/iMessage App Icon.stickersiconset"

qlmanage -t -s 1024 -o "$temp_dir" "$square_source" >/dev/null
qlmanage -t -s 1024 -o "$temp_dir" "$wide_source" >/dev/null

square_thumbnail="$temp_dir/$(basename "$square_source").png"
square_render="$temp_dir/unlucky-sevens-icon-opaque.png"
wide_thumbnail="$temp_dir/$(basename "$wide_source").png"
wide_cropped="$temp_dir/unlucky-sevens-imessage-icon-cropped.png"
wide_render="$temp_dir/unlucky-sevens-imessage-icon-opaque.png"
swift "$repo_root/scripts/make-icon-png-opaque.swift" "$square_thumbnail" "$square_render"
sips --cropToHeightWidth 768 1024 "$wide_thumbnail" --out "$wide_cropped" >/dev/null
swift "$repo_root/scripts/make-icon-png-opaque.swift" "$wide_cropped" "$wide_render"

resize() {
  local source="$1"
  local width="$2"
  local height="$3"
  local output="$4"
  sips -z "$height" "$width" "$source" --out "$output" >/dev/null
}

resize "$square_render" 20 20 "$app_dir/AppIcon-20.png"
resize "$square_render" 40 40 "$app_dir/AppIcon-20@2x.png"
resize "$square_render" 60 60 "$app_dir/AppIcon-20@3x.png"
resize "$square_render" 29 29 "$app_dir/AppIcon-29.png"
resize "$square_render" 58 58 "$app_dir/AppIcon-29@2x.png"
resize "$square_render" 87 87 "$app_dir/AppIcon-29@3x.png"
resize "$square_render" 40 40 "$app_dir/AppIcon-40.png"
resize "$square_render" 80 80 "$app_dir/AppIcon-40@2x.png"
resize "$square_render" 120 120 "$app_dir/AppIcon-40@3x.png"
resize "$square_render" 120 120 "$app_dir/AppIcon-60@2x.png"
resize "$square_render" 180 180 "$app_dir/AppIcon-60@3x.png"
resize "$square_render" 76 76 "$app_dir/AppIcon-76.png"
resize "$square_render" 152 152 "$app_dir/AppIcon-76@2x.png"
resize "$square_render" 167 167 "$app_dir/AppIcon-83.5@2x.png"
resize "$square_render" 1024 1024 "$app_dir/AppIcon-1024.png"

resize "$square_render" 58 58 "$message_dir/iMessageIcon-29@2x.png"
resize "$square_render" 87 87 "$message_dir/iMessageIcon-29@3x.png"
resize "$square_render" 58 58 "$message_dir/iMessageIcon-iPad-29@2x.png"
resize "$wide_render" 120 90 "$message_dir/iMessageIcon-60x45@2x.png"
resize "$wide_render" 180 135 "$message_dir/iMessageIcon-60x45@3x.png"
resize "$wide_render" 134 100 "$message_dir/iMessageIcon-67x50@2x.png"
resize "$wide_render" 148 110 "$message_dir/iMessageIcon-74x55@2x.png"
resize "$wide_render" 54 40 "$message_dir/iMessageIcon-27x20@2x.png"
resize "$wide_render" 81 60 "$message_dir/iMessageIcon-27x20@3x.png"
resize "$wide_render" 64 48 "$message_dir/iMessageIcon-32x24@2x.png"
resize "$wide_render" 96 72 "$message_dir/iMessageIcon-32x24@3x.png"
resize "$wide_render" 1024 768 "$message_dir/iMessageIcon-1024x768.png"

echo "Generated app and iMessage icon assets."
