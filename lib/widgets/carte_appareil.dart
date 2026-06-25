import 'package:flutter/material.dart';
import '../models/appareil.dart';
import '../screens/detail_appareil_screen.dart';

class CarteAppareil extends StatelessWidget {
  final Appareil appareil;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final bool modeEcoActif;
  final IconData iconePiece;

  const CarteAppareil({
    super.key,
    required this.appareil,
    required this.iconePiece,
    this.onToggle,
    this.onDelete,
    this.modeEcoActif = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailAppareilScreen(appareil: appareil),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: CircleAvatar(
            backgroundColor: appareil.estAllume
                ? Colors.green.shade100
                : Colors.grey.shade200,
            child: Icon(
              appareil.icone,
              color: appareil.estAllume ? Colors.green : Colors.grey,
            ),
          ),
          title: Text(
            appareil.nom,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Row(
            children: [
              Icon(iconePiece, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Flexible(
                child: Text(appareil.piece, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 6),
              Text(
                '${appareil.watts.toInt()} W',
                style: TextStyle(
                  fontSize: 12,
                  color: appareil.watts >= 1000
                      ? Colors.red.shade400
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: appareil.estAllume,
                activeThumbColor: Colors.green,
                onChanged: modeEcoActif ? null : (_) => onToggle?.call(),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
