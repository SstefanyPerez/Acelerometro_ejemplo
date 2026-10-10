import 'package:flutter/material.dart';

/// Vista reutilizable para mostrar un aviso en lugar de los datos del
/// sensor: cargando, sin datos o error.
class VistaMensajeSensor extends StatelessWidget {
  const VistaMensajeSensor({
    super.key,
    required this.titulo,
    required this.mensaje,
    this.icono,
    this.cargando = false,
    this.onReintentar,
  });

  /// Título de la AppBar (nombre de la demo).
  final String titulo;

  /// Texto principal del aviso.
  final String mensaje;

  /// Ícono que acompaña al mensaje (se ignora si [cargando] es true).
  final IconData? icono;

  /// true muestra un indicador de progreso en lugar del ícono.
  final bool cargando;

  /// Si no es null, aparece un botón "Reintentar".
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cargando)
                const CircularProgressIndicator()
              else
                Icon(icono ?? Icons.sensors_off, size: 90, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              if (onReintentar != null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  onPressed: onReintentar,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
