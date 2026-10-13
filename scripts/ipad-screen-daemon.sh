#!/usr/bin/env bash
# ==============================================================================
# ipad-screen-daemon.sh - Demonio automático para monitorizar sesiones de Sunshine
# ==============================================================================
# Detecta en tiempo real cuándo Moonlight se conecta o desconecta en Sunshine,
# activando la segunda pantalla al iniciar y apagándola al salir para que
# el puntero del ratón nunca quede atrapado en una pantalla invisible.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ON_SCRIPT="${SCRIPT_DIR}/ipad-display-on.sh"
OFF_SCRIPT="${SCRIPT_DIR}/ipad-display-off.sh"
LOG_FILE="${HOME}/.config/sunshine/sunshine.log"

echo "[ipad-daemon] Iniciando demonio de pantalla virtual para iPad..."

if [ ! -f "$LOG_FILE" ]; then
    echo "[ipad-daemon] Esperando a que Sunshine genere el archivo de log..."
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
fi

# Al cerrar el demonio (SIGINT / SIGTERM), asegurarse de apagar la pantalla virtual
cleanup() {
    echo "[ipad-daemon] Cerrando demonio. Desactivando pantalla virtual..."
    "$OFF_SCRIPT" 2>/dev/null || true
    exit 0
}
trap cleanup SIGINT SIGTERM

echo "[ipad-daemon] Escuchando eventos de conexión en $LOG_FILE..."

tail -F -n 0 "$LOG_FILE" 2>/dev/null | while read -r line; do
    if [[ "$line" =~ "CLIENT CONNECTED" ]]; then
        echo "[ipad-daemon] Conexión de Moonlight detectada. Levantando segunda pantalla..."
        "$ON_SCRIPT"
    elif [[ "$line" =~ "CLIENT DISCONNECTED" ]]; then
        echo "[ipad-daemon] Desconexión de Moonlight detectada. Apagando segunda pantalla..."
        "$OFF_SCRIPT"
    fi
done
