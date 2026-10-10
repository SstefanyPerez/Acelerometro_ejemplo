// Implementación de permisos para Android, iOS y escritorio.
// Este archivo se usa cuando la app NO corre en un navegador
// (ver el import condicional en servicio_permisos.dart).

import 'package:flutter/foundation.dart';

import 'estado_permiso.dart';

/// Detecta la plataforma nativa en la que corre la app.
Plataforma detectarPlataforma() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return Plataforma.android;
    case TargetPlatform.iOS:
      return Plataforma.ios;
    default:
      return Plataforma.otra;
  }
}

/// En Android e iOS leer el acelerómetro y el giroscopio NO necesita
/// un permiso en tiempo de ejecución, así que no hay nada que consultar.
Future<EstadoPermiso> consultarPermiso() async => EstadoPermiso.noRequerido;

/// Tampoco hay diálogo que mostrar: se responde lo mismo que en consultar.
Future<EstadoPermiso> solicitarPermiso() async => EstadoPermiso.noRequerido;
