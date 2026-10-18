#!/usr/bin/env bash
# ==============================================================================
# install.sh - Instalador Interactivo de iPad Second Screen para Linux (Wayland)
# ==============================================================================
set -e

# Colores de terminal
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_RED="\033[31m"
C_CYAN="\033[36m"
C_BLUE="\033[34m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"
APP_CONFIG_DIR="${HOME}/.config/ipad-second-screen"

# Cargar configuración previa si ya existe para ofrecerla por defecto
DEFAULT_POS=4
DEFAULT_ORIENT="H"
if [ -f "${APP_CONFIG_DIR}/config.env" ]; then
    # shellcheck disable=SC1090
    source "${APP_CONFIG_DIR}/config.env" 2>/dev/null || true
    DEFAULT_POS="${IPAD_POSITION:-4}"
    DEFAULT_ORIENT="${IPAD_ORIENTATION:-H}"
fi

clear 2>/dev/null || true
echo -e "${C_CYAN}${C_BOLD}"
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║          iPad como Segundo Monitor en Linux (Wayland)                ║"
echo "║                 Instalador y Asistente de Configuración              ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo -e "${C_RESET}"

# ------------------------------------------------------------------------------
# 1. VERIFICACIÓN DE SUNSHINE (NO DESTRUCTIVA)
# ------------------------------------------------------------------------------
echo -e "${C_BOLD}==> [1/5] Comprobando si Sunshine está instalado...${C_RESET}"

SUNSHINE_BIN=""
SUNSHINE_CONFIG_DIR="${HOME}/.config/sunshine"

if command -v sunshine &>/dev/null; then
    SUNSHINE_BIN="$(command -v sunshine)"
    echo -e "    ${C_GREEN}✓ Sunshine detectado en el sistema:${C_RESET} ${SUNSHINE_BIN}"
elif flatpak list --app 2>/dev/null | grep -q "dev.lizardbyte.app.Sunshine"; then
    SUNSHINE_BIN="flatpak run dev.lizardbyte.app.Sunshine"
    SUNSHINE_CONFIG_DIR="${HOME}/.var/app/dev.lizardbyte.app.Sunshine/config/sunshine"
    echo -e "    ${C_GREEN}✓ Sunshine detectado en Flatpak.${C_RESET}"
fi

if [ -z "$SUNSHINE_BIN" ]; then
    echo -e "${C_YELLOW}${C_BOLD}    ⚠️ AVISO: No se encontró Sunshine instalado en este equipo.${C_RESET}"
    echo ""
    echo -e "    Para utilizar tu iPad como segundo monitor necesitas instalar ${C_BOLD}Sunshine${C_RESET}."
    echo -e "    Por favor, consulta la guía oficial de instalación para tu distribución:"
    echo -e "    ${C_CYAN}🔗 https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/installation.html${C_RESET}"
    echo ""
    echo -e "    Comandos rápidos según tu distribución:"
    echo -e "      • ${C_BOLD}Arch / CachyOS / Manjaro:${C_RESET}   paru -S sunshine  (o yay -S sunshine)"
    echo -e "      • ${C_BOLD}Debian / Ubuntu / Pop!_OS:${C_RESET}  Descarga el archivo .deb desde GitHub Releases"
    echo -e "      • ${C_BOLD}Fedora:${C_RESET}                     sudo dnf copr enable lizardbyte/beta && sudo dnf install sunshine"
    echo -e "      • ${C_BOLD}Flatpak (Cualquier distro):${C_RESET} flatpak install flathub dev.lizardbyte.app.Sunshine"
    echo ""
    read -rp "¿Deseas continuar la configuración de los scripts de todos modos? (s/N): " CONTINUE_CHOICE
    if [[ ! "$CONTINUE_CHOICE" =~ ^[sSyY]$ ]]; then
        echo -e "\n${C_RED}Instalación cancelada. Instala Sunshine y vuelve a ejecutar este instalador.${C_RESET}\n"
        exit 0
    fi
fi

# ------------------------------------------------------------------------------
# 2. SELECCIÓN DE MODELO DE IPAD Y RESOLUCIÓN
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_BOLD}==> [2/5] ¿Qué modelo de iPad vas a utilizar?${C_RESET}"
echo ""
echo -e "    ${C_YELLOW}[1]${C_RESET} ${C_BOLD}iPad Clásico (iPad 1 / 2 / mini 1)${C_RESET} (1024 x 768 - 4:3) ${C_GREEN}[Ideal para modelos clásicos]${C_RESET}"
echo -e "    ${C_YELLOW}[2]${C_RESET} ${C_BOLD}iPad 3 al 6 / iPad Air 1 y 2 / iPad mini 2 al 5${C_RESET} (2048 x 1536 / Retina 4:3)"
echo -e "    ${C_YELLOW}[3]${C_RESET} ${C_BOLD}iPad 7, 8 y 9 (10.2\")${C_RESET} (2160 x 1620 / 4:3)"
echo -e "    ${C_YELLOW}[4]${C_RESET} ${C_BOLD}iPad 10 / iPad Air (10.9\") / iPad Pro 11\"${C_RESET} (2360 x 1640 ~ 2388 x 1668)"
echo -e "    ${C_YELLOW}[5]${C_RESET} ${C_BOLD}iPad Pro 12.9\" / iPad Air 13\"${C_RESET} (2732 x 2048 / 4:3 grande)"
echo -e "    ${C_YELLOW}[6]${C_RESET} ${C_BOLD}Personalizado${C_RESET} (Introducir resolución manual)"
echo ""

while true; do
    read -rp "Selecciona tu modelo de iPad (1-6) [Por defecto: 1]: " MODEL_CHOICE
    MODEL_CHOICE="${MODEL_CHOICE:-1}"
    if [[ "$MODEL_CHOICE" =~ ^[1-6]$ ]]; then
        break
    else
        echo -e "${C_RED}Opción no válida. Por favor introduce un número del 1 al 6.${C_RESET}"
    fi
done

IPAD_NAME="iPad"
IPAD_WIDTH=1024
IPAD_HEIGHT=768

case "$MODEL_CHOICE" in
    1) IPAD_NAME="iPad Clásico (1/2/mini)"; IPAD_WIDTH=1024; IPAD_HEIGHT=768 ;;
    2) IPAD_NAME="iPad Retina (3-6 / Air)"; IPAD_WIDTH=1024; IPAD_HEIGHT=768 ;; # 1024x768 lógico escalado 2x
    3) IPAD_NAME="iPad 10.2\" (7-9 gen)"; IPAD_WIDTH=1080; IPAD_HEIGHT=810 ;;
    4) IPAD_NAME="iPad Air / Pro 11\""; IPAD_WIDTH=1180; IPAD_HEIGHT=820 ;;
    5) IPAD_NAME="iPad Pro 12.9\""; IPAD_WIDTH=1366; IPAD_HEIGHT=1024 ;;
    6)
        read -rp "Ingresa el ancho en píxeles (ej. 1024): " IPAD_WIDTH
        read -rp "Ingresa el alto en píxeles (ej. 768): " IPAD_HEIGHT
        IPAD_NAME="iPad Personalizado (${IPAD_WIDTH}x${IPAD_HEIGHT})"
        ;;
esac

echo -e "    ${C_GREEN}✓ Dispositivo configurado:${C_RESET} ${IPAD_NAME} (Base: ${IPAD_WIDTH}x${IPAD_HEIGHT})"

# ------------------------------------------------------------------------------
# 3. SELECCIÓN DE ORIENTACIÓN (HORIZONTAL VS VERTICAL)
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_BOLD}==> [3/5] ¿En qué orientación colocarás el iPad?${C_RESET}"
echo ""
echo -e "    ${C_YELLOW}[H]${C_RESET} ${C_BOLD}Horizontal (Landscape)${C_RESET} - Vista habitual apaisada (escritorio extendido tradicional)"
echo -e "    ${C_YELLOW}[V]${C_RESET} ${C_BOLD}Vertical (Portrait)${C_RESET} - Vista vertical (ideal para leer código largo, terminales o chats)"
echo ""

while true; do
    read -rp "Selecciona orientación (H/V) [Por defecto: ${DEFAULT_ORIENT}]: " ORIENT_INPUT
    ORIENT_INPUT="${ORIENT_INPUT:-$DEFAULT_ORIENT}"
    ORIENT_INPUT="$(echo "$ORIENT_INPUT" | tr '[:lower:]' '[:upper:]')"
    if [[ "$ORIENT_INPUT" =~ ^[HV]$ ]]; then
        break
    else
        echo -e "${C_RED}Opción no válida. Introduce 'H' para horizontal o 'V' para vertical.${C_RESET}"
    fi
done

echo -e "    ${C_GREEN}✓ Orientación seleccionada:${C_RESET} $([ "$ORIENT_INPUT" = "V" ] && echo "Vertical (Retrato 90°)" || echo "Horizontal (Apaisado)")"

