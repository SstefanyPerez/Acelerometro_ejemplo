# Acelerómetro y Giroscopio en Flutter

App de ejemplo para el video universitario sobre **acelerómetro y giroscopio** con el paquete [`sensors_plus`](https://pub.dev/packages/sensors_plus). Funciona en **Android, iOS y Web** (Chrome/Edge y Safari de iPhone) e incluye una pantalla para probar el permiso **aceptándolo y negándolo**.

**Demo web (HTTPS):** https://sstefanyperez.github.io/Acelerometro_ejemplo/

> Ábrela desde el **celular**: un computador de escritorio normalmente no tiene acelerómetro ni giroscopio.

## Demos incluidas

| Pantalla | Sensor | Qué hace |
|---|---|---|
| Permisos | — | Muestra la plataforma, el estado del permiso y permite solicitarlo. Indica si el acelerómetro y el giroscopio están disponibles. |
| Bolita | Acelerómetro | Una bolita rueda según la inclinación del celular y muestra X, Y, Z en m/s². |
| Muñequito | Acelerómetro de usuario | El muñeco se despeina cuando agitas el celular (magnitud > 10 m/s²). |
| Giroscopio | Giroscopio | Muestra X, Y, Z en rad/s y una figura que gira acumulando la rotación en Z. |
| Detector de caídas | Acelerómetro | Detecta caída libre (< 3 m/s²) seguida de impacto (> 20 m/s²) y pregunta "¿Estás bien?". |

Si el permiso está negado, cada demo muestra una vista de **"Permiso denegado"** con un botón para reintentar. Si en 3 segundos no llega ninguna lectura, muestra **"No se reciben datos del sensor"**.

## Capturas

<!-- Reemplazar por las capturas reales (por ejemplo, en docs/capturas/). -->

| Menú | Permisos | Permiso denegado |
|---|---|---|
| <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/c93ea037-d2d8-4ec9-b618-7d6e6b80ba59" />
 | <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/254d5575-752e-41db-8ad9-798317a86159" />
 | `[captura permiso denegado]` |

| Bolita | Muñequito | Giroscopio | Caídas |
|---|---|---|---|
| <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/97a492a8-a438-473b-8771-26440af86264" />
 | <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/15c7e462-4db1-4d63-8d50-13a1d07fcbfd" />
 | <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/d8b75899-f715-4cfe-b148-38082dce9b68" />
 | <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/8acb63fd-11c8-44b8-8d0c-0cecda8a9bdc" />
 |

## Cómo ejecutar

Requisitos: Flutter 3.44 o superior (Dart 3.12).

```bash
flutter pub get
```

**Android** (celular con depuración USB activada):

```bash
flutter run -d android
```

**iOS** (en macOS con Xcode; el simulador no tiene sensores, usa un iPhone real):

```bash
flutter run -d ios
```

**Web**:

```bash
flutter run -d chrome          # en el computador (sin sensores reales)
flutter build web --release    # para publicar
```

Para probar en un celular hace falta **HTTPS**. Lo más fácil es usar la demo publicada en GitHub Pages (enlace arriba).

## Permisos por plataforma

| Plataforma | ¿Pide permiso al usuario? | Configuración | Cómo lo maneja la app |
|---|---|---|---|
| **Android** | No. Leer acelerómetro y giroscopio no requiere permiso en tiempo de ejecución. | `AndroidManifest.xml`: `uses-feature` de acelerómetro y giroscopio con `required="false"`. `HIGH_SAMPLING_RATE_SENSORS` queda comentado: solo hace falta para leer a más de 200 Hz (Android 12+). | Estado "No requerido". Si el sensor no existe, `sensors_plus` envía el error `NO_SENSOR` y se muestra qué sensor falta. |
| **iOS** | No muestra diálogo para acelerómetro y giroscopio. | `Info.plist`: `NSMotionUsageDescription` es **obligatoria** (sin ella la app se cierra). | Estado "No requerido". |
| **Chrome / Edge** | Sí, como permiso del sitio ("Sensores de movimiento"). Normalmente se concede solo; el usuario puede bloquearlo. | Solo funciona con HTTPS. | Se consulta con `navigator.permissions.query({name: 'accelerometer'})` y `{name: 'gyroscope'}`. Los datos llegan con `sensors_plus` (Generic Sensor API). |
| **Safari (iPhone)** | Sí, con un diálogo que aparece al tocar un botón. | Solo funciona con HTTPS. | Se pide con `DeviceMotionEvent.requestPermission()` dentro del `onPressed`. Los datos se leen del evento `devicemotion`, convertidos a los mismos tipos de `sensors_plus`. |

¿Por qué hay código propio para Web? En Web, `sensors_plus` **no envía un error** si el permiso está bloqueado: emite una lectura `(0, 0, 0)` o no emite nada, y el error solo aparece en la consola. Por eso la app consulta el permiso por su cuenta (`lib/servicios/servicio_permisos.dart`) y usa un temporizador de 3 s para detectar que no llegan datos.

## Cómo probar el permiso negado

**Chrome (Android):**

1. Abre la demo web y toca el candado (o el ícono de ajustes) junto a la dirección.
2. Entra a **Configuración del sitio → Sensores de movimiento → Bloquear**.
3. Recarga la página y abre **Permisos**: el estado aparece como **Denegado** con las instrucciones. Las demos muestran "Permiso denegado".
4. Para reactivarlo: misma ruta → **Permitir**, recarga y toca **Reintentar**.

**Safari (iPhone):**

1. Abre la demo web, entra a **Permisos** y toca **Solicitar permiso**.
2. En el diálogo elige **No permitir**: el estado pasa a **Denegado**.
3. Safari no vuelve a preguntar hasta que recargues la página. Si sigue bloqueado, ve a **Ajustes → Safari → Movimiento y orientación** (en iOS 18: **Ajustes → Apps → Safari**), actívalo y recarga.
4. Para aceptarlo: toca **Solicitar permiso** y elige **Permitir**.

**Android / iOS nativo:** no hay diálogo que negar. La pantalla de Permisos explica por qué y muestra si cada sensor está disponible.

## Estructura de carpetas

```
lib/
├── main.dart                      # Menú principal
├── pantalla_permisos.dart         # Estado del permiso y botón "Solicitar permiso"
├── pantalla_bolita.dart           # Demo con acelerómetro
├── pantalla_muneco.dart           # Demo con acelerómetro de usuario
├── pantalla_giroscopio.dart       # Demo con giroscopio
├── pantalla_caidas.dart           # Detector de caídas
├── servicios/
│   ├── servicio_permisos.dart     # Permisos multiplataforma (import condicional)
│   ├── permisos_nativos.dart      #   Android / iOS: "no requerido"
│   ├── permisos_web.dart          #   Chrome (permissions.query) y Safari (requestPermission)
│   ├── estado_permiso.dart        # Enums EstadoPermiso y Plataforma
│   ├── fuente_sensores.dart       # Fuente única de datos (import condicional)
│   ├── fuente_sensores_nativa.dart#   sensors_plus directo
│   ├── fuente_sensores_web.dart   #   sensors_plus o 'devicemotion' (Safari)
│   ├── interop_web.dart           # Enlaces a las APIs del navegador
│   └── tipo_sensor.dart           # Sensores y mensajes de error
└── widgets/
    ├── control_sensor.dart        # Mixin: revisa permiso + timeout de 3 s
    ├── vista_permiso_denegado.dart# Vista "Permiso denegado" con reintentar
    └── vista_mensaje_sensor.dart  # Vista de carga / sin datos / error
assets/                            # Imágenes del muñequito
.github/workflows/deploy_web.yml   # Publicación en GitHub Pages
```

## Paquetes

| Paquete | Versión | Uso |
|---|---|---|
| `sensors_plus` | ^7.1.0 | Acelerómetro, acelerómetro de usuario y giroscopio |
| `web` | ^1.1.1 | APIs del navegador (permisos y `devicemotion`), solo en Web |

## Publicación web

El workflow `.github/workflows/deploy_web.yml` compila con `flutter build web --release --base-href "/Acelerometro_ejemplo/"` y publica en GitHub Pages en cada push a `main`.

URL: **https://sstefanyperez.github.io/Acelerometro_ejemplo/**

## Integrantes

- María Maestre
- José Suárez
- Stefany Pérez
- Andrea Ocampo
