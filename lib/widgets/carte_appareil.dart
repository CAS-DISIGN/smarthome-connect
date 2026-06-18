import 'package:flutter/material.dart';
import '../models/appareil.dart';

class CarteAppareil extends StatelessWidget {
  final Appareil appareil;
  final VoidCallback? onToggle;

  const CarteAppareil({super.key, required this.appareil, this.onToggle});

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
        trailing: Switch(
          value: appareil.estAllume,
          onChanged: (_) => onToggle?.call(),
        ),
      ),
    );
  }
}