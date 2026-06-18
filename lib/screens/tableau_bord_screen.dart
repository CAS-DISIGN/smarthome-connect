import 'package:flutter/material.dart';
import '../models/appareil.dart';

class TableauBordScreen extends StatelessWidget {
  final List<Appareil> appareils;

  const TableauBordScreen({super.key, required this.appareils});

  // Consommation estimée en watts par type d'icône
  double _consommationEstimee() {
  double total = 0;
  for (final a in appareils) {
    if (!a.estAllume) {
      continue;
    }
    final nom = a.nom.toLowerCase();
    if (nom.contains('lampe')) {
      total += 10;
    } else if (nom.contains('climatiseur')) {
      total += 1500;
    } else if (nom.contains('chauffage')) {
      total += 2000;
    } else if (nom.contains('prise')) {
      total += 100;
    } else {
      total += 50;
    }
  }
  return total;
}

  Map<String, Map<String, int>> _statsParPiece() {
    final Map<String, Map<String, int>> stats = {};
    for (final a in appareils) {
      stats.putIfAbsent(a.piece, () => {'total': 0, 'allumes': 0});
      stats[a.piece]!['total'] = stats[a.piece]!['total']! + 1;
      if (a.estAllume) {
        stats[a.piece]!['allumes'] = stats[a.piece]!['allumes']! + 1;
      }
    }
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final allumes = appareils.where((a) => a.estAllume).length;
    final eteints = appareils.length - allumes;
    final consommation = _consommationEstimee();
    final statsParPiece = _statsParPiece();
    final maxTotal = statsParPiece.values
        .map((s) => s['total']!)
        .fold(0, (a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Résumé visuel ---
            const Text(
              'Résumé',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CarteResume(
                    icone: Icons.power,
                    couleur: Colors.green,
                    valeur: '$allumes',
                    label: 'Allumés',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CarteResume(
                    icone: Icons.power_off,
                    couleur: Colors.grey,
                    valeur: '$eteints',
                    label: 'Éteints',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CarteResume(
                    icone: Icons.bolt,
                    couleur: Colors.orange,
                    valeur: consommation >= 1000
                        ? '${(consommation / 1000).toStringAsFixed(1)} kW'
                        : '${consommation.toInt()} W',
                    label: 'Conso.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Graphique en barres ---
            const Text(
              'Répartition par pièce',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...statsParPiece.entries.map((entry) {
              final piece = entry.key;
              final total = entry.value['total']!;
              final allumesP = entry.value['allumes']!;
              final ratio = maxTotal > 0 ? total / maxTotal : 0.0;
              final ratioAllumes = total > 0 ? allumesP / total : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          piece,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '$allumesP/$total allumés',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        // Barre de fond (total)
                        Container(
                          height: 24,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        // Barre totale proportionnelle
                        FractionallySizedBox(
                          widthFactor: ratio.toDouble(),
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        // Barre allumés
                        FractionallySizedBox(
                          widthFactor: ratio * ratioAllumes,
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // --- Statistiques par pièce ---
            const Text(
              'Détail par pièce',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...statsParPiece.entries.map((entry) {
              final piece = entry.key;
              final total = entry.value['total']!;
              final allumesP = entry.value['allumes']!;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: allumesP > 0
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                    child: Text(
                      '$allumesP',
                      style: TextStyle(
                        color: allumesP > 0 ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(piece),
                  subtitle: Text('$total appareil${total > 1 ? 's' : ''}'),
                  trailing: Text(
                    allumesP > 0 ? '🟢 Actif' : '⚫ Inactif',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CarteResume extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final String valeur;
  final String label;

  const _CarteResume({
    required this.icone,
    required this.couleur,
    required this.valeur,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icone, color: couleur, size: 28),
            const SizedBox(height: 8),
            Text(
              valeur,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: couleur,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}