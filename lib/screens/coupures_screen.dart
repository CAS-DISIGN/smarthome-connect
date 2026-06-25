import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CoupuresScreen extends StatefulWidget {
  const CoupuresScreen({super.key});

  @override
  State<CoupuresScreen> createState() => _CoupuresScreenState();
}

class _CoupuresScreenState extends State<CoupuresScreen> {
  List<Map<String, dynamic>> _coupures = [];
  final _controleurQuartier = TextEditingController();

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('coupures');
    final quartier = prefs.getString('quartier') ?? '';
    setState(() {
      if (data != null) {
        final List decoded = jsonDecode(data);
        _coupures = decoded.cast<Map<String, dynamic>>();
      }
      _controleurQuartier.text = quartier;
    });
  }

  Future<void> _sauvegarder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('coupures', jsonEncode(_coupures));
    await prefs.setString('quartier', _controleurQuartier.text.trim());
  }

  void _ajouterCoupure() {
    String jourSelectionne = 'Lundi';
    TimeOfDay heureDebut = const TimeOfDay(hour: 18, minute: 0);
    TimeOfDay heureFin = const TimeOfDay(hour: 21, minute: 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Ajouter une coupure habituelle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Jour de la semaine'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: jourSelectionne,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche']
                      .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                      .toList(),
                  onChanged: (v) => setStateDialog(() => jourSelectionne = v!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Début'),
                          const SizedBox(height: 4),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(heureDebut.format(context)),
                            onPressed: () async {
                              final h = await showTimePicker(
                                context: context,
                                initialTime: heureDebut,
                              );
                              if (h != null) setStateDialog(() => heureDebut = h);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fin'),
                          const SizedBox(height: 4),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(heureFin.format(context)),
                            onPressed: () async {
                              final h = await showTimePicker(
                                context: context,
                                initialTime: heureFin,
                              );
                              if (h != null) setStateDialog(() => heureFin = h);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _coupures.add({
                    'jour': jourSelectionne,
                    'debut': '${heureDebut.hour}:${heureDebut.minute.toString().padLeft(2, '0')}',
                    'fin': '${heureFin.hour}:${heureFin.minute.toString().padLeft(2, '0')}',
                    'actif': true,
                  });
                });
                _sauvegarder();
                Navigator.pop(context);
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _supprimerCoupure(int index) {
    setState(() => _coupures.removeAt(index));
    _sauvegarder();
  }

  void _toggleCoupure(int index) {
    setState(() => _coupures[index]['actif'] = !(_coupures[index]['actif'] as bool));
    _sauvegarder();
  }

  // Vérifie si une coupure est prévue aujourd'hui ou dans les prochaines 24h
  Map<String, dynamic>? get _prochaineAlerte {
    final maintenant = DateTime.now();
    final joursMap = {
      'Lundi': 1, 'Mardi': 2, 'Mercredi': 3, 'Jeudi': 4,
      'Vendredi': 5, 'Samedi': 6, 'Dimanche': 7,
    };

    Map<String, dynamic>? prochaine;
    Duration? plusPetitEcart;

    for (final c in _coupures) {
      if (!(c['actif'] as bool)) continue;
      final jourCible = joursMap[c['jour']] ?? 1;
      final parts = (c['debut'] as String).split(':');
      final heure = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      var diff = jourCible - maintenant.weekday;
      if (diff < 0) diff += 7;
      if (diff == 0 && (maintenant.hour > heure || (maintenant.hour == heure && maintenant.minute >= minute))) {
        diff = 7;
      }

      final cibleDate = maintenant.add(Duration(days: diff));
      final cibleDatetime = DateTime(cibleDate.year, cibleDate.month, cibleDate.day, heure, minute);
      final ecart = cibleDatetime.difference(maintenant);

      if (plusPetitEcart == null || ecart < plusPetitEcart) {
        plusPetitEcart = ecart;
        prochaine = {...c, 'dans': ecart};
      }
    }

    return prochaine;
  }

  String _formatDuree(Duration d) {
    if (d.inDays > 0) return 'dans ${d.inDays} jour${d.inDays > 1 ? 's' : ''}';
    if (d.inHours > 0) return 'dans ${d.inHours}h${d.inMinutes.remainder(60).toString().padLeft(2, '0')}';
    return 'dans ${d.inMinutes} minutes';
  }

  @override
  Widget build(BuildContext context) {
    final alerte = _prochaineAlerte;

    return Scaffold(
      appBar: AppBar(title: const Text('Alertes coupures SEEG')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Quartier
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ton quartier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controleurQuartier,
                            decoration: const InputDecoration(
                              labelText: 'Ex: Libreville Centre, Owendo...',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _sauvegarder,
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Prochaine alerte
            if (alerte != null) ...[
              Card(
                color: const Color(0xFFFFF3E0),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Prochaine coupure prévue',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(
                              '${alerte['jour']} · ${alerte['debut']} → ${alerte['fin']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              _formatDuree(alerte['dans'] as Duration),
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.orange, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: const Color(0xFFE3F2FD),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('💡 Conseils avant la coupure',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('• Charge ton téléphone et ta batterie externe'),
                      Text('• Sauvegarde ton travail sur l\'ordinateur'),
                      Text('• Prépare une lampe torche ou une bougie'),
                      Text('• Active le Mode Éco pour économiser les unités'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Liste des coupures
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Coupures habituelles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                  onPressed: _ajouterCoupure,
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_coupures.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.power_off, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune coupure enregistrée\nAppuie sur "Ajouter" pour en créer une',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_coupures.length, (i) {
                final c = _coupures[i];
                final actif = c['actif'] as bool;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.bolt,
                      color: actif ? Colors.orange : Colors.grey,
                    ),
                    title: Text(
                      c['jour'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: actif ? null : Colors.grey,
                      ),
                    ),
                    subtitle: Text('${c['debut']} → ${c['fin']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: actif,
                          onChanged: (_) => _toggleCoupure(i),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _supprimerCoupure(i),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterCoupure,
        tooltip: 'Ajouter une coupure',
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _controleurQuartier.dispose();
    super.dispose();
  }
}