# ------------------------------------------------------------------------------
# 4. SELECCIÓN DE POSICIÓN RELATIVA (MATRIZ 3x3)
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_BOLD}==> [4/5] Posición física del iPad respecto a tu monitor principal:${C_RESET}"
echo ""
echo -e "                 ${C_YELLOW}[8]${C_RESET}     ${C_YELLOW}[1]${C_RESET}     ${C_YELLOW}[2]${C_RESET}"
echo -e "                 ${C_YELLOW}[7]${C_RESET}     ${C_GREEN}${C_BOLD}[0]${C_RESET}     ${C_YELLOW}[3]${C_RESET}"
echo -e "                 ${C_YELLOW}[6]${C_RESET}     ${C_YELLOW}[5]${C_RESET}     ${C_YELLOW}[4]${C_RESET}"
echo ""
echo -e "       ${C_GREEN}[0]${C_RESET} = Tu monitor principal (Laptop / Pantalla del PC)"
echo -e "       ${C_YELLOW}[1]${C_RESET} = Arriba (Centrado)"
echo -e "       ${C_YELLOW}[2]${C_RESET} = Esquina Superior Derecha"
echo -e "       ${C_YELLOW}[3]${C_RESET} = A la Derecha (Centrado)"
echo -e "       ${C_YELLOW}[4]${C_RESET} = Esquina Inferior Derecha"
echo -e "       ${C_YELLOW}[5]${C_RESET} = Abajo (Centrado)"
echo -e "       ${C_YELLOW}[6]${C_RESET} = Esquina Inferior Izquierda ${C_BLUE}(Ideal junto al teclado de la laptop)${C_RESET}"
echo -e "       ${C_YELLOW}[7]${C_RESET} = A la Izquierda (Centrado)"
echo -e "       ${C_YELLOW}[8]${C_RESET} = Esquina Superior Izquierda"
echo ""

while true; do
    read -rp "Ingresa el número de posición (1-8) [Por defecto: ${DEFAULT_POS}]: " POS_INPUT
    POS_INPUT="${POS_INPUT:-$DEFAULT_POS}"
    if [[ "$POS_INPUT" =~ ^[1-8]$ ]]; then
        break
    else
        echo -e "${C_RED}Opción no válida. Introduce un número del 1 al 8.${C_RESET}"
    fi
done

echo -e "    ${C_GREEN}✓ Posición seleccionada: [${POS_INPUT}]${C_RESET}"

# ------------------------------------------------------------------------------
# 5. INSTALACIÓN Y CONFIGURACIÓN NO DESTRUCTIVA DE SUNSHINE
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_BOLD}==> [5/5] Aplicando configuración sin alterar tus otras aplicaciones...${C_RESET}"

DETECTED_DRM="card1-HDMI-A-1"
AUTO_DRM_PATH=$(ls /sys/class/drm/card*-HDMI-A-*/status 2>/dev/null | head -n 1 || true)
if [ -n "$AUTO_DRM_PATH" ]; then
    DETECTED_DRM="$(basename "$(dirname "$AUTO_DRM_PATH")")"
fi

mkdir -p "$APP_CONFIG_DIR"
cat << EOF > "${APP_CONFIG_DIR}/config.env"
# Configuración generada automáticamente para iPad Second Screen
IPAD_MODEL="${IPAD_NAME}"
IPAD_WIDTH=${IPAD_WIDTH}
IPAD_HEIGHT=${IPAD_HEIGHT}
IPAD_ORIENTATION="${ORIENT_INPUT}"
IPAD_POSITION=${POS_INPUT}
DRM_CONNECTOR="${DETECTED_DRM}"
SUNSHINE_CONFIG_DIR="${SUNSHINE_CONFIG_DIR}"
EOF
echo -e "    ${C_GREEN}✓ Configuración guardada en:${C_RESET} ${APP_CONFIG_DIR}/config.env"

mkdir -p "$BIN_DIR"
cp "${SCRIPT_DIR}/ipad-display-on.sh" "${BIN_DIR}/"
cp "${SCRIPT_DIR}/ipad-display-off.sh" "${BIN_DIR}/"
cp "${SCRIPT_DIR}/ipad-screen-daemon.sh" "${BIN_DIR}/"
chmod +x "${BIN_DIR}/ipad-display-on.sh" "${BIN_DIR}/ipad-display-off.sh" "${BIN_DIR}/ipad-screen-daemon.sh"
echo -e "    ${C_GREEN}✓ Scripts instalados en ${BIN_DIR}.${C_RESET}"

mkdir -p "$SUNSHINE_CONFIG_DIR"
SUNSHINE_CONF="${SUNSHINE_CONFIG_DIR}/sunshine.conf"
SUNSHINE_APPS="${SUNSHINE_CONFIG_DIR}/apps.json"
CONNECTOR_NAME="${DETECTED_DRM#*-}"

