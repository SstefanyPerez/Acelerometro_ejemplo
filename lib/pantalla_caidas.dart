import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'servicios/fuente_sensores.dart';
import 'widgets/control_sensor.dart';

/// En caída libre el acelerómetro marca casi 0 (el celular "flota"),
/// en reposo marca ~9.8 m/s² (la gravedad).
const double umbralCaidaLibre = 3;

/// Al golpear el suelo aparece un pico muy alto, de más de 2 g.
const double umbralImpacto = 20;

/// El impacto debe llegar poco después de la caída libre para contar.
const Duration tiempoMaximo = Duration(seconds: 1);

/// Estados de la pantalla del detector.
enum EstadoCaida { monitoreando, alerta, enviada }

/// Demo 3: detector de caídas.
/// Patrón: primero caída libre (aceleración < 3) y, en menos de 1 s,
/// un impacto (aceleración > 20). Si ocurre, pregunta "¿Estás bien?".
class PantallaCaidas extends StatefulWidget {
  const PantallaCaidas({super.key});

  @override
  State<PantallaCaidas> createState() => _PantallaCaidasState();
}

class _PantallaCaidasState extends State<PantallaCaidas>
    with ControlSensor<PantallaCaidas> {
  StreamSubscription<AccelerometerEvent>? _suscripcion;

  /// Cuenta regresiva de la alerta (10 s).
  Timer? _temporizador;

  EstadoCaida _estado = EstadoCaida.monitoreando;
  double _aceleracion = 0;
  DateTime? _momentoCaidaLibre;
  int _segundos = 10;

  @override
  TipoSensor get sensorUsado => TipoSensor.acelerometro;

  /// initState: revisa el permiso; si hay, el mixin llama a empezarAEscuchar.
  @override
  void initState() {
    super.initState();
    revisarPermiso();
  }

  @override
  void empezarAEscuchar() {
    _suscripcion = FuenteSensores.acelerometro().listen(
      (evento) {
        if (!registrarLectura(evento.x, evento.y, evento.z)) return;

        // Pitágoras: aceleración total en los 3 ejes, √(x² + y² + z²).
        final double total = math.sqrt(
          evento.x * evento.x + evento.y * evento.y + evento.z * evento.z,
        );

        setState(() => _aceleracion = total);

        if (_estado != EstadoCaida.monitoreando) return;

        // Paso 1: caída libre → guardamos el momento.
        if (total < umbralCaidaLibre) {
          _momentoCaidaLibre = DateTime.now();
        }
        // Paso 2: impacto fuerte poco después de la caída libre → alerta.
        if (total > umbralImpacto &&
            _momentoCaidaLibre != null &&
            DateTime.now().difference(_momentoCaidaLibre!) < tiempoMaximo) {
          _activarAlerta();
        }
      },
      // onError: el equipo no tiene acelerómetro o falló la lectura.
      onError: registrarError,
      // cancelOnError: cancela la suscripción después del error.
      cancelOnError: true,
    );
  }

  @override
  void dejarDeEscuchar() => _suscripcion?.cancel();

  /// Vibra, muestra la alerta y arranca la cuenta regresiva de 10 s.
  void _activarAlerta() {
    HapticFeedback.vibrate();
    _momentoCaidaLibre = null;
    setState(() {
      _estado = EstadoCaida.alerta;
      _segundos = 10;
    });

    _temporizador?.cancel();
    _temporizador = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _segundos--;
        if (_segundos == 0) {
          _temporizador?.cancel();
          _estado = EstadoCaida.enviada;
        }
      });
    });
  }

  /// "Estoy bien": cancela la alerta y vuelve a vigilar.
  void _volverAMonitorear() {
    _temporizador?.cancel();
    _momentoCaidaLibre = null;
    setState(() => _estado = EstadoCaida.monitoreando);
  }

  /// dispose: cancela la suscripción y los temporizadores al salir.
  @override
  void dispose() {
    _suscripcion?.cancel();
    _temporizador?.cancel();
    liberarControl();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aviso = vistaSegunEtapa('Detector de caídas');
    if (aviso != null) return aviso;

    switch (_estado) {
      case EstadoCaida.alerta:
        return _vistaAlerta();
      case EstadoCaida.enviada:
        return _vistaEnviada();
      case EstadoCaida.monitoreando:
        return _vistaMonitoreo();
    }
  }

  Widget _vistaAlerta() {
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

  Widget _vistaEnviada() {
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

  Widget _vistaMonitoreo() {
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
              // Permite probar la alerta sin dejar caer el celular.
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
