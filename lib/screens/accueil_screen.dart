import 'package:flutter/material.dart';
import '../models/appareil.dart';
import '../widgets/carte_appareil.dart';

class AccueilScreen extends StatefulWidget {
  const AccueilScreen({super.key});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  final List<Appareil> _appareils = appareilsMock();

  void _toggleAppareil(String id) {
    setState(() {
      final appareil = _appareils.firstWhere((a) => a.id == id);
      appareil.estAllume = !appareil.estAllume;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartHome Connect'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mes appareils connectés',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _appareils.length,
              itemBuilder: (context, index) {
                final appareil = _appareils[index];
                return CarteAppareil(
                  appareil: appareil,
                  onToggle: () => _toggleAppareil(appareil.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}