import 'package:flutter/material.dart';
import '../models/appareil.dart';

class CarteAppareil extends StatelessWidget {
  final Appareil appareil;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final bool modeEcoActif;

  const CarteAppareil({
    super.key,
    required this.appareil,
    this.onToggle,
    this.onDelete,
    this.modeEcoActif = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: Icon(
          appareil.icone,
          color: appareil.estAllume ? Colors.green : Colors.grey,
        ),
        title: Text(appareil.nom),
        subtitle: Text(appareil.piece),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: appareil.estAllume,
              onChanged: modeEcoActif ? null : (_) => onToggle?.call(),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}