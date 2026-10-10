// Fuente de datos para Web.
//
// - Chrome/Edge: sensors_plus ya usa la Generic Sensor API (Accelerometer(),
//   Gyroscope()), así que acelerómetro y giroscopio se leen con sensors_plus.
// - Safari: no tiene Generic Sensor API; los datos salen del evento
//   'devicemotion' y los convertimos a los mismos tipos de sensors_plus.
// - Acelerómetro de usuario: sensors_plus 7.1.0 en Web tiene un error (envía
//   esas lecturas al stream del giroscopio y nunca emite), por eso siempre
//   lo leemos de 'devicemotion' (propiedad `acceleration`, sin gravedad).

import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';
import 'package:web/web.dart' as web;

import 'interop_web.dart';

/// Safari no tiene Accelerometer/Gyroscope pero sí DeviceMotionEvent.
bool get _usarDeviceMotion => !tieneGenericSensor && tieneDeviceMotion;

/// En iPhone, Safari entrega la aceleración con el signo contrario al de
/// Android (boca arriba da z = -9.8). sensors_plus usa la convención de
/// Android (z = +9.8), así que invertimos los tres ejes.
double get _signo => esSafariConPermiso ? -1 : 1;

/// Grados por segundo → radianes por segundo (unidad de sensors_plus).
const double _gradosARadianes = math.pi / 180;

Stream<AccelerometerEvent> acelerometro(Duration samplingPeriod) {
  if (!_usarDeviceMotion) {
    return accelerometerEventStream(samplingPeriod: samplingPeriod);
  }
  return _escucharDeviceMotion((evento) {
    final a = evento.accelerationIncludingGravity;
    if (a == null || a.x == null || a.y == null || a.z == null) return null;
    return AccelerometerEvent(
      a.x! * _signo,
      a.y! * _signo,
      a.z! * _signo,
      DateTime.now(),
    );
  });
}

Stream<UserAccelerometerEvent> acelerometroUsuario(Duration samplingPeriod) {
  if (!tieneDeviceMotion) {
    return userAccelerometerEventStream(samplingPeriod: samplingPeriod);
  }
  return _escucharDeviceMotion((evento) {
    final a = evento.acceleration;
    if (a == null || a.x == null || a.y == null || a.z == null) return null;
    return UserAccelerometerEvent(
      a.x! * _signo,
      a.y! * _signo,
      a.z! * _signo,
      DateTime.now(),
    );
  });
}

Stream<GyroscopeEvent> giroscopio(Duration samplingPeriod) {
  if (!_usarDeviceMotion) {
    return gyroscopeEventStream(samplingPeriod: samplingPeriod);
  }
  return _escucharDeviceMotion((evento) {
    // beta = giro en X, gamma = giro en Y, alpha = giro en Z (grados/s).
    final r = evento.rotationRate;
    if (r == null || r.alpha == null || r.beta == null || r.gamma == null) {
      return null;
    }
    return GyroscopeEvent(
      r.beta! * _gradosARadianes,
      r.gamma! * _gradosARadianes,
      r.alpha! * _gradosARadianes,
      DateTime.now(),
    );
  });
}

/// Convierte el evento 'devicemotion' de la ventana en un Stream de Dart.
/// [convertir] devuelve null si el evento no trae datos útiles.
///
/// El oyente se registra al suscribirse (onListen) y se quita al cancelar
/// (onCancel), igual que hace sensors_plus con los sensores nativos.
Stream<T> _escucharDeviceMotion<T>(
  T? Function(web.DeviceMotionEvent evento) convertir,
) {
  late final StreamController<T> controlador;
  JSFunction? oyente;

  controlador = StreamController<T>(
    onListen: () {
      void alRecibir(web.DeviceMotionEvent evento) {
        final dato = convertir(evento);
        if (dato != null) controlador.add(dato);
      }

      oyente = alRecibir.toJS;
      web.window.addEventListener('devicemotion', oyente);
    },
    onCancel: () {
      web.window.removeEventListener('devicemotion', oyente);
    },
  );
  return controlador.stream;
}
