# 📱 iPad como Segundo Monitor Táctil en Linux (Wayland) con Sunshine y Moonlight

> **Guía definitiva y asistente de configuración automatizado**: Convierte **cualquier iPad** (desde el clásico iPad 2 hasta los modelos iPad Pro, Air o mini más recientes) en una segunda pantalla táctil extendida de alto rendimiento para Linux (GNOME Wayland). Incluye **conmutación 100% automática** (la pantalla virtual solo se crea cuando conectas Moonlight y se destruye al cerrar para no perder nunca el ratón).

---

## 🌟 Características Principales

- 📱 **Compatible con Cualquier iPad**: Ya sea un iPad clásico (iPad 1, 2, mini 1), modelos Retina (iPad 3-6, Air), iPad 10.2" o los modelos modernos iPad Pro y Air (11" y 12.9").
- 🔄 **Orientación Horizontal o Vertical**: Elige entre vista apaisada tradicional o vertical rotada 90° (ideal para leer código largo, terminales o chats).
- 🧭 **Selector Matricial 3x3 de Posición**: Coloca tu iPad en cualquiera de las 8 orientaciones alrededor de tu pantalla principal mediante una matriz visual intuitiva.
- ⚡ **Auto-Conmutación Inteligente**: Cero scripts manuales ni ratones perdidos en pantallas invisibles. La pantalla virtual se enciende al iniciar Moonlight y se apaga sola al desconectarte.
- 🛡️ **Configuración No Destructiva**: No sobreescribe tu archivo `apps.json` ni borra tus juegos de Steam, emuladores o perfiles de Sunshine existentes; solo añade el perfil del iPad.
- 🐧 **Linux Nativo (GNOME Wayland)**: Sin necesidad de comprar "dummy plugs" HDMI físicos. Forzado directo en el kernel DRM de salidas de vídeo no conectadas (`card1-HDMI-A-1`).
- 👆 **Control Táctil Completo**: Modo táctil nativo en Moonlight (Touchscreen Mode).

---

## 🚀 Inicio Rápido (1 Solo Paso)

Clona este repositorio y ejecuta el asistente interactivo:

```bash
git clone https://github.com/ACKB/ipad-second-screen.git
cd ipad-second-screen
chmod +x *.sh scripts/*.sh
./configurar.sh
```

*(También puedes ejecutar `./scripts/install.sh` si prefieres la ruta tradicional).*

---

## 🧙‍♂️ ¿Qué hace el asistente `./configurar.sh`?

Al ejecutar `./configurar.sh`, un asistente interactivo en terminal configurará todo en segundos:

