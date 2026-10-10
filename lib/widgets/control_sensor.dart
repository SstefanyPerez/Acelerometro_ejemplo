import 'dart:async';

import 'package:flutter/material.dart';

import '../servicios/fuente_sensores.dart';
import '../servicios/servicio_permisos.dart';
import 'vista_mensaje_sensor.dart';
import 'vista_permiso_denegado.dart';

/// Etapas por las que pasa una pantalla de sensores.
enum EtapaSensor {
  revisandoPermiso,
  esperandoPermiso, // Safari: falta que el usuario toque "Permitir"
  permisoDenegado,
  esperandoDatos, // suscritos, pero aún no llega la primera lectura
  conDatos,
  sinDatos, // pasaron 3 s sin lecturas válidas
  error, // el Stream envió un error (por ejemplo, el sensor no existe)
}

/// Lógica común de las pantallas de sensores:
/// 1. Al abrirse, revisa el permiso.
/// 2. Si hay permiso, se suscribe al sensor y arranca un temporizador de 3 s.
/// 3. Si no llega ninguna lectura válida a tiempo, muestra "No se reciben datos".
///
/// Cada pantalla solo implementa [sensorUsado], [empezarAEscuchar] y
/// [dejarDeEscuchar].
mixin ControlSensor<T extends StatefulWidget> on State<T> {
  static const Duration tiempoMaximoSinDatos = Duration(seconds: 3);

  EtapaSensor etapa = EtapaSensor.revisandoPermiso;
  String? _mensajeError;
  Timer? _temporizadorSinDatos;

  /// Sensor que usa la pantalla (para los mensajes de error).
  TipoSensor get sensorUsado;

  /// Crea la suscripción al Stream del sensor.
  void empezarAEscuchar();

  /// Cancela la suscripción al Stream del sensor.
  void dejarDeEscuchar();

  /// Llamar en initState: consulta el permiso sin mostrar diálogos.
  Future<void> revisarPermiso() async {
    final estado = await ServicioPermisos.consultar();
    if (mounted) _aplicarPermiso(estado);
  }

  /// Llamar desde el onPressed de un botón. No hay await antes de
  /// solicitar() porque Safari exige que ocurra durante el toque.
  void pedirPermiso() {
    ServicioPermisos.solicitar().then((estado) {
      if (mounted) _aplicarPermiso(estado);
    });
  }

  void _aplicarPermiso(EstadoPermiso estado) {
    if (estado == EstadoPermiso.denegado) {
      setState(() => etapa = EtapaSensor.permisoDenegado);
    } else if (estado == EstadoPermiso.pendiente &&
        ServicioPermisos.requiereGesto) {
      setState(() => etapa = EtapaSensor.esperandoPermiso);
    } else {
      // concedido, noRequerido, o pendiente en Chrome (se resuelve solo al
      // encender el sensor). Si no es soportado, el temporizador lo detecta.
      _iniciarLectura();
    }
  }

  void _iniciarLectura() {
    dejarDeEscuchar();
    setState(() => etapa = EtapaSensor.esperandoDatos);
    empezarAEscuchar();

    // Si en 3 s no llega ninguna lectura válida, avisamos al usuario.
    _temporizadorSinDatos?.cancel();
    _temporizadorSinDatos = Timer(tiempoMaximoSinDatos, () {
      if (mounted && etapa == EtapaSensor.esperandoDatos) {
        setState(() => etapa = EtapaSensor.sinDatos);
      }
    });
  }

  /// Llamar al recibir cada lectura. Devuelve false si debe ignorarse
  /// (la lectura falsa 0,0,0 que emite sensors_plus en Web).
  bool registrarLectura(double x, double y, double z) {
    if (!FuenteSensores.esLecturaValida(x, y, z)) return false;
    if (etapa != EtapaSensor.conDatos) {
      _temporizadorSinDatos?.cancel();
      setState(() => etapa = EtapaSensor.conDatos);
    }
    return true;
  }

  /// Llamar desde onError del Stream.
  void registrarError(Object error) {
    _temporizadorSinDatos?.cancel();
    setState(() {
      etapa = EtapaSensor.error;
      _mensajeError = sensorUsado.mensajeDeError(error);
    });
  }

  /// Llamar en dispose para no dejar el temporizador vivo.
  void liberarControl() => _temporizadorSinDatos?.cancel();

  /// Devuelve la vista que reemplaza a la pantalla mientras no haya datos,
  /// o null si ya hay datos y la pantalla debe dibujarse normalmente.
  Widget? vistaSegunEtapa(String titulo) {
    switch (etapa) {
      case EtapaSensor.revisandoPermiso:
        return VistaMensajeSensor(
          titulo: titulo,
          mensaje: 'Revisando permiso…',
          cargando: true,
        );
      case EtapaSensor.esperandoPermiso:
      case EtapaSensor.permisoDenegado:
        return VistaPermisoDenegado(
          titulo: titulo,
          pendiente: etapa == EtapaSensor.esperandoPermiso,
          onReintentar: pedirPermiso,
        );
      case EtapaSensor.esperandoDatos:
        return VistaMensajeSensor(
          titulo: titulo,
          mensaje: 'Esperando datos del ${sensorUsado.nombre}…',
          cargando: true,
        );
      case EtapaSensor.sinDatos:
        return VistaMensajeSensor(
          titulo: titulo,
          icono: Icons.sensors_off,
          mensaje:
              'No se reciben datos del sensor.\n\n'
              'Puede que el equipo no tenga ${sensorUsado.nombre}, que el '
              'navegador no lo soporte o que la página no use HTTPS.',
          onReintentar: _iniciarLectura,
        );
      case EtapaSensor.error:
        return VistaMensajeSensor(
          titulo: titulo,
          icono: Icons.error_outline,
          mensaje: _mensajeError ?? 'Error al leer el sensor.',
        );
      case EtapaSensor.conDatos:
        return null;
    }
  }
}
