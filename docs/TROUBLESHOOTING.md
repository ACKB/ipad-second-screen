# Guía de Resolución de Problemas (Troubleshooting)

Esta guía documenta los problemas técnicos reales y sus soluciones verificadas durante el desarrollo de este proyecto.

---

## 1. El iPad muestra la pantalla en Modo Espejo (Clon) en vez de Pantalla Extendida

### Causa 1: Falta de `output_name` en Sunshine
En Linux, cuando Sunshine inicia sin la directiva `output_name`, su comportamiento por defecto es capturar el monitor 0 (`eDP-1`, la pantalla principal de tu laptop).
- **Solución**: Asegúrate de que `~/.config/sunshine/sunshine.conf` contenga:
  ```ini
  output_name = HDMI-A-1
  ```
  Reinicia el servicio con:
  ```bash
  systemctl --user restart app-dev.lizardbyte.app.Sunshine.service
  ```

### Causa 2: Scripts de sistema borrando la configuración (`ExecStopPost`)
Si notas que cada vez que reinicias el PC o Sunshine, la línea `output_name` desaparece mágicamente de `sunshine.conf`, revisa si tienes drop-ins de systemd activos:
```bash
cat ~/.config/systemd/user/app-dev.lizardbyte.app.Sunshine.service.d/*.conf
```
En algunos entornos (como migraciones previas de KDE Plasma con scripts de `sunshine-stop-vmon.sh`), existe una instrucción `sed -i '/^output_name/d'` que borra activamente el monitor secundario cada vez que el servicio se detiene.
- **Solución**: Desactiva el `ExecStopPost` en ese archivo override o comenta la línea `sed` dentro del script.

---

## 2. Error de GNOME Mutter: "Logical monitors not adjacent"

Al intentar colocar el monitor virtual tocando exactamente la esquina de la pantalla principal en coordenadas diagonales puras (ej. `(0, 1200)` y `(1024, 0)`), Mutter rechaza la configuración con:
```text
org.freedesktop.DBus.Error.InvalidArgs: Logical monitors not adjacent
```
- **Por qué ocurre**: Mutter exige que los monitores compartan al menos un borde con una longitud mayor a 0 píxeles para permitir que el cursor del ratón cruce de una pantalla a otra.
- **Solución**: Ajusta la coordenada vertical del monitor secundario para dejar un solape (un "puente" de píxeles). Por ejemplo, situar el iPad en `(0, 1175)` crea un puente vertical de 25 píxeles justo en la esquina inferior izquierda.

---

## 3. ¿Por qué no funciona el tunneling simple por cable USB (`usbmuxd` / `iproxy`)?

- `usbmuxd` y las herramientas como `iproxy` están diseñadas exclusivamente para multiplexar conexiones **TCP** (utilizadas por iTunes, SSH o depuración).
- El protocolo de streaming de NVIDIA / Sunshine / Moonlight requiere paquetes **UDP** (puertos 47998 a 48000) para transmitir vídeo y audio a 60 FPS sin retraso.
- **La única forma de streaming 100% por cable en iOS**:
  Activar **Compartir Internet por USB (Personal Hotspot)** en iOS. Esto hace que el kernel cargue el módulo `ipheth` y cree una interfaz de red Ethernet completa por cable, permitiendo tráfico TCP y UDP sin latencia.
  *(Nota: Requiere una tarjeta SIM insertada en el iPad para desbloquear el menú en iOS).*

---

## 4. Rendimiento y optimización de códec (iPads Clásicos vs Modernos)

1. **Para iPads clásicos (iPad 1, iPad 2, iPad mini 1 / Apple A5)**:
   - En la app Moonlight, **fuerza el códec a H.264** (los chips antiguos no poseen decodificador por hardware para HEVC/H.265 ni AV1).
   - Ajusta el bitrate a **5 - 8 Mbps**. Un bitrate superior a 15 Mbps sobrecarga el bus del procesador antiguo.
   - Fija la resolución en **1024x768 a 60 FPS**.
2. **Para iPads modernos (iPad Retina, Air, Pro con chips A9, A12, M1, M2...)**:
   - Puedes activar **HEVC (H.265)** para menor uso de ancho de banda y mayor compresión.
   - Puedes subir el bitrate a **15 - 30 Mbps** para máxima nitidez en texto fino.
   - Selecciona la resolución correspondiente en `./configurar.sh` para aprovechar al 100% la pantalla Retina.

---

## 5. Cierre inesperado al iniciar Sunshine (`signal=SEGV` / Core Dump en Laptops con GPU Dual Intel + NVIDIA)

### Síntomas en el log de Sunshine:
```text
Info: Screencasting with KMS
Info: Mapped 'HDMI-A-1' to kmsgrab monitor index 0
Error: Couldn't find monitor [0]
Info: Encoder [nvenc] failed
Info: Trying encoder [vulkan]
Info: Creating encoder [h264_vulkan]
...
systemd: app-dev.lizardbyte.app.Sunshine.service: Main process exited, code=dumped, status=11/SEGV
systemd: Failed with result 'core-dump' / 'start-limit-hit'.
```

### Causa Raíz:
En portátiles con gráficos híbridos (Intel Iris Xe/Arc como `card0` y NVIDIA GeForce como `card1`):
1. La pantalla principal (`eDP-2`) está físicamente conectada a la GPU Intel (`card0`), mientras que el conector virtual `HDMI-A-1` pertenece a la GPU NVIDIA (`card1`).
2. Al iniciar Sunshine cuando el iPad está apagado (`HDMI-A-1` desconectado), la GPU NVIDIA no tiene ninguna pantalla activa local. El autotest de KMS para NVENC no encuentra monitores en la tarjeta NVIDIA (`Couldn't find monitor [0]`) y reporta fallo temporal.
3. Sunshine intenta como alternativa el codificador Vulkan (`h264_vulkan`) usando el controlador de Intel (`libvulkan_intel.so` de Mesa).
4. La implementación de Vulkan Video Encode en el controlador Mesa Intel contiene un fallo conocido que genera un fallo de segmentación (`signal: 11 SEGV`) y cierra el proceso.

### Solución:
Forzar a Sunshine a utilizar exclusivamente el codificador por hardware de NVIDIA (`nvenc`), evitando que caiga en el codificador experimental de Intel:
1. Edita `~/.config/sunshine/sunshine.conf` y añade:
   ```ini
   encoder = nvenc
   ```
2. Reinicia el servicio:
   ```bash
   systemctl --user reset-failed app-dev.lizardbyte.app.Sunshine.service
   systemctl --user restart app-dev.lizardbyte.app.Sunshine.service
   ```
3. Verifica que el estado sea `active (running)`.

