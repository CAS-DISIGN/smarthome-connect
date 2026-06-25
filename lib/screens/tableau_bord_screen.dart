import 'package:flutter/material.dart';
import '../models/appareil.dart';

class TableauBordScreen extends StatelessWidget {
  final List<Appareil> appareils;

  const TableauBordScreen({super.key, required this.appareils});

  // Consommation réelle basée sur le champ watts
  double get _consoTotaleWatts =>
      appareils.where((a) => a.estAllume).fold(0.0, (s, a) => s + a.watts);

  // Appareils triés par consommation décroissante
  List<Appareil> get _topConsommateurs {
    final liste = [...appareils];
    liste.sort((a, b) => b.watts.compareTo(a.watts));
    return liste;
  }

  Map<String, Map<String, dynamic>> _statsParPiece() {
    final Map<String, Map<String, dynamic>> stats = {};
    for (final a in appareils) {
      stats.putIfAbsent(a.piece, () => {'total': 0, 'allumes': 0, 'watts': 0.0});
      stats[a.piece]!['total'] = stats[a.piece]!['total'] + 1;
      if (a.estAllume) {
        stats[a.piece]!['allumes'] = stats[a.piece]!['allumes'] + 1;
        stats[a.piece]!['watts'] = stats[a.piece]!['watts'] + a.watts;
      }
    }
    return stats;
  }

  // Période de la journée
  String get _periode {
    final h = DateTime.now().hour;
    if (h >= 6 && h < 12) return 'Matin';
    if (h >= 12 && h < 18) return 'Après-midi';
    if (h >= 18 && h < 22) return 'Soir';
    return 'Nuit';
  }

  IconData get _iconesPeriode {
    switch (_periode) {
      case 'Matin': return Icons.wb_twilight;
      case 'Après-midi': return Icons.wb_sunny;
      case 'Soir': return Icons.nights_stay;
      default: return Icons.bedtime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allumes = appareils.where((a) => a.estAllume).length;
    final eteints = appareils.length - allumes;
    final conso = _consoTotaleWatts;
    final statsParPiece = _statsParPiece();
    final top = _topConsommateurs;
    final maxWatts = top.isNotEmpty ? top.first.watts : 1.0;
    final maxTotal = statsParPiece.values
        .map((s) => s['total'] as int)
        .fold(0, (a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // --- Résumé ---
            const Text('Résumé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _CarteResume(icone: Icons.power, couleur: Colors.green, valeur: '$allumes', label: 'Allumés')),
                const SizedBox(width: 12),
                Expanded(child: _CarteResume(icone: Icons.power_off, couleur: Colors.grey, valeur: '$eteints', label: 'Éteints')),
                const SizedBox(width: 12),
                Expanded(child: _CarteResume(
                  icone: Icons.bolt,
                  couleur: Colors.orange,
                  valeur: conso >= 1000
                      ? '${(conso / 1000).toStringAsFixed(1)} kW'
                      : '${conso.toInt()} W',
                  label: 'Conso.',
                )),
              ],
            ),
            const SizedBox(height: 24),

            // --- Période actuelle ---
            Card(
              color: const Color(0xFFE8F5E9),
              child: ListTile(
                leading: Icon(_iconesPeriode, color: Colors.green.shade700, size: 32),
                title: Text('Période actuelle : $_periode',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  allumes > 0
                      ? '$allumes appareil${allumes > 1 ? 's' : ''} allumé${allumes > 1 ? 's' : ''} — ${conso.toInt()} W consommés'
                      : 'Aucun appareil allumé en ce moment',
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Top consommateurs ---
            const Text('Top consommateurs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: top.map((a) {
                  final ratio = maxWatts > 0 ? a.watts / maxWatts : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(a.icone, color: a.estAllume ? Colors.amber : Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(a.nom, style: const TextStyle(fontWeight: FontWeight.w500))),
                            Text('${a.watts.toInt()} W',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: a.watts >= 1000 ? Colors.red : Colors.orange,
                                )),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              a.estAllume ? Colors.orange : Colors.grey.shade400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${a.piece} · ${((a.watts * 6) / 1000).toStringAsFixed(2)} kWh/jour estimé · ${a.estAllume ? "🟢 Allumé" : "⚫ Éteint"}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        if (a != top.last) const Divider(height: 16),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // --- Répartition par pièce ---
            const Text('Répartition par pièce', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...statsParPiece.entries.map((entry) {
              final piece = entry.key;
              final total = entry.value['total'] as int;
              final allumesP = entry.value['allumes'] as int;
              final wattsP = entry.value['watts'] as double;
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
                        Text(piece, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '$allumesP/$total allumés · ${wattsP.toInt()} W',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        Container(height: 24, width: double.infinity,
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8))),
                        FractionallySizedBox(
                          widthFactor: ratio,
                          child: Container(height: 24,
                              decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8))),
                        ),
                        FractionallySizedBox(
                          widthFactor: ratio * ratioAllumes,
                          child: Container(height: 24,
                              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8))),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // --- Détail par pièce ---
            const Text('Détail par pièce', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...statsParPiece.entries.map((entry) {
              final piece = entry.key;
              final total = entry.value['total'] as int;
              final allumesP = entry.value['allumes'] as int;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: allumesP > 0 ? Colors.green.shade100 : Colors.grey.shade200,
                    child: Text('$allumesP',
                        style: TextStyle(color: allumesP > 0 ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(piece),
                  subtitle: Text('$total appareil${total > 1 ? 's' : ''}'),
                  trailing: Text(allumesP > 0 ? '🟢 Actif' : '⚫ Inactif', style: const TextStyle(fontSize: 13)),
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

  const _CarteResume({required this.icone, required this.couleur, required this.valeur, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icone, color: couleur, size: 28),
            const SizedBox(height: 8),
            Text(valeur, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: couleur)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}