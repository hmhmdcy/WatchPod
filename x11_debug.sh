#!/bin/bash
# WatchPod X11 Debug Helper
# Virtual display: :42 (466x466)

export DISPLAY=:42
export FLUTTER_ROOT="$HOME/.flutter-sdk/flutter"
export PATH="$FLUTTER_ROOT/bin:$PATH"

XVFB_PID=$(pgrep -f "Xvfb :42" 2>/dev/null | head -1)

if [ -z "$XVFB_PID" ]; then
    echo "Starting Xvfb on :42..."
    rm -f /tmp/.X*-lock /tmp/.X11-unix/X42 2>/dev/null
    Xvfb :42 -screen 0 466x466x24 -nolisten tcp &
    sleep 2
fi

echo "=== X11 Debug Environment Ready ==="
echo "Display: $DISPLAY"
echo "Xvfb PID: $(pgrep -f 'Xvfb :42' 2>/dev/null | head -1)"
echo ""
echo "Usage:"
echo "  Run app:     ./build/linux/x64/debug/bundle/watchpod --disable-gpu"
echo "  Screenshot:   xwd -root -out /tmp/screenshot.xwd && convert /tmp/screenshot.xwd /tmp/screenshot.png"
echo "  List wins:    xwininfo -root -tree"
