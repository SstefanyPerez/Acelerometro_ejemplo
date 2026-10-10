import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'servicios/fuente_sensores.dart';
import 'widgets/control_sensor.dart';

/// Demo 1: una bolita que rueda según la inclinación del celular.
/// Usa el ACELERÓMETRO (incluye la gravedad), por eso al inclinar el
/// teléfono la gravedad "se reparte" entre los ejes X e Y.
class PantallaBolita extends StatefulWidget {
  const PantallaBolita({super.key});

  @override
  State<PantallaBolita> createState() => _PantallaBolitaState();
}

class _PantallaBolitaState extends State<PantallaBolita>
    with ControlSensor<PantallaBolita> {
  static const double radioArea = 140; // radio del círculo grande
  static const double radioBola = 25; // radio de la bolita
  static const double sensibilidad = 15; // píxeles que se mueve por cada m/s²

  /// Suscripción al Stream: la guardamos para poder cancelarla.
  StreamSubscription<AccelerometerEvent>? _suscripcion;

  double _x = 0;
  double _y = 0;
  double _z = 0;

  @override
  TipoSensor get sensorUsado => TipoSensor.acelerometro;

  /// initState: se ejecuta una sola vez al abrir la pantalla.
  /// Primero revisamos el permiso; si todo está bien, el mixin llama a
  /// empezarAEscuchar().
  @override
  void initState() {
    super.initState();
    revisarPermiso();
  }

  @override
  void empezarAEscuchar() {
    // samplingPeriod: gameInterval (~20 ms) da un movimiento fluido.
    _suscripcion =
        FuenteSensores.acelerometro(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen(
          // Cada lectura nueva llega aquí con los valores X, Y, Z en m/s².
          (AccelerometerEvent evento) {
            if (!registrarLectura(evento.x, evento.y, evento.z)) return;
            setState(() {
              _x = evento.x;
              _y = evento.y;
              _z = evento.z;
            });
          },
          // onError: el sensor no existe o falló.
          onError: registrarError,
          // cancelOnError: tras un error se cancela la suscripción sola.
          cancelOnError: true,
        );
  }

  @override
  void dejarDeEscuchar() => _suscripcion?.cancel();

  /// dispose: se ejecuta al salir de la pantalla. Cancelar la suscripción
  /// apaga el sensor y evita gastar batería y memoria.
  @override
  void dispose() {
    _suscripcion?.cancel();
    liberarControl();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si falta permiso, no hay datos o hubo error, se muestra ese aviso.
    final aviso = vistaSegunEtapa('Bolita');
    if (aviso != null) return aviso;

    // Inclinar a la derecha da X negativo, por eso se invierte el signo.
    double dx = -_x * sensibilidad;
    double dy = _y * sensibilidad;

    // Distancia al centro con Pitágoras; si se sale del círculo, se limita.
    final double limite = radioArea - radioBola;
    final double distancia = math.sqrt(dx * dx + dy * dy);
    if (distancia > limite) {
      dx = dx / distancia * limite;
      dy = dy / distancia * limite;
    }

    final bool centrada = distancia < 15;

    return Scaffold(
      appBar: AppBar(title: const Text('Bolita')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Pon el celular acostado e inclínalo',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: radioArea * 2,
              height: radioArea * 2,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: centrada ? Colors.green : Colors.redAccent,
                        width: 3,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(dx, dy),
                    child: Container(
                      width: radioBola * 2,
                      height: radioBola * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: centrada ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            Text(
              centrada ? '¡Centrada! 🎯' : 'Llévala al centro',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            _valor('X', _x),
            _valor('Y', _y),
            _valor('Z', _z),
          ],
        ),
      ),
    );
  }

  /// Muestra un eje con dos decimales.
  Widget _valor(String eje, double valor) {
    return Text(
      '$eje: ${valor.toStringAsFixed(2)} m/s²',
      style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
    );
  }
}
