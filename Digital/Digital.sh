#!/bin/bash
DIR="$( cd "$( dirname "$( realpath "${BASH_SOURCE[0]}" )" )" >/dev/null && pwd )"

# Niri/Wayland (XWayland): AWT only knows a hardcoded list of reparenting X11
# WMs. Niri is not on it, so AWT mis-maps the content window and the frame
# paints blank grey. Force the non-reparenting code path.
export _JAVA_AWT_WM_NONREPARENTING=1

java -jar "$DIR/Digital.jar" "$@"
