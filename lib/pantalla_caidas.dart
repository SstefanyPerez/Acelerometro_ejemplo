import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

const double umbralCaidaLibre = 3;
const double umbralImpacto = 20;
const Duration tiempoMaximo = Duration(seconds: 1);

class PantallaCaidas extends StatefulWidget {
  const PantallaCaidas({super.key});

  @override
  State<PantallaCaidas> createState() => _PantallaCaidasState();
}

class _PantallaCaidasState extends State<PantallaCaidas> {
  StreamSubscription<AccelerometerEvent>? _suscripcion;
  Timer? _temporizador;

  String _estado = 'monitoreando';
  double _aceleracion = 0;
  DateTime? _momentoCaidaLibre;
  int _segundos = 10;
  String? _error;

  @override
  void initState() {
    super.initState();
    _suscripcion = accelerometerEventStream().listen((evento) {
      // Pitágoras: aceleración total en los 3 ejes
      final double total = math.sqrt(
        evento.x * evento.x + evento.y * evento.y + evento.z * evento.z,
      );

      setState(() => _aceleracion = total);

      if (_estado != 'monitoreando') return;

      if (total < umbralCaidaLibre) {
        _momentoCaidaLibre = DateTime.now();
      }
      if (total > umbralImpacto &&
          _momentoCaidaLibre != null &&
          DateTime.now().difference(_momentoCaidaLibre!) < tiempoMaximo) {
        _activarAlerta();
      }
    },
        onError: (_) {
      setState(() => _error = 'Este dispositivo no tiene acelerómetro');
    }, cancelOnError: true);
  }

  void _activarAlerta() {
    HapticFeedback.vibrate();
    _momentoCaidaLibre = null;
    setState(() {
      _estado = 'alerta';
      _segundos = 10;
    });

    _temporizador?.cancel();
    _temporizador = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _segundos--;
        if (_segundos == 0) {
          _temporizador?.cancel();
          _estado = 'enviada';
        }
      });
    });
  }

  void _volverAMonitorear() {
    _temporizador?.cancel();
    _momentoCaidaLibre = null;
    setState(() => _estado = 'monitoreando');
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
        appBar: AppBar(title: const Text('Detector de caídas')),
        body: Center(child: Text(_error!, style: const TextStyle(fontSize: 18))),
      );
    }

    if (_estado == 'alerta') {
      return Scaffold(
        backgroundColor: Colors.red,
        appBar: AppBar(title: const Text('Detector de caídas')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.warning, size: 100, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  '¿Estás bien?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$_segundos',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 80,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                    ),
                    onPressed: _volverAMonitorear,
                    child: const Text(
                      'Estoy bien',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_estado == 'enviada') {
      return Scaffold(
        appBar: AppBar(title: const Text('Detector de caídas')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.sms, size: 100, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Alerta enviada a tu contacto de emergencia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Volver a monitorear'),
                  onPressed: _volverAMonitorear,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detector de caídas')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.elderly, size: 120, color: Colors.green.shade700),
              const SizedBox(height: 16),
              Text(
                'Monitoreando…',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Aceleración total: ${_aceleracion.toStringAsFixed(2)} m/s²',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Caída libre < $umbralCaidaLibre   ·   Impacto > $umbralImpacto',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              TextButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Simular caída'),
                onPressed: _activarAlerta,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
