// Import condicional: en Web se usa fuente_sensores_web.dart (que soporta
// Safari); en Android/iOS, fuente_sensores_nativa.dart (sensors_plus directo).
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'fuente_sensores_nativa.dart'
    if (dart.library.js_interop) 'fuente_sensores_web.dart'
    as implementacion;
import 'tipo_sensor.dart';

export 'package:sensors_plus/sensors_plus.dart'
    show
        AccelerometerEvent,
        GyroscopeEvent,
        SensorInterval,
        UserAccelerometerEvent;
export 'tipo_sensor.dart';

/// Fuente única de datos de los sensores. Las pantallas la usan en lugar
/// de llamar directamente a sensors_plus, así funcionan igual en Android,
/// iOS, Chrome y Safari.
class FuenteSensores {
  FuenteSensores._();

  /// Acelerómetro: aceleración en m/s² INCLUYENDO la gravedad.
  ///
  /// [samplingPeriod] indica cada cuánto queremos una lectura
  /// (SensorInterval.gameInterval ≈ 20 ms, normalInterval ≈ 200 ms).
  static Stream<AccelerometerEvent> acelerometro({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) => implementacion.acelerometro(samplingPeriod);

  /// Acelerómetro de usuario: aceleración en m/s² SIN la gravedad
  /// (solo el movimiento que hace la persona).
  static Stream<UserAccelerometerEvent> acelerometroUsuario({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) => implementacion.acelerometroUsuario(samplingPeriod);

  /// Giroscopio: velocidad de giro en rad/s alrededor de X, Y y Z.
  static Stream<GyroscopeEvent> giroscopio({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) => implementacion.giroscopio(samplingPeriod);

  /// Comprueba si un sensor entrega datos.
  /// Devuelve true (llegó una lectura), false (llegó un error) o
  /// null (no llegó nada en [espera]).
  static Future<bool?> estaDisponible(
    TipoSensor tipo, {
    Duration espera = const Duration(seconds: 3),
  }) async {
    final Stream<List<double>> lecturas = switch (tipo) {
      TipoSensor.acelerometro => acelerometro().map((e) => [e.x, e.y, e.z]),
      TipoSensor.acelerometroUsuario => acelerometroUsuario().map(
        (e) => [e.x, e.y, e.z],
      ),
      TipoSensor.giroscopio => giroscopio().map((e) => [e.x, e.y, e.z]),
    };

    final resultado = Completer<bool?>();
    final suscripcion = lecturas.listen(
      (valores) {
        if (esLecturaValida(valores[0], valores[1], valores[2]) &&
            !resultado.isCompleted) {
          resultado.complete(true);
        }
      },
      onError: (_) {
        if (!resultado.isCompleted) resultado.complete(false);
      },
      cancelOnError: true,
    );

    final disponible = await resultado.future.timeout(
      espera,
      onTimeout: () => null,
    );
    await suscripcion.cancel();
    return disponible;
  }

  /// En Web, si el sensor no existe o está bloqueado, sensors_plus emite
  /// UNA lectura falsa (0, 0, 0) en lugar de un error. Por eso esa lectura
  /// exacta no cuenta como válida (solo en Web).
  static bool esLecturaValida(double x, double y, double z) =>
      !kIsWeb || x != 0 || y != 0 || z != 0;
}