# Inyectar output_name y encoder en sunshine.conf SOLO si no existen
if [ -f "$SUNSHINE_CONF" ]; then
    if ! grep -q "^output_name" "$SUNSHINE_CONF"; then
        echo "output_name = ${CONNECTOR_NAME}" >> "$SUNSHINE_CONF"
        echo "    ✓ Añadido 'output_name = ${CONNECTOR_NAME}' a sunshine.conf."
    fi
else
    echo "output_name = ${CONNECTOR_NAME}" > "$SUNSHINE_CONF"
    echo "capture = kms" >> "$SUNSHINE_CONF"
fi

# En portátiles con GPU híbrida (Intel + NVIDIA), forzar 'encoder = nvenc' evita que
# Sunshine caiga al codificador Vulkan de Intel (que causa SEGV / core dump en Mesa).
if command -v nvidia-smi &>/dev/null || lspci | grep -qi nvidia; then
    if ! grep -q "^encoder" "$SUNSHINE_CONF"; then
        echo "encoder = nvenc" >> "$SUNSHINE_CONF"
        echo "    ✓ Configurado 'encoder = nvenc' para compatibilidad con GPU híbrida (NVIDIA)."
    fi
fi

# Fusión NO DESTRUCTIVA en apps.json mediante Python
python3 -c "
import json, os

apps_path = '$SUNSHINE_APPS'
bin_dir = '$BIN_DIR'
conn_name = '$CONNECTOR_NAME'

data = {'env': {'PATH': '\$(PATH):\$(HOME)/.local/bin'}, 'apps': []}
if os.path.exists(apps_path):
    try:
        with open(apps_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print('    Aviso: No se pudo leer apps.json previo, se creará uno nuevo.')

apps = data.setdefault('apps', [])

# Buscar si ya existe una app para iPad para actualizarla sin duplicar
target_idx = None
for i, app in enumerate(apps):
    name = app.get('name', '')
    if 'iPad' in name:
        target_idx = i
        break

ipad_app = {
    'name': 'iPad (Segunda Pantalla)',
    'output_name': conn_name,
    'image-path': 'desktop.png',
    'prep-cmd': [
        {
            'do': f'{bin_dir}/ipad-display-on.sh',
            'undo': f'{bin_dir}/ipad-display-off.sh'
        }
    ]
}

if target_idx is not None:
    apps[target_idx] = ipad_app
    print('    ✓ Perfil \"iPad (Segunda Pantalla)\" actualizado en apps.json.')
else:
    apps.append(ipad_app)
    print('    ✓ Perfil \"iPad (Segunda Pantalla)\" añadido a apps.json (otras apps conservadas).')

with open(apps_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
"

# Instalar servicio systemd de usuario
mkdir -p "$SYSTEMD_USER_DIR"
cp "${SCRIPT_DIR}/../systemd/ipad-screen-daemon.service" "${SYSTEMD_USER_DIR}/"
systemctl --user daemon-reload 2>/dev/null || true

# Reiniciar Sunshine suavemente para cargar la nueva app
if systemctl --user is-active --quiet app-dev.lizardbyte.app.Sunshine.service 2>/dev/null; then
    echo "    Reiniciando Sunshine para aplicar los cambios..."
    systemctl --user restart app-dev.lizardbyte.app.Sunshine.service 2>/dev/null || true
fi

echo ""
echo -e "${C_GREEN}${C_BOLD}╔══════════════════════════════════════════════════════════════════════╗${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}║                    ¡Instalación Completada!                          ║${C_RESET}"
echo -e "${C_GREEN}${C_BOLD}╚══════════════════════════════════════════════════════════════════════╝${C_RESET}"
echo ""
echo -e "  ${C_BOLD}Resumen de tu configuración:${C_RESET}"
echo -e "    • Modelo: ${C_CYAN}${IPAD_NAME}${C_RESET} (${IPAD_WIDTH}x${IPAD_HEIGHT})"
echo -e "    • Orientación: ${C_CYAN}$([ "$ORIENT_INPUT" = "V" ] && echo "Vertical" || echo "Horizontal")${C_RESET}"
echo -e "    • Posición respecto al monitor: ${C_CYAN}Matriz [${POS_INPUT}]${C_RESET}"
echo -e "    • Aplicaciones de Sunshine preservadas: ${C_GREEN}100% intactas${C_RESET}"
echo ""
echo -e "  ${C_BOLD}¿Cómo usarlo?${C_RESET}"
echo -e "  1. Abre ${C_BOLD}Moonlight${C_RESET} en tu iPad."
echo -e "  2. Toca la app ${C_CYAN}${C_BOLD}'iPad (Segunda Pantalla)'${C_RESET}."
echo -e "  3. ¡La pantalla virtual se encenderá sola! Al desconectarte, se apagará."
echo ""
