import 'package:flutter/material.dart';
import '../models/appareil.dart';

class DetailAppareilScreen extends StatelessWidget {
  final Appareil appareil;

  const DetailAppareilScreen({super.key, required this.appareil});

  // Historique simulé basé sur le nom de l'appareil
  List<Map<String, dynamic>> _historique() {
    final now = DateTime.now();
    return [
      {
        'date': now.subtract(const Duration(hours: 1)),
        'action': 'Allumé',
        'icone': Icons.power,
        'couleur': Colors.green,
      },
      {
        'date': now.subtract(const Duration(hours: 3)),
        'action': 'Éteint',
        'icone': Icons.power_off,
        'couleur': Colors.grey,
      },
      {
        'date': now.subtract(const Duration(hours: 6)),
        'action': 'Allumé',
        'icone': Icons.power,
        'couleur': Colors.green,
      },
      {
        'date': now.subtract(const Duration(hours: 9)),
        'action': 'Éteint',
        'icone': Icons.power_off,
        'couleur': Colors.grey,
      },
      {
        'date': now.subtract(const Duration(days: 1)),
        'action': 'Allumé',
        'icone': Icons.power,
        'couleur': Colors.green,
      },
      {
        'date': now.subtract(const Duration(days: 1, hours: 4)),
        'action': 'Éteint',
        'icone': Icons.power_off,
        'couleur': Colors.grey,
      },
      {
        'date': now.subtract(const Duration(days: 2)),
        'action': 'Allumé',
        'icone': Icons.power,
        'couleur': Colors.green,
      },
      {
        'date': now.subtract(const Duration(days: 2, hours: 5)),
        'action': 'Éteint',
        'icone': Icons.power_off,
        'couleur': Colors.grey,
      },
    ];
  }

  String _formaterDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier à ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
    return 'Il y a ${diff.inDays} jours à ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
  }

  // Consommation estimée sur 24h (6h d'utilisation)
  double get _consoJournaliere => (appareil.watts * 6) / 1000;

  // Consommation estimée sur 30 jours
  double get _consoMensuelle => _consoJournaliere * 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(appareil.nom)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Carte état
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: appareil.estAllume
                          ? Colors.green.shade100
                          : Colors.grey.shade200,
                      child: Icon(
                        appareil.icone,
                        size: 36,
                        color: appareil.estAllume ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appareil.nom,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(appareil.piece,
                              style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: appareil.estAllume
                                  ? Colors.green.shade100
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              appareil.estAllume ? '🟢 Allumé' : '⚫ Éteint',
                              style: TextStyle(
                                color: appareil.estAllume
                                    ? Colors.green.shade700
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Carte consommation
            const Text('Consommation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ligneConso(
                      Icons.bolt,
                      'Puissance',
                      '${appareil.watts.toInt()} W',
                      Colors.orange,
                    ),
                    const Divider(),
                    _ligneConso(
                      Icons.today,
                      'Estimation journalière',
                      '${_consoJournaliere.toStringAsFixed(2)} kWh',
                      Colors.blue,
                    ),
                    const Divider(),
                    _ligneConso(
                      Icons.calendar_month,
                      'Estimation mensuelle',
                      '${_consoMensuelle.toStringAsFixed(1)} kWh',
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Conseil
            Card(
              color: appareil.watts >= 1000
                  ? Colors.red.shade50
                  : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Text(
                      appareil.watts >= 1000 ? '⚠️' : '✅',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        appareil.watts >= 1000
                            ? 'Appareil énergivore (${appareil.watts.toInt()} W) — limite son utilisation pour économiser tes unités SEEG.'
                            : 'Appareil économique (${appareil.watts.toInt()} W) — consommation raisonnable.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Historique simulé
            const Text('Historique d\'activité',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: _historique().map((event) {
                  final date = event['date'] as DateTime;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          (event['couleur'] as Color).withValues(alpha: 0.15),
                      child: Icon(
                        event['icone'] as IconData,
                        color: event['couleur'] as Color,
                        size: 20,
                      ),
                    ),
                    title: Text(event['action'] as String),
                    subtitle: Text(_formaterDate(date)),
                    dense: true,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ligneConso(IconData icone, String label, String valeur, Color couleur) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icone, color: couleur, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          Text(valeur,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: couleur)),
        ],
      ),
    );
  }
}