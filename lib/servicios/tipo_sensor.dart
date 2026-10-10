import 'package:flutter/services.dart';

/// Sensores que usa la app. Sirve para dar mensajes de error que digan
/// exactamente qué sensor falta.
enum TipoSensor {
  acelerometro('acelerómetro'),
  acelerometroUsuario('acelerómetro de usuario'),
  giroscopio('giroscopio');

  const TipoSensor(this.nombre);

  /// Nombre legible del sensor.
  final String nombre;

  /// Convierte el error que llega por onError en un mensaje para el usuario.
  ///
  /// En Android, si el sensor no existe, sensors_plus envía una
  /// PlatformException con el código "NO_SENSOR".
  String mensajeDeError(Object error) {
    final noExiste = error is PlatformException && error.code == 'NO_SENSOR';
    final base = noExiste
        ? 'Este dispositivo no tiene $nombre.'
        : 'No se pudo leer el $nombre.';

    if (this == TipoSensor.acelerometroUsuario) {
      // El acelerómetro de usuario no es un chip: se calcula por software
      // restando la gravedad, y para eso muchos equipos usan el giroscopio.
      return '$base\n\nEl acelerómetro de usuario se calcula por software '
          '(acelerómetro menos gravedad) y en muchos equipos depende del '
          'giroscopio. Si tu equipo no tiene giroscopio, esta demo no '
          'funcionará en él.';
    }
    return base;
  }
}
