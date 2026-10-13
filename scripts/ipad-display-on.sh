#!/usr/bin/env bash
# ==============================================================================
# ipad-display-on.sh - Activa la segunda pantalla virtual para iPad (Sunshine)
# ==============================================================================
set -e

CONFIG_ENV="${HOME}/.config/ipad-second-screen/config.env"
if [ -f "$CONFIG_ENV" ]; then
    # shellcheck disable=SC1090
    source "$CONFIG_ENV"
fi

DRM_CONNECTOR="${DRM_CONNECTOR:-card1-HDMI-A-1}"
IPAD_POSITION="${IPAD_POSITION:-6}"
IPAD_ORIENTATION="${IPAD_ORIENTATION:-H}"
STATUS_PATH="/sys/class/drm/${DRM_CONNECTOR}/status"
CONF_FILE="${SUNSHINE_CONFIG_DIR:-$HOME/.config/sunshine}/sunshine.conf"

echo "==> [1/3] Activando salida virtual en el kernel DRM (${DRM_CONNECTOR})..."
if [ ! -f "$STATUS_PATH" ]; then
    AUTO_PATH=$(ls /sys/class/drm/card*-HDMI-A-*/status 2>/dev/null | head -n 1 || true)
    if [ -n "$AUTO_PATH" ]; then
        STATUS_PATH="$AUTO_PATH"
        echo "    Conector detectado automáticamente: $STATUS_PATH"
    else
        echo "Error: No se encontró la interfaz DRM para forzar la pantalla."
        exit 1
    fi
fi

echo on | sudo tee "$STATUS_PATH" > /dev/null
echo "    Conector forzado a estado 'connected'."

# Esperar brevemente a que Wayland (Mutter) registre el nuevo monitor
sleep 0.8

echo "==> [2/3] Verificando configuración de salida en Sunshine..."
if [ -f "$CONF_FILE" ]; then
    if ! grep -q "^output_name" "$CONF_FILE"; then
        echo "    Agregando 'output_name = HDMI-A-1' a sunshine.conf..."
        echo "output_name = HDMI-A-1" >> "$CONF_FILE"
        systemctl --user restart app-dev.lizardbyte.app.Sunshine.service 2>/dev/null || true
    fi
fi

echo "==> [3/3] Aplicando disposición en GNOME Mutter (Posición: $IPAD_POSITION | Orientación: $IPAD_ORIENTATION)..."
python3 -c "
import dbus, sys

POS = int('$IPAD_POSITION')
ORIENT = '$IPAD_ORIENTATION'.upper()
BRIDGE = 25  # Píxeles de solape para esquinas para evitar 'monitors not adjacent'

try:
    bus = dbus.SessionBus()
    obj = bus.get_object('org.gnome.Mutter.DisplayConfig', '/org/gnome/Mutter/DisplayConfig')
    iface = dbus.Interface(obj, 'org.gnome.Mutter.DisplayConfig')
    serial, monitors, logical_monitors, props = iface.GetCurrentState()

    edp_info = None
    hdmi_info = None

    for m in monitors:
        spec, modes, properties = m
        connector = spec[0]
        chosen_mode = None
        for mode in modes:
            if mode[6].get('is-current', False) or mode[6].get('is-preferred', False):
                chosen_mode = mode
                break
        if not chosen_mode and len(modes) > 0:
            chosen_mode = modes[0]

        if 'eDP' in connector:
            edp_info = (connector, chosen_mode[0], chosen_mode[1], chosen_mode[2])
        elif 'HDMI' in connector:
            hdmi_info = (connector, chosen_mode[0], chosen_mode[1], chosen_mode[2])

    if edp_info and hdmi_info:
        edp_conn, edp_mode_id, W_m, H_m = edp_info
        hdmi_conn, hdmi_mode_id, W_i, H_i = hdmi_info

        # Determinar rotación en Mutter y dimensiones efectivas
        if ORIENT == 'V':
            W_ir, H_ir = H_i, W_i
            transform = 1  # 90 grados en Mutter
        else:
            W_ir, H_ir = W_i, H_i
            transform = 0  # Normal / Horizontal

        # Matriz 3x3:
        # [8] [1] [2]
        # [7] [0] [3]
        # [6] [5] [4]
        if POS == 1:    # Arriba
            main_coords = (max(0, (W_ir - W_m) // 2), H_ir)
            ipad_coords = (max(0, (W_m - W_ir) // 2), 0)
        elif POS == 2:  # Esquina Superior Derecha
            main_coords = (0, H_ir - BRIDGE)
            ipad_coords = (W_m, 0)
        elif POS == 3:  # Derecha
            main_coords = (0, max(0, (H_ir - H_m) // 2))
            ipad_coords = (W_m, max(0, (H_m - H_ir) // 2))
        elif POS == 4:  # Esquina Inferior Derecha
            main_coords = (0, 0)
            ipad_coords = (W_m, H_m - BRIDGE)
        elif POS == 5:  # Abajo
            main_coords = (max(0, (W_ir - W_m) // 2), 0)
            ipad_coords = (max(0, (W_m - W_ir) // 2), H_m)
        elif POS == 6:  # Esquina Inferior Izquierda (Por defecto)
            main_coords = (W_ir, 0)
            ipad_coords = (0, H_m - BRIDGE)
        elif POS == 7:  # Izquierda
            main_coords = (W_ir, max(0, (H_ir - H_m) // 2))
            ipad_coords = (0, max(0, (H_m - H_ir) // 2))
        elif POS == 8:  # Esquina Superior Izquierda
            main_coords = (W_ir, H_ir - BRIDGE)
            ipad_coords = (0, 0)
        else:
            main_coords = (W_ir, 0)
            ipad_coords = (0, H_m - BRIDGE)

        logical = [
            dbus.Struct((dbus.Int32(main_coords[0]), dbus.Int32(main_coords[1]), dbus.Double(1.0), dbus.UInt32(0), dbus.Boolean(True),
                         dbus.Array([(edp_conn, edp_mode_id, dbus.Dictionary({}, signature='sv'))], signature='(ssa{sv})')), signature='(iiduba(ssa{sv}))'),
            dbus.Struct((dbus.Int32(ipad_coords[0]), dbus.Int32(ipad_coords[1]), dbus.Double(1.0), dbus.UInt32(transform), dbus.Boolean(False),
                         dbus.Array([(hdmi_conn, hdmi_mode_id, dbus.Dictionary({}, signature='sv'))], signature='(ssa{sv})')), signature='(iiduba(ssa{sv}))')
        ]
        iface.ApplyMonitorsConfig(serial, dbus.UInt32(2), logical, dbus.Dictionary({}, signature='sv'))
        orient_txt = 'Vertical (90°)' if ORIENT == 'V' else 'Horizontal'
        print(f'    Disposición aplicada ({orient_txt}, Posición {POS}):')
        print(f'      - Monitor Principal ({W_m}x{H_m}) en {main_coords}')
        print(f'      - iPad ({W_ir}x{H_ir}) en {ipad_coords}')
    else:
        print('    Aviso: No se detectaron ambos monitores en Mutter aún. Se mantendrá la configuración automática.')
except Exception as e:
    print(f'    Aviso Mutter: {e}')
" 2>/dev/null || true

echo "==> ¡Listo! Segunda pantalla virtual activada."
