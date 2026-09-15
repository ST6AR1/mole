[English](README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Français](README.fr.md) | Español | [Deutsch](README.de.md) | [Português (Brasil)](README.pt-BR.md)

<p align="center">
  <img src="icon/mole-poses/wordmark-logo.png" width="160" alt="mole logo">
</p>

<p align="center">Olvídate de los comandos, ponte a trabajar.<br>Skip the commands, get to work.</p>

<p align="center">
  <img src="docs/screenshots/app-icon.png" width="120" alt="mole app icon">
</p>

<p align="center">
  <img src="docs/screenshots/main.png" width="480" alt="Ventana principal de mole: suelta una carpeta de proyecto y la detecta y ejecuta automáticamente">
</p>

Una pequeña utilidad para macOS: sueltas una carpeta de proyecto, y mole averigua de qué tipo de proyecto se trata, lo ejecuta en segundo plano y abre tu navegador, sin amontonar ventanas de Terminal. También puedes ver exactamente qué servicios de localhost están corriendo en este momento y detenerlos con un solo clic.

## Por qué hice esto

<p align="center">
  <img src="docs/screenshots/story.png" width="280" alt="Por qué hice esta app">
</p>

No soy desarrollador profesional. Después de mucho vibe coding, terminé con cada vez más proyectos, sin poder recordar los comandos de arranque y perdiendo la cuenta de qué puertos localhost seguían activos.

Y tampoco quería volver a preguntarle a una IA solo para poner en marcha un proyecto otra vez.

Así que hice mole. Sueltas la carpeta y él se encarga del resto.

## Funciones

- **Inicio arrastrando y soltando**: suelta una carpeta sobre la ventana, o usa "Elegir carpeta" — mole detecta el tipo de proyecto y lo inicia automáticamente. Compatible con Node.js (npm / pnpm / yarn / bun), sitios estáticos, Python, Ruby / Rails, Go, Rust, Docker Compose, Deno, PHP, Flutter, Java / Kotlin, .NET, extensiones de Chrome, apps nativas de macOS, y más
- **Se ejecuta completamente en segundo plano**: ya no se amontonan ventanas de Terminal — la salida del comando de inicio se sigue registrando, simplemente no tienes que mirarla
- **Lista de proyectos en ejecución**: cada servicio toma automáticamente el `<title>` o el favicon del sitio, para que puedas distinguir tus proyectos de un vistazo; los íconos de mantener activo (⭐️) y detener (✕) son visibles y se pueden pulsar directamente, sin necesidad de abrir ningún menú
- **Cierre automático**: cierra automáticamente los servicios inactivos después de un tiempo configurable; los proyectos fijados (mantener activo) nunca se tocan
- **Interfaz en 9 idiomas**: English, 繁體中文, 简体中文, 日本語, 한국어, Français, Español, Deutsch y Português (Brasil) — cambia de idioma al instante desde Ajustes, sin reiniciar la app. La lista de idiomas siempre aparece en el mismo orden fijo, con cada idioma escrito en su propio nombre nativo
- **Actualización automática**: revisa si hay una versión más reciente al iniciar, con descarga e instalación en un clic

## Capturas de pantalla

<p align="center">
  <img src="docs/screenshots/main.png" width="480" alt="Ventana principal de mole">
</p>

## Cómo funciona

Suelta una carpeta sobre mole, y él va a:

1. Revisar el contenido de la carpeta (`package.json`, `Gemfile`, `go.mod`, `Dockerfile`, …) para averiguar el tipo de proyecto
2. Construir el comando de inicio correspondiente y ejecutarlo en segundo plano (la salida va a un archivo de registro, sin que aparezca ninguna ventana de Terminal)
3. Sondear si aparece un nuevo puerto de localhost
4. Abrir el navegador automáticamente en cuanto lo detecta — o, si no hay ningún puerto web que detectar (una app nativa, un servicio solo de backend, etc.), marcar el inicio como completado de inmediato

## Instalación

Requiere macOS 12 o superior.

### Opción 1: Descargar la app

1. Descarga el último `mole-x.x.x.dmg` desde [Releases](https://github.com/ST6AR1/mole/releases/latest)
2. Abre el DMG y arrastra la app a `Applications`
3. Como no hay un certificado de Apple Developer de pago, el primer inicio mostrará una advertencia de "desarrollador no identificado" — en Finder, **haz clic en la app manteniendo pulsada la tecla Control → Abrir**, o permítelo en **Ajustes del Sistema → Privacidad y seguridad**. Esto solo ocurre una vez

### Opción 2: Compilar desde el código fuente

```bash
xcode-select --install   # si aún no lo has hecho
git clone https://github.com/ST6AR1/mole.git
cd mole
./build.sh
```

Esto genera `mole.app` en la carpeta del proyecto — arrástralo a `Applications` para usarlo.

## Plataformas compatibles

Solo macOS 12 (Monterey) y versiones posteriores, tanto en Apple Silicon como en Intel.

## Privacidad

mole se ejecuta completamente en tu propio equipo. No recopila ni sube ningún dato de uso ni el contenido de tus proyectos; las únicas llamadas de red que hace son comprobar en GitHub si hay una versión más reciente al iniciar (una llamada de solo lectura a la API de Releases, sin enviar información del dispositivo), y abrir una página de GitHub Issues ya rellenada cuando tú mismo haces clic en "Reportar un problema".

## Preguntas frecuentes

**P: Se queda atascado en "Waiting for localhost", ¿qué hago?**
R: Si es un servicio solo de backend, una base de datos o una app nativa, sencillamente no hay ningún puerto web que encontrar, y se marcará como completado automáticamente después de un rato. Si todavía está corriendo `npm install`, descargando una imagen de Docker, o algún otro paso de configuración, revisa el registro o el Terminal para ver el progreso real en lugar de volver a soltar la carpeta.

**P: Elegí el idioma equivocado y ya no puedo leer la interfaz, ¿qué hago?**
R: En el menú desplegable de idiomas de Ajustes, cada idioma se muestra en su propio nombre nativo (por ejemplo, "Français", "日本語") y siempre aparece en el mismo orden fijo, así que puedes encontrar el que sí puedes leer sin tener que descifrar nada más primero.

**P: ¿Qué tipos de proyecto son compatibles?**
R: Node.js (npm / pnpm / yarn / bun), sitios estáticos, Python, Ruby / Rails, Go, Rust, Docker Compose, Deno, PHP, Flutter, Java / Kotlin, .NET, extensiones de Chrome, apps nativas de macOS, y más — la detección sigue ampliándose con el tiempo.

## Términos de uso

El código fuente de este proyecto es público en GitHub solo para consulta y uso personal; todos los derechos reservados. Ponte en contacto con el autor antes de usarlo para cualquier otro fin.

## Desarrollo

- `App/main.swift`: el código fuente de toda la app (AppKit puro, sin SwiftUI)
- `App/Localization/`: los archivos de traducción de los 9 idiomas (`Strings.*.swift`) y la lógica de cambio de idioma
- `bin/smart-launch.sh`: el script de shell que detecta los tipos de proyecto y construye los comandos de inicio
- `build.sh`: compila y empaqueta la `.app`
- `make-dmg.sh`: empaqueta un `.dmg` distribuible

Para publicar una versión:

```bash
./make-dmg.sh
gh release create vX.Y.Z mole-X.Y.Z.dmg --title "vX.Y.Z" --notes "Qué cambió esta vez"
```

## Credits

Made by Wen and Claude, together ⌯^⦁𖥦⦁^⌯
