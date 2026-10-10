import 'package:flutter/material.dart';

import 'servicios/fuente_sensores.dart';
import 'servicios/servicio_permisos.dart';
import 'widgets/vista_permiso_denegado.dart';

/// Pantalla de permisos: muestra la plataforma, el estado del permiso de
/// los sensores de movimiento y permite solicitarlo.
/// Sirve para la demo de ACEPTAR y NEGAR el permiso.
class PantallaPermisos extends StatefulWidget {
  const PantallaPermisos({super.key});

  @override
  State<PantallaPermisos> createState() => _PantallaPermisosState();
}

class _PantallaPermisosState extends State<PantallaPermisos> {
  final Plataforma _plataforma = ServicioPermisos.plataforma;

  /// null mientras se consulta.
  EstadoPermiso? _estado;

  /// Disponibilidad de cada sensor: true, false o null (sin datos).
  final Map<TipoSensor, bool?> _disponible = {};
  bool _comprobandoSensores = false;

  /// initState: al abrir la pantalla consultamos el permiso (sin diálogos).
  @override
  void initState() {
    super.initState();
    ServicioPermisos.consultar().then(_mostrarEstado);
  }

  /// Botón "Solicitar permiso". La llamada a solicitar() va primero y sin
  /// await antes, porque Safari solo muestra el diálogo durante el toque.
  void _solicitar() {
    ServicioPermisos.solicitar().then(_mostrarEstado);
  }

  void _mostrarEstado(EstadoPermiso estado) {
    if (!mounted) return;
    setState(() => _estado = estado);
    if (estado == EstadoPermiso.concedido ||
        estado == EstadoPermiso.noRequerido) {
      _comprobarSensores();
    }
  }

  /// Escucha cada sensor unos segundos para saber si existe.
  Future<void> _comprobarSensores() async {
    if (_comprobandoSensores) return;
    setState(() => _comprobandoSensores = true);
    final resultados = await Future.wait([
      FuenteSensores.estaDisponible(TipoSensor.acelerometro),
      FuenteSensores.estaDisponible(TipoSensor.giroscopio),
    ]);
    if (!mounted) return;
    setState(() {
      _disponible[TipoSensor.acelerometro] = resultados[0];
      _disponible[TipoSensor.giroscopio] = resultados[1];
      _comprobandoSensores = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permisos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                _plataforma.esWeb ? Icons.public : Icons.phone_android,
              ),
              title: const Text('Plataforma'),
              subtitle: Text(_plataforma.nombre),
            ),
          ),
          _tarjetaEstado(),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.lock_open),
            label: const Text('Solicitar permiso'),
            onPressed: _estado == null ? null : _solicitar,
          ),
          const SizedBox(height: 8),
          if (_estado == EstadoPermiso.denegado)
            _tarjetaInfo(
              icono: Icons.settings,
              color: Colors.red,
              titulo: '¿Cómo volver a activarlo?',
              texto: instruccionesParaReactivar(_plataforma),
            ),
          if (_estado == EstadoPermiso.noSoportado)
            _tarjetaInfo(
              icono: Icons.https,
              color: Colors.grey,
              titulo: 'No soportado',
              texto:
                  'Los sensores de movimiento en Web necesitan HTTPS y un '
                  'navegador compatible: Chrome/Edge (Generic Sensor API) o '
                  'Safari en iPhone (DeviceMotionEvent).',
            ),
          if (_estado == EstadoPermiso.noRequerido)
            _tarjetaInfo(
              icono: Icons.info_outline,
              color: Colors.blue,
              titulo: 'No requiere permiso en ejecución',
              texto: _explicacionNativa(),
            ),
          if (_estado == EstadoPermiso.concedido ||
              _estado == EstadoPermiso.noRequerido)
            _tarjetaSensores(),
        ],
      ),
    );
  }

  /// Texto que explica por qué Android/iOS no muestran un diálogo.
  String _explicacionNativa() {
    switch (_plataforma) {
      case Plataforma.android:
        return 'En Android leer el acelerómetro y el giroscopio no pide '
            'permiso al usuario. Solo para leer a más de 200 Hz (Android 12+) '
            'habría que declarar HIGH_SAMPLING_RATE_SENSORS en el '
            'AndroidManifest.xml.';
      case Plataforma.ios:
        return 'En iOS Core Motion no muestra un diálogo para el acelerómetro '
            'ni el giroscopio, pero sensors_plus exige la clave '
            'NSMotionUsageDescription en Info.plist (sin ella la app se cierra).';
      default:
        return 'Esta plataforma no pide permiso para leer los sensores.';
    }
  }

  /// Tarjeta con el estado del permiso: ícono, color y texto.
  Widget _tarjetaEstado() {
    final (IconData icono, Color color, String texto) = switch (_estado) {
      null => (Icons.hourglass_empty, Colors.grey, 'Consultando…'),
      EstadoPermiso.concedido => (
        Icons.check_circle,
        Colors.green,
        'Concedido',
      ),
      EstadoPermiso.denegado => (Icons.cancel, Colors.red, 'Denegado'),
      EstadoPermiso.pendiente => (
        Icons.help,
        Colors.orange,
        'Pendiente (aún no se ha preguntado)',
      ),
      EstadoPermiso.noRequerido => (
        Icons.verified,
        Colors.blue,
        'No requerido',
      ),
      EstadoPermiso.noSoportado => (
        Icons.block,
        Colors.grey,
        'No soportado en este navegador',
      ),
    };
    return Card(
      child: ListTile(
        leading: Icon(icono, color: color, size: 36),
        title: const Text('Estado del permiso'),
        subtitle: Text(
          texto,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Tarjeta que indica si el acelerómetro y el giroscopio entregan datos.
  Widget _tarjetaSensores() {
    Widget fila(TipoSensor tipo) {
      final valor = _disponible[tipo];
      final Widget icono;
      final String texto;
      if (_comprobandoSensores) {
        icono = const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
        texto = 'Comprobando…';
      } else if (valor == true) {
        icono = const Icon(Icons.check_circle, color: Colors.green);
        texto = 'Disponible';
      } else if (valor == false) {
        icono = const Icon(Icons.cancel, color: Colors.red);
        texto = 'No disponible';
      } else {
        icono = const Icon(Icons.help, color: Colors.orange);
        texto = 'Sin datos';
      }
      return ListTile(
        leading: icono,
        title: Text(tipo.nombre[0].toUpperCase() + tipo.nombre.substring(1)),
        subtitle: Text(texto),
      );
    }

    return Card(
      child: Column(
        children: [
          const ListTile(title: Text('Sensores del equipo')),
          fila(TipoSensor.acelerometro),
          fila(TipoSensor.giroscopio),
        ],
      ),
    );
  }

  Widget _tarjetaInfo({
    required IconData icono,
    required Color color,
    required String titulo,
    required String texto,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icono, color: color),
        title: Text(titulo),
        subtitle: Text(texto),
      ),
    );
  }
}
