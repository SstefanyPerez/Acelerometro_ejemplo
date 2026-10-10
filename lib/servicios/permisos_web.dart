// Implementación de permisos para Web.
// sensors_plus en Web NO informa cuando el permiso está bloqueado (solo lo
// escribe en la consola), por eso aquí lo gestionamos con código propio.

import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'estado_permiso.dart';
import 'interop_web.dart';

/// Detecta el navegador según las APIs que tiene disponibles.
Plataforma detectarPlataforma() {
  if (tieneGenericSensor) return Plataforma.webChromium;
  if (esSafariConPermiso) return Plataforma.webSafari;
  return Plataforma.webOtro;
}

/// Safari no permite consultar el permiso sin preguntar, así que guardamos
/// la última respuesta del usuario mientras la página siga abierta.
EstadoPermiso? _respuestaSafari;

/// Consulta el permiso SIN mostrar ningún diálogo.
Future<EstadoPermiso> consultarPermiso() async {
  // Los sensores de movimiento solo funcionan en páginas HTTPS (o localhost).
  if (!web.window.isSecureContext) return EstadoPermiso.noSoportado;

  switch (detectarPlataforma()) {
    case Plataforma.webChromium:
      return _consultarChrome();
    case Plataforma.webSafari:
      if (_respuestaSafari != null) return _respuestaSafari!;
      // Si el usuario ya lo aceptó antes, los eventos llegan sin preguntar.
      final llegaronDatos = await _llegaAlgunDeviceMotion(
        const Duration(milliseconds: 600),
      );
      return llegaronDatos ? EstadoPermiso.concedido : EstadoPermiso.pendiente;
    default:
      // Firefox y otros: 'devicemotion' funciona sin permiso.
      return tieneDeviceMotion
          ? EstadoPermiso.noRequerido
          : EstadoPermiso.noSoportado;
  }
}

/// Pide el permiso al usuario.
///
/// IMPORTANTE (Safari): debe llamarse directamente dentro del onPressed de
/// un botón y SIN ningún `await` antes, porque Safari solo muestra el
/// diálogo si la llamada ocurre durante el gesto del usuario.
Future<EstadoPermiso> solicitarPermiso() async {
  if (!web.window.isSecureContext) return EstadoPermiso.noSoportado;

  switch (detectarPlataforma()) {
    case Plataforma.webSafari:
      try {
        // Esta es la primera instrucción: no hay await antes de la llamada.
        final respuesta = await ClaseDeviceMotion.requestPermission().toDart;
        _respuestaSafari = respuesta.toDart == 'granted'
            ? EstadoPermiso.concedido
            : EstadoPermiso.denegado;
      } catch (_) {
        // Se lanza si la llamada no vino de un gesto del usuario.
        return EstadoPermiso.pendiente;
      }
      return _respuestaSafari!;
    case Plataforma.webChromium:
      // Chrome no tiene un "requestPermission": el permiso se resuelve al
      // encender un sensor. Encendemos ambos un momento y luego consultamos.
      await _encenderSensoresChrome();
      return _consultarChrome();
    default:
      return consultarPermiso();
  }
}

/// Consulta el permiso de acelerómetro y giroscopio en Chrome/Edge con
/// `navigator.permissions.query`. Devuelve 'granted', 'denied' o 'prompt'.
Future<EstadoPermiso> _consultarChrome() async {
  try {
    final permisos = web.window.navigator.permissions;
    final acelerometro = await permisos
        .query(DescriptorPermiso(name: 'accelerometer'))
        .toDart;
    final giroscopio = await permisos
        .query(DescriptorPermiso(name: 'gyroscope'))
        .toDart;
    final estados = [acelerometro.state, giroscopio.state];

    if (estados.contains('denied')) return EstadoPermiso.denegado;
    if (estados.every((e) => e == 'granted')) return EstadoPermiso.concedido;
    return EstadoPermiso.pendiente;
  } catch (_) {
    // El navegador no reconoce esos nombres de permiso.
    return EstadoPermiso.pendiente;
  }
}

/// Enciende acelerómetro y giroscopio hasta recibir una lectura o un error
/// (máximo 3 s). Encenderlos es lo que hace que Chrome resuelva el permiso.
Future<void> _encenderSensoresChrome() async {
  final sensores = <web.Sensor>[];
  final esperas = <Future<void>>[];
  try {
    final constructores = <web.Sensor Function()>[
      () => AcelerometroJs(),
      () => web.Gyroscope(),
    ];
    for (final crear in constructores) {
      final sensor = crear();
      final terminado = Completer<void>();
      void terminar(web.Event _) {
        if (!terminado.isCompleted) terminado.complete();
      }

      sensor.onreading = terminar.toJS;
      sensor.onerror = terminar.toJS;
      sensor.start();
      sensores.add(sensor);
      esperas.add(terminado.future);
    }
    await Future.wait(
      esperas,
    ).timeout(const Duration(seconds: 3), onTimeout: () => []);
  } catch (_) {
    // El constructor falla si una política de seguridad bloquea el sensor.
  } finally {
    for (final sensor in sensores) {
      sensor.stop();
    }
  }
}

/// Escucha 'devicemotion' durante [espera] y responde si llegó algún evento.
Future<bool> _llegaAlgunDeviceMotion(Duration espera) async {
  final llego = Completer<bool>();
  void alRecibir(web.Event _) {
    if (!llego.isCompleted) llego.complete(true);
  }

  final oyente = alRecibir.toJS;
  web.window.addEventListener('devicemotion', oyente);
  final resultado = await llego.future.timeout(espera, onTimeout: () => false);
  web.window.removeEventListener('devicemotion', oyente);
  return resultado;
}
