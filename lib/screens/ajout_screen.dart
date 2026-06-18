import 'package:flutter/material.dart';
import '../models/appareil.dart';

class AjoutScreen extends StatefulWidget {
  const AjoutScreen({super.key});

  @override
  State<AjoutScreen> createState() => _AjoutScreenState();
}

class _AjoutScreenState extends State<AjoutScreen> {
  final _controleurNom = TextEditingController();
  String _pieceSelectionnee = 'Salon';
  String _typeSelectionne = 'Lampe';

  final List<String> _pieces = ['Salon', 'Chambre', 'Cuisine', 'Salle de bain', 'Bureau'];

  final Map<String, IconData> _typesIcones = {
    'Lampe': Icons.lightbulb,
    'Climatiseur': Icons.ac_unit,
    'Prise': Icons.power,
    'Volet': Icons.blinds,
    'Chauffage': Icons.thermostat,
  };

  void _valider() {
    final nom = _controleurNom.text.trim();
    if (nom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Merci de donner un nom à l'appareil")),
      );
      return;
    }

    final nouvelAppareil = Appareil(
      id: DateTime.now().toIso8601String(),
      nom: nom,
      piece: _pieceSelectionnee,
      icone: _typesIcones[_typeSelectionne]!,
    );

    Navigator.pop(context, nouvelAppareil);
  }

  @override
  void dispose() {
    _controleurNom.dispose();
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
              onChanged: (valeur) => setState(() => _typeSelectionne = valeur!),
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