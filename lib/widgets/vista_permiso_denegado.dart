import 'package:flutter/material.dart';

import '../servicios/servicio_permisos.dart';

/// Pasos para volver a activar el permiso según el navegador.
String instruccionesParaReactivar(Plataforma plataforma) {
  switch (plataforma) {
    case Plataforma.webChromium:
      return 'En Chrome toca el candado (o el ícono de ajustes) junto a la '
          'dirección → Configuración del sitio → Sensores de movimiento → '
          'Permitir. Luego recarga la página.';
    case Plataforma.webSafari:
      return 'En el iPhone abre Ajustes → Safari → Movimiento y orientación '
          '(o Ajustes → Apps → Safari en iOS 18) y actívalo. Luego recarga '
          'la página.';
    default:
      return 'Revisa los permisos de sensores de movimiento en la '
          'configuración del navegador y recarga la página.';
  }
}

/// Vista reutilizable que reemplaza a una pantalla de sensores cuando el
/// permiso está denegado (o pendiente en Safari, donde hace falta un toque).
class VistaPermisoDenegado extends StatelessWidget {
  const VistaPermisoDenegado({
    super.key,
    required this.titulo,
    required this.onReintentar,
    this.pendiente = false,
  });

  /// Título de la AppBar (nombre de la demo).
  final String titulo;

  /// Se ejecuta al tocar el botón. Debe llamar a ServicioPermisos.solicitar()
  /// sin await antes, para que Safari muestre el diálogo.
  final VoidCallback onReintentar;

  /// true: aún no se ha preguntado (Safari). false: el usuario lo negó.
  final bool pendiente;

  @override
  Widget build(BuildContext context) {
    final color = pendiente ? Colors.orange : Colors.red;
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                pendiente ? Icons.touch_app : Icons.block,
                size: 90,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                pendiente ? 'Se necesita permiso' : 'Permiso denegado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                pendiente
                    ? 'Toca el botón para permitir el acceso a los sensores '
                          'de movimiento.'
                    : 'Sin este permiso el navegador no entrega datos del '
                          'acelerómetro ni del giroscopio.\n\n'
                          '${instruccionesParaReactivar(ServicioPermisos.plataforma)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: Icon(pendiente ? Icons.check : Icons.refresh),
                label: Text(pendiente ? 'Permitir sensores' : 'Reintentar'),
                onPressed: onReintentar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
