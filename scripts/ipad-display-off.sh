#!/usr/bin/env bash
# ==============================================================================
# ipad-display-off.sh - Desactiva la segunda pantalla virtual
# ==============================================================================
set -e

DRM_CONNECTOR="${DRM_CONNECTOR:-card1-HDMI-A-1}"
STATUS_PATH="/sys/class/drm/${DRM_CONNECTOR}/status"

if [ ! -f "$STATUS_PATH" ]; then
    AUTO_PATH=$(ls /sys/class/drm/card*-HDMI-A-*/status 2>/dev/null | head -n 1 || true)
    if [ -n "$AUTO_PATH" ]; then
        STATUS_PATH="$AUTO_PATH"
    fi
fi

echo "==> Desactivando conector virtual ($STATUS_PATH)..."
if [ -f "$STATUS_PATH" ]; then
    echo off | sudo tee "$STATUS_PATH" > /dev/null
    echo "    Conector apagado correctamente."
else
    echo "    No se encontró conector DRM activo."
fi

echo "==> Segunda pantalla apagada. El escritorio vuelve a pantalla única."
