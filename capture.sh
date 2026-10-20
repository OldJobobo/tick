#!/usr/bin/env bash
# Actual offscreen QML captures, synthetic files/settings, no desktop or portal changes.
set -euo pipefail
source=$(realpath "$1")
before_ui=$(realpath "$2")
after_ui=$(realpath "$3")
out=$(realpath -m "$4")
script=$(cd "$(dirname "$0")" && pwd)
cd "$source"
. tools/flea-sandbox-guard
. tests/headless-commons.sh
root="$FIXTURE_ROOT/fv-$$"
sandbox_make "$root"
trap 'sandbox_remove "$root"' EXIT
mkdir -p "$out"
for variant in before after; do
    phase="$root/$variant"
    mkdir -p "$phase"/{config,home/Downloads/{Projects,Reference},state/flea,settings,cache,data,r,bin,tmp}
    chmod 700 "$phase/r"
    for name in brief.pdf budget.csv launch-notes.md readme.txt .draft-notes.txt .env.example; do
        printf 'Synthetic visual fixture.\n' > "$phase/home/Downloads/$name"
    done
    touch -t 202610011000 "$phase/home/Downloads/"*
    touch -t 202610011000 "$phase/home/Downloads/.draft-notes.txt" "$phase/home/Downloads/.env.example"
    printf '{"pickerView":"list","hidden":false,"keys":"default","places":{"favourites":[]},"display":{"textSize":{"mode":14}},"preview":{"thumbnails":"off","thumbSize":"medium","ctrlZoom":true}}\n' > "$phase/state/flea/ui.json"
    ui=$before_ui; [[ "$variant" == after ]] && ui=$after_ui
    ln -s "$ui" "$phase/config/flea"
    headless_commons "$root" "$phase/config/Commons"
    ln -s "$(readlink -f ui/boot/Ui)" "$phase/config/Ui"
    cp "$script/capture.qml" "$phase/config/shell.qml"
    # Hide host-specific device and network discovery, not any chooser UI control.
    printf '#!/bin/sh\nprintf '\''{"blockdevices":[]}\\n'\''\n' > "$phase/bin/lsblk"
    printf '#!/bin/sh\nexit 0\n' > "$phase/bin/gio"
    chmod +x "$phase/bin/lsblk" "$phase/bin/gio"
    request=$(python3 - "$phase/home/Downloads" <<'PY'
import json,sys
print(json.dumps(dict(mode='save',folder=sys.argv[1],name='report.pdf',title='Save a file')))
PY
    )
    set +e
    env -u DISPLAY -u WAYLAND_DISPLAY -u HYPRLAND_INSTANCE_SIGNATURE -u DBUS_SESSION_BUS_ADDRESS \
        HOME="$phase/home" XDG_CONFIG_HOME="$phase/settings" XDG_STATE_HOME="$phase/state" \
        XDG_CACHE_HOME="$phase/cache" XDG_DATA_HOME="$phase/data" XDG_RUNTIME_DIR="$phase/r" TMPDIR="$phase/tmp" \
        PATH="$phase/bin:$PATH" FLEA_BIN="$source/target/debug/flea" FLEA_PICKER="$request" FLEA_PICKER_REPLY="$phase/reply.json" \
        FLEA_VISUAL_VARIANT="$variant" FLEA_CAPTURE_OUT="$out" \
        QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME=generic QT_QUICK_BACKEND=software QT_FORCE_STDERR_LOGGING=1 \
        timeout 35 qs -p "$phase/config" > "$out/$variant.log" 2>&1
    result=$?
    set -e
    grep 'VISUAL ' "$out/$variant.log" || true
    [[ "$result" == 143 ]] && grep -q "VISUAL DONE $variant captures=8 filename=report.pdf answered=false" "$out/$variant.log" \
        || { printf 'FAIL visual capture %s exit=%s\n' "$variant" "$result"; exit 1; }
    if grep -E 'VISUAL FAIL|TypeError|ReferenceError|ERROR|Unable to assign' "$out/$variant.log"; then exit 1; fi
done
