#!/bin/bash
# Build script for cpufreq UNRAID plugin
# Embeds payload files as plain text (CDATA) into the final .plg file
# Usage: ./build.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/source"
PLUGIN_DIR="$SOURCE_DIR/plugins/cpufreq"
OUTPUT_DIR="$SCRIPT_DIR/archive"
TEMPLATE="$SOURCE_DIR/cpufreq.plg"
OUTPUT="$OUTPUT_DIR/cpufreq.plg"

mkdir -p "$OUTPUT_DIR"
OUTPUT_TMP="$(mktemp "$OUTPUT_DIR/.cpufreq.plg.XXXXXX")"
trap 'rm -f "$OUTPUT_TMP"' EXIT

echo "Building cpufreq plugin..."

# Validate payload files are CDATA-safe.
for f in "$PLUGIN_DIR/cpufreq.php" "$PLUGIN_DIR/cpufreqdash.page"; do
    if grep -q ']]>' "$f"; then
        echo "ERROR: $f contains ']]>' which breaks CDATA embedding!" >&2
        exit 1
    fi
done

# Use awk to replace placeholder lines with file contents.
awk -v php="$PLUGIN_DIR/cpufreq.php" \
    -v dash="$PLUGIN_DIR/cpufreqdash.page" '
function embed(path,   line) {
    while ((getline line < path) > 0) print line
    close(path)
}
/@cpufreq\.php\.content@/       { embed(php);  next }
/@cpufreqdash\.page\.content@/  { embed(dash); next }
{ print }
' "$TEMPLATE" > "$OUTPUT_TMP"

if grep -Eq '@[a-z.]+\.content@' "$OUTPUT_TMP"; then
    echo "ERROR: unreplaced payload placeholder found" >&2
    exit 1
fi

mv -f "$OUTPUT_TMP" "$OUTPUT"
trap - EXIT

echo ""
echo "Build complete: $OUTPUT"
echo "Install: copy to /boot/config/plugins/ on your UNRAID server, then run:"
echo "  plugin install /boot/config/plugins/cpufreq.plg"
