import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class PantallaMuneco extends StatefulWidget {
  const PantallaMuneco({super.key});

  @override
  State<PantallaMuneco> createState() => _PantallaMunecoState();
}

class _PantallaMunecoState extends State<PantallaMuneco> {
  static const double umbral = 10; 

  StreamSubscription<UserAccelerometerEvent>? _suscripcion;
  Timer? _temporizador;

  bool _agitado = false;
  double _fuerza = 0;
  String? _error; 

  @override
  void initState() {
    super.initState();
    _suscripcion = userAccelerometerEventStream().listen((evento) {
      final double fuerza = math.sqrt(
        evento.x * evento.x + evento.y * evento.y + evento.z * evento.z,
      );

      setState(() {
        _fuerza = fuerza;
        if (fuerza > umbral) {
          _agitado = true;
          _temporizador?.cancel();
          _temporizador = Timer(const Duration(seconds: 2), () {
            if (mounted) setState(() => _agitado = false);
          });
        }
      });
    },
        onError: (_) {
      setState(() => _error = 'Este dispositivo no tiene acelerómetro');
    }, cancelOnError: true);
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    _temporizador?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Muñequito')),
        body: Center(child: Text(_error!, style: const TextStyle(fontSize: 18))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(title: const Text('Muñequito')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Image.asset(
                    _agitado
                        ? 'assets/muneco_despeinado.png'
                        : 'assets/muneco_tranquilo.png',
                    key: ValueKey(_agitado),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            Text(
              _agitado ? '¡Me despeinaste!' : 'Estoy tranquilo… agítame',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _agitado ? Colors.red : Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: LinearProgressIndicator(
                value: (_fuerza / 20).clamp(0.0, 1.0),
                minHeight: 12,
                color: _fuerza > umbral ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Fuerza: ${_fuerza.toStringAsFixed(2)} m/s²  (umbral: $umbral)',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}