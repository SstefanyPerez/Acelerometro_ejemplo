import 'package:acelerometro_ejemplo/pantalla_bolita.dart';
import 'package:acelerometro_ejemplo/pantalla_caidas.dart';
import 'package:acelerometro_ejemplo/pantalla_muneco.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Demo Acelerómetro',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const MenuPage(),
    );
  }
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo Acelerómetro'), centerTitle: true),
      body: Center(
        child: Padding(
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
                icon: const Icon(Icons.circle),
                label: const Text('Bolita (valores X, Y, Z)'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PantallaBolita()),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.face),
                label: const Text('Muñequito (agítame)'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PantallaMuneco()),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.elderly),
                label: const Text('Detector de caídas'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PantallaCaidas()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}