import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'servicios/fuente_sensores.dart';
import 'widgets/control_sensor.dart';

/// Demo 2: un muñequito que se despeina cuando agitas el celular.
/// Usa el ACELERÓMETRO DE USUARIO (sin gravedad): en reposo marca ~0,
/// así que cualquier valor alto significa que la persona movió el equipo.
class PantallaMuneco extends StatefulWidget {
  const PantallaMuneco({super.key});

  @override
  State<PantallaMuneco> createState() => _PantallaMunecoState();
}

class _PantallaMunecoState extends State<PantallaMuneco>
    with ControlSensor<PantallaMuneco> {
  /// Fuerza (m/s²) a partir de la cual consideramos que hubo una sacudida.
  static const double umbral = 10;

  StreamSubscription<UserAccelerometerEvent>? _suscripcion;

  /// Temporizador que devuelve al muñeco a "tranquilo" tras 2 s.
  Timer? _temporizador;

  bool _agitado = false;
  double _fuerza = 0;

  @override
  TipoSensor get sensorUsado => TipoSensor.acelerometroUsuario;

  /// initState: revisa el permiso; si hay, el mixin llama a empezarAEscuchar.
  @override
  void initState() {
    super.initState();
    revisarPermiso();
  }

  @override
  void empezarAEscuchar() {
    _suscripcion = FuenteSensores.acelerometroUsuario().listen(
      (evento) {
        if (!registrarLectura(evento.x, evento.y, evento.z)) return;

        // Magnitud con Pitágoras en 3D: √(x² + y² + z²).
        // Así no importa en qué dirección se agite el celular.
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
      // onError: el acelerómetro de usuario no está disponible.
      onError: registrarError,
      // cancelOnError: no seguimos escuchando un sensor que falló.
      cancelOnError: true,
    );
  }

  @override
  void dejarDeEscuchar() => _suscripcion?.cancel();

  /// dispose: cancela la suscripción y el temporizador al salir.
  @override
  void dispose() {
    _suscripcion?.cancel();
    _temporizador?.cancel();
    liberarControl();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aviso = vistaSegunEtapa('Muñequito');
    if (aviso != null) return aviso;

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

            // Barra de fuerza: llena al llegar a 20 m/s².
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
