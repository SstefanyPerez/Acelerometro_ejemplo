import 'package:acelerometro_ejemplo/pantalla_bolita.dart';
import 'package:acelerometro_ejemplo/pantalla_caidas.dart';
import 'package:acelerometro_ejemplo/pantalla_giroscopio.dart';
import 'package:acelerometro_ejemplo/pantalla_muneco.dart';
import 'package:acelerometro_ejemplo/pantalla_permisos.dart';
import 'package:flutter/material.dart';

/// Punto de entrada: arranca la app.
void main() => runApp(const MyApp());

/// Widget raíz: define el título y el tema de toda la app.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Acelerómetro y Giroscopio',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const MenuPage(),
    );
  }
}

/// Menú principal con un botón por cada demo.
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  /// Abre una pantalla encima del menú.
  void _abrir(BuildContext context, Widget pantalla) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acelerómetro y Giroscopio'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.screen_rotation, size: 90),
              const SizedBox(height: 16),
              const Text(
                'Elige una demo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.lock_open),
                label: const Text('Permisos'),
                onPressed: () => _abrir(context, const PantallaPermisos()),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.circle),
                label: const Text('Bolita (valores X, Y, Z)'),
                onPressed: () => _abrir(context, const PantallaBolita()),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.face),
                label: const Text('Muñequito (agítame)'),
                onPressed: () => _abrir(context, const PantallaMuneco()),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.threesixty),
                label: const Text('Giroscopio (gira el celular)'),
                onPressed: () => _abrir(context, const PantallaGiroscopio()),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.elderly),
                label: const Text('Detector de caídas'),
                onPressed: () => _abrir(context, const PantallaCaidas()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
