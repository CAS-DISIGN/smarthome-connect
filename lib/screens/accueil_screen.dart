import 'package:flutter/material.dart';
import '../models/appareil.dart';
import '../widgets/carte_appareil.dart';
import 'ajout_screen.dart';

class AccueilScreen extends StatefulWidget {
  const AccueilScreen({super.key});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  final List<Appareil> _appareils = appareilsMock();
  bool _modeEcoActif = false;

  void _toggleAppareil(String id) {
    setState(() {
      final appareil = _appareils.firstWhere((a) => a.id == id);
      appareil.estAllume = !appareil.estAllume;
    });
  }

  void _supprimerAppareil(String id) {
    setState(() => _appareils.removeWhere((a) => a.id == id));
  }

  Future<void> _ouvrirAjout() async {
    final nouvelAppareil = await Navigator.push<Appareil>(
      context,
      MaterialPageRoute(builder: (context) => const AjoutScreen()),
    );

    if (nouvelAppareil != null) {
      setState(() => _appareils.add(nouvelAppareil));
    }
  }

  void _toggleModeEco() {
    setState(() {
      _modeEcoActif = !_modeEcoActif;
      if (_modeEcoActif) {
        for (final appareil in _appareils) {
          appareil.estAllume = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartHome Connect')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.green.shade50,
              child: SwitchListTile(
                title: const Text('Mode Éco-Responsable'),
                subtitle: const Text('Éteint tous les appareils et verrouille les interrupteurs'),
                secondary: const Icon(Icons.eco, color: Colors.green),
                value: _modeEcoActif,
                onChanged: (_) => _toggleModeEco(),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
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
                  modeEcoActif: _modeEcoActif,
                  onToggle: () => _toggleAppareil(appareil.id),
                  onDelete: () => _supprimerAppareil(appareil.id),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ouvrirAjout,
        child: const Icon(Icons.add),
      ),
    );
  }
}