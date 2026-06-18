
import 'package:flutter/material.dart';
import '../models/appareil.dart';
import '../widgets/carte_appareil.dart';
import 'ajout_screen.dart';
import 'tableau_bord_screen.dart';
import 'simulation_screen.dart';


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

  IconData _iconeParPiece(String piece) {
    switch (piece) {
      case 'Salon': return Icons.weekend;
      case 'Chambre': return Icons.bed;
      case 'Cuisine': return Icons.kitchen;
      case 'Salle de bain': return Icons.bathtub;
      case 'Bureau': return Icons.computer;
      default: return Icons.home;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text('SmartHome Connect'),
  actions: [
    IconButton(
      icon: const Icon(Icons.map),
      tooltip: 'Simulation 2D',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SimulationScreen(appareils: _appareils),
          ),
        );
      },
    ),
    IconButton(
      icon: const Icon(Icons.dashboard),
      tooltip: 'Tableau de bord',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TableauBordScreen(appareils: _appareils),
          ),
        );
      },
    ),
  ],
),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mes appareils connectés',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_appareils.where((a) => a.estAllume).length}/${_appareils.length} allumés',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _appareils.length,
              itemBuilder: (context, index) {
                final appareil = _appareils[index];
                return CarteAppareil(
                  appareil: appareil,
                   iconePiece: _iconeParPiece(appareil.piece),
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