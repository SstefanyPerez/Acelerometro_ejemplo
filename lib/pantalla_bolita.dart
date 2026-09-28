import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class PantallaBolita extends StatefulWidget {
  const PantallaBolita({super.key});

  @override
  State<PantallaBolita> createState() => _PantallaBolitaState();
}

class _PantallaBolitaState extends State<PantallaBolita> {
  static const double radioArea = 140; // radio del círculo grande
  static const double radioBola = 25; // radio de la bolita
  static const double sensibilidad = 15; // píxeles que se mueve por cada m/s²

  StreamSubscription<AccelerometerEvent>? _suscripcion;

  double _x = 0;
  double _y = 0;
  double _z = 0;
  String? _error; 

  @override
  void initState() {
    super.initState();
    _suscripcion = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((AccelerometerEvent evento) {
      setState(() {
        _x = evento.x;
        _y = evento.y;
        _z = evento.z;
      });
    },
        onError: (_) {
      setState(() => _error = 'Este dispositivo no tiene acelerómetro');
    }, cancelOnError: true);
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bolita')),
        body: Center(child: Text(_error!, style: const TextStyle(fontSize: 18))),
      );
    }

    double dx = -_x * sensibilidad;
    double dy = _y * sensibilidad;

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

  Widget _valor(String eje, double valor) {
    return Text(
      '$eje: ${valor.toStringAsFixed(2)} m/s²',
      style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
    );
  }
}