### 1. Comprobación Inteligente de Sunshine
Comprueba si tienes [Sunshine](https://github.com/LizardByte/Sunshine) instalado en el sistema o vía Flatpak. Si no lo tienes, te muestra los comandos exactos para tu distribución (Arch/CachyOS, Ubuntu/Debian, Fedora, Flatpak) y el enlace oficial para que lo instales sin complicaciones.

### 2. Selector de Modelo de iPad
Configura automáticamente la resolución y proporción nativa:
```text
  [1] iPad Clásico (iPad 1 / 2 / mini 1) -> 1024 x 768 (4:3 clásico)
  [2] iPad Retina (iPad 3 al 6 / Air 1 y 2 / mini 2 al 5) -> Retina 4:3
  [3] iPad 10.2" (7ma, 8va y 9na generación) -> 2160 x 1620
  [4] iPad Modernos (iPad 10 / iPad Air 10.9" / iPad Pro 11") -> ~1.43:1
  [5] iPad Pro 12.9" / iPad Air 13" -> 2732 x 2048 (4:3 grande)
  [6] Personalizado -> Introducir resolución manual (Ancho x Alto)
```

### 3. Selector de Orientación (Horizontal o Vertical)
- **`[H]` Horizontal (Landscape)**: Vista apaisada estándar de escritorio extendido.
- **`[V]` Vertical (Portrait)**: Rota la pantalla virtual 90° en Wayland (`transform = 1`). Excelente para ver código de arriba a abajo o leer documentación.

### 4. Selector Matricial de Posición 3x3
Te pregunta dónde colocarás físicamente el iPad respecto a tu monitor:

```text
                 [8]     [1]     [2]
                 [7]     [0]     [3]
                 [6]     [5]     [4]

       [0] = Tu monitor principal (Laptop / Pantalla del PC)
       [1] = Arriba (Centrado)
       [2] = Esquina Superior Derecha
       [3] = A la Derecha (Centrado)
       [4] = Esquina Inferior Derecha
       [5] = Abajo (Centrado)
       [6] = Esquina Inferior Izquierda (Junto al teclado de la laptop)
       [7] = A la Izquierda (Centrado)
       [8] = Esquina Superior Izquierda
```

> **Anti-bloqueo de ratón**: Para las posiciones en esquinas `[2]`, `[4]`, `[6]` y `[8]`, el script genera un puente de contacto de 25 píxeles para que GNOME Mutter no arroje el error `Logical monitors not adjacent` y el cursor cruce con suavidad.

### 5. Configuración Automática No Destructiva en Sunshine
- Añade la app **`iPad (Segunda Pantalla)`** a tu `~/.config/sunshine/apps.json` con los ganchos `prep-cmd`:
  - **`do`**: Enciende la pantalla y la alinea en Mutter al conectar.
  - **`undo`**: Apaga la pantalla al salir de Moonlight.
- **Tus otras apps y juegos en Sunshine se mantienen 100% intactos**.

---

## 🛠️ ¿Cómo funciona internamente?

```text
               Al abrir Moonlight en el iPad
                           │
                           ▼
              ┌─────────────────────────┐
              │  Sunshine recibe stream │
              └────────────┬────────────┘
                           │ Ejecuta prep-cmd ("do")
                           ▼
              ┌─────────────────────────┐
              │   ipad-display-on.sh    │
              │  1. echo on > DRM       │
              │  2. Aplica D-Bus Mutter │
              └────────────┬────────────┘
                           │
                           ▼
  [ GNOME Wayland crea HDMI-1 con resolución y rotación elegidas ]
  [ Sunshine captura HDMI-A-1 con KMS Grab y envía el flujo de vídeo ]
                           │
               Al cerrar Moonlight en el iPad
                           │
                           ▼
              ┌─────────────────────────┐
              │  Sunshine ejecuta undo  │
              │   ipad-display-off.sh   │
              │   echo off > DRM        │
              └─────────────────────────┘
                           │
                           ▼
  [ La pantalla virtual se destruye de inmediato. El ratón vuelve al monitor principal ]
```

---

## 📱 Configuración en la App Moonlight (en el iPad)

En tu iPad, abre **Moonlight** y toca el icono de engranaje (**Ajustes**):

1. **Resolución**: Selecciona la resolución recomendada para tu modelo:
   - Para iPad 1, 2 o mini 1: `1024 x 768`.
   - Para iPad Retina / Air / Pro: Selecciona la resolución nativa o una resolución 4:3 para evitar barras negras.
2. **Fotogramas por segundo (FPS)**: `60 FPS`.
3. **Códec de vídeo**:
   - En **iPads antiguos (iPad 1, 2, mini 1 con Apple A5)**: Selecciona obligatoriamente **`H.264`** (aceleración por hardware).
   - En **iPads modernos (Air, Pro, M1/M2/M4)**: Puedes usar **`HEVC (H.265)`** o `H.264`.
4. **Modo de entrada**: Selecciona **`Touchscreen Mode`** para que los toques en pantalla hagan clic directo.
5. Selecciona tu PC y toca en **`iPad (Segunda Pantalla)`**.

---

## 🔌 Conexión: Wi-Fi vs Cable USB

- **Por Wi-Fi (5 GHz)**: Es la forma más rápida y sin cables. Recomendado conectar el PC por Ethernet al router y el iPad a la red de 5 GHz. Puedes dejar el cable USB conectado al PC únicamente para mantener la batería al 100%.
- **Por Cable Físico (0 ms de latencia)**:
  - Las herramientas de reenvío TCP como `usbmuxd` o `iproxy` **no funcionan con Moonlight**, ya que el vídeo y audio viajan en paquetes **UDP**.
  - Si tu iPad cuenta con bandeja SIM, activa **Compartir Internet por USB (Personal Hotspot)** en iOS.
  - Linux cargará el controlador `ipheth` y creará una interfaz Ethernet cableada directa (`eth0`), permitiendo streaming UDP directo por cable sin tocar el Wi-Fi.

---

## 📂 Contenido del Repositorio

```text
ipad-second-screen/
├── configurar.sh                  # Asistente principal de configuración rápida
├── README.md                      # Esta documentación completa
├── LICENSE                        # Licencia MIT
├── .gitignore
├── scripts/
│   ├── configurar.sh              # Script interactivo del asistente
│   ├── install.sh                 # Alias tradicional de instalación
│   ├── ipad-display-on.sh         # Activa DRM, verifica Sunshine y alinea en Mutter
│   ├── ipad-display-off.sh        # Apaga el conector DRM limpiamente
│   └── ipad-screen-daemon.sh      # Demonio alternativo de monitorización
├── systemd/
│   └── ipad-screen-daemon.service # Unidad systemd de usuario para el demonio
├── configs/
│   ├── sunshine.conf.example      # Configuración de captura y salida de Sunshine
│   └── apps.json.example          # Configuración de apps con prep-cmd automatizado
└── docs/
    └── TROUBLESHOOTING.md         # Diagnóstico de fallos (modo espejo, overrides, etc.)
```

---

## 🛠️ Preguntas Frecuentes y Problemas Conocidos

Consulte el documento [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) para resolver:
- Por qué Sunshine a veces caía en "Modo Espejo" (solución a `output_name` y scripts `ExecStopPost`).
- Cómo funciona el cruce de pantalla en Mutter y el ajuste milimétrico del ratón.
- Permisos `sudo` sin contraseña para el subsistema DRM.

---

## 📄 Licencia

Este proyecto está bajo la Licencia **MIT**. Siéntete libre de utilizarlo, modificarlo y compartirlo.
