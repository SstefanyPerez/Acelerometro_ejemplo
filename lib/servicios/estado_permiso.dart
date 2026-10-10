/// Estados posibles del permiso para leer los sensores de movimiento.
///
/// Todas las plataformas responden con uno de estos valores, así las
/// pantallas no necesitan saber si corren en Android, iOS o un navegador.
enum EstadoPermiso {
  /// El usuario aceptó el permiso (solo aplica en Web).
  concedido,

  /// El usuario negó el permiso: no llegarán datos de los sensores.
  denegado,

  /// Todavía no se ha preguntado al usuario.
  pendiente,

  /// La plataforma no pide permiso en tiempo de ejecución (Android e iOS).
  noRequerido,

  /// El navegador no tiene ninguna API de sensores de movimiento,
  /// o la página no se abrió por HTTPS.
  noSoportado,
}

/// Plataforma en la que corre la app. Define cómo se piden los permisos
/// y de dónde salen los datos.
enum Plataforma {
  android('Android'),
  ios('iOS'),
  webChromium('Web · Chrome / Edge (Generic Sensor API)'),
  webSafari('Web · Safari (DeviceMotionEvent)'),
  webOtro('Web · otro navegador'),
  otra('Escritorio');

  const Plataforma(this.nombre);

  /// Texto que se muestra en pantalla.
  final String nombre;

  /// true si la app corre dentro de un navegador.
  bool get esWeb => this == webChromium || this == webSafari || this == webOtro;
}
