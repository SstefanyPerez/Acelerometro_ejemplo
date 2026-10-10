import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'servicios/fuente_sensores.dart';
import 'widgets/control_sensor.dart';

/// Demo 4: giroscopio.
/// El giroscopio NO mide la inclinación, mide qué tan rápido gira el
/// celular (rad/s) alrededor de cada eje. Si sumamos esa velocidad en el
/// tiempo (ángulo = velocidad × tiempo) obtenemos cuánto ha girado.
class PantallaGiroscopio extends StatefulWidget {
  const PantallaGiroscopio({super.key});

  @override
  State<PantallaGiroscopio> createState() => _PantallaGiroscopioState();
}

class _PantallaGiroscopioState extends State<PantallaGiroscopio>
    with ControlSensor<PantallaGiroscopio> {
  /// Rango de las barras de cada eje (±5 rad/s).
  static const double velocidadMaxima = 5;

  StreamSubscription<GyroscopeEvent>? _suscripcion;

  double _x = 0;
  double _y = 0;
  double _z = 0;

  /// Ángulo acumulado alrededor de Z, en radianes.
  double _anguloZ = 0;

  /// Momento de la lectura anterior, para calcular el tiempo transcurrido.
  DateTime? _ultimaLectura;

  @override
  TipoSensor get sensorUsado => TipoSensor.giroscopio;

  /// initState: revisa el permiso; si hay, el mixin llama a empezarAEscuchar.
  @override
  void initState() {
    super.initState();
    revisarPermiso();
  }

  @override
  void empezarAEscuchar() {
    _ultimaLectura = null;
    // samplingPeriod: gameInterval (~20 ms) para que la animación sea fluida.
    _suscripcion =
        FuenteSensores.giroscopio(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen(
          (GyroscopeEvent evento) {
            if (!registrarLectura(evento.x, evento.y, evento.z)) return;

            // Tiempo entre lecturas en segundos (limitado a 0.1 s por si
            // la app estuvo en pausa).
            final anterior = _ultimaLectura;
            _ultimaLectura = evento.timestamp;
            final double dt = anterior == null
                ? 0
                : (evento.timestamp.difference(anterior).inMicroseconds / 1e6)
                      .clamp(0.0, 0.1);

            setState(() {
              _x = evento.x;
              _y = evento.y;
              _z = evento.z;
              // Integración: ángulo += velocidad angular × tiempo.
              _anguloZ += evento.z * dt;
            });
          },
          // onError: el equipo no tiene giroscopio.
          onError: registrarError,
          // cancelOnError: cancela la suscripción después del error.
          cancelOnError: true,
        );
  }

  @override
  void dejarDeEscuchar() => _suscripcion?.cancel();

  /// dispose: cancela la suscripción para apagar el giroscopio al salir.
  @override
  void dispose() {
    _suscripcion?.cancel();
    liberarControl();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aviso = vistaSegunEtapa('Giroscopio');
    if (aviso != null) return aviso;

    // Ángulo en grados entre 0 y 359 para mostrarlo en pantalla.
    final double grados = (_anguloZ * 180 / math.pi) % 360;
    // Qué tan rápido gira en total (Pitágoras en 3D), para el brillo.
    final double rapidez = math.sqrt(_x * _x + _y * _y + _z * _z);
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Giroscopio')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pon el celular acostado y gíralo sobre la mesa',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),

              // Flutter gira en sentido horario con ángulos positivos y el
              // giroscopio usa positivo = antihorario; por eso el signo menos.
              Transform.rotate(
                angle: -_anguloZ,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(
                          alpha: (0.2 + rapidez / 4).clamp(0.2, 0.9),
                        ),
                        blurRadius: 10 + rapidez * 8,
                        spreadRadius: rapidez * 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.navigation,
                    size: 90,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 30),
              Text(
                'Giro acumulado en Z: ${grados.toStringAsFixed(0)}°',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              _eje('X', _x, Colors.red),
              _eje('Y', _y, Colors.green),
              _eje('Z', _z, colores.primary),

              const SizedBox(height: 20),
              OutlinedButton.icon(
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reiniciar ángulo'),
                onPressed: () => setState(() => _anguloZ = 0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fila con el valor de un eje en rad/s y una barra centrada en 0.
  Widget _eje(String eje, double valor, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$eje: ${valor.toStringAsFixed(2)} rad/s',
              style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
            ),
          ),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              // 0.5 es el centro (sin giro); los extremos son ±5 rad/s.
              value: (0.5 + valor / (2 * velocidadMaxima)).clamp(0.0, 1.0),
              minHeight: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
