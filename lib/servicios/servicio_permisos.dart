// Import condicional: si existe dart:js_interop (la app corre en un
// navegador) se usa permisos_web.dart; si no, permisos_nativos.dart.
// Así Android e iOS compilan sin nada del código web.
import 'permisos_nativos.dart'
    if (dart.library.js_interop) 'permisos_web.dart'
    as implementacion;

import 'estado_permiso.dart';

export 'estado_permiso.dart';

/// Punto único para consultar y pedir el permiso de los sensores de
/// movimiento en cualquier plataforma.
class ServicioPermisos {
  ServicioPermisos._();

  /// Plataforma actual (Android, iOS, Chrome, Safari…).
  static Plataforma get plataforma => implementacion.detectarPlataforma();

  /// true si el permiso solo se puede pedir con un toque del usuario
  /// (Safari). En ese caso la pantalla debe mostrar un botón.
  static bool get requiereGesto => plataforma == Plataforma.webSafari;

  /// Consulta el estado del permiso sin mostrar ningún diálogo.
  static Future<EstadoPermiso> consultar() => implementacion.consultarPermiso();

  /// Pide el permiso. Llamar dentro del onPressed de un botón y sin await
  /// antes (requisito de Safari).
  static Future<EstadoPermiso> solicitar() => implementacion.solicitarPermiso();
}
