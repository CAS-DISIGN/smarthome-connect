import 'package:flutter/material.dart';
import '../models/appareil.dart';

class AjoutScreen extends StatefulWidget {
  const AjoutScreen({super.key});

  @override
  State<AjoutScreen> createState() => _AjoutScreenState();
}

class _AjoutScreenState extends State<AjoutScreen> {
  final _controleurNom = TextEditingController();
  final _controleurWatts = TextEditingController();
  String _pieceSelectionnee = 'Salon';
  String _typeSelectionne = 'Lampe';

  final List<String> _pieces = ['Salon', 'Chambre', 'Cuisine', 'Salle de bain', 'Bureau'];

  // Watts par défaut selon le type
  final Map<String, IconData> _typesIcones = {
    'Lampe': Icons.lightbulb,
    'Climatiseur': Icons.ac_unit,
    'Prise': Icons.power,
    'Volet': Icons.blinds,
    'Chauffage': Icons.thermostat,
  };

  final Map<String, double> _typesWatts = {
    'Lampe': 15,
    'Climatiseur': 1500,
    'Prise': 120,
    'Volet': 50,
    'Chauffage': 2000,
  };

  @override
  void initState() {
    super.initState();
    _controleurWatts.text = _typesWatts[_typeSelectionne]!.toInt().toString();
  }

  void _valider() {
    final nom = _controleurNom.text.trim();
    if (nom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Merci de donner un nom à l'appareil")),
      );
      return;
    }

    final watts = double.tryParse(_controleurWatts.text.trim()) ?? _typesWatts[_typeSelectionne]!;

    final nouvelAppareil = Appareil(
      id: DateTime.now().toIso8601String(),
      nom: nom,
      piece: _pieceSelectionnee,
      icone: _typesIcones[_typeSelectionne]!,
      watts: watts,
    );

    Navigator.pop(context, nouvelAppareil);
  }

  @override
  void dispose() {
    _controleurNom.dispose();
    _controleurWatts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un appareil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controleurNom,
              decoration: const InputDecoration(
                labelText: "Nom de l'appareil",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _typeSelectionne,
              decoration: const InputDecoration(
                labelText: "Type d'appareil",
                border: OutlineInputBorder(),
              ),
              items: _typesIcones.keys
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (valeur) {
                setState(() {
                  _typeSelectionne = valeur!;
                  // Met à jour les watts par défaut selon le type choisi
                  _controleurWatts.text = _typesWatts[valeur]!.toInt().toString();
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _pieceSelectionnee,
              decoration: const InputDecoration(
                labelText: 'Pièce',
                border: OutlineInputBorder(),
              ),
              items: _pieces
                  .map((piece) => DropdownMenuItem(value: piece, child: Text(piece)))
                  .toList(),
              onChanged: (valeur) => setState(() => _pieceSelectionnee = valeur!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controleurWatts,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Consommation (Watts)',
                suffixText: 'W',
                border: OutlineInputBorder(),
                helperText: 'Valeur pré-remplie selon le type, modifiable',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _valider,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text("Ajouter l'appareil"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}