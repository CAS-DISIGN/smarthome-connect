import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appareil.dart';

class SeegScreen extends StatefulWidget {
  final List<Appareil> appareils;
  const SeegScreen({super.key, required this.appareils});

  @override
  State<SeegScreen> createState() => _SeegScreenState();
}

class _SeegScreenState extends State<SeegScreen> {
  final _controleur = TextEditingController();
  double _unitesSaisies = 0;
  double _unitesRestantes = 0;
  bool _dejaSaisi = false;

  static const double _heuresParJour = 6.0;

  @override
  void initState() {
    super.initState();
    _chargerUnites();
  }

  Future<void> _chargerUnites() async {
    final prefs = await SharedPreferences.getInstance();
    final valeur = prefs.getDouble('unites_seeg') ?? 0;
    setState(() {
      _unitesRestantes = valeur;
      _unitesSaisies = valeur;
      _dejaSaisi = valeur > 0;
      if (valeur > 0) _controleur.text = valeur.toStringAsFixed(0);
    });
  }

  Future<void> _sauvegarderUnites(double valeur) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('unites_seeg', valeur);
  }

  void _validerSaisie() {
    final valeur = double.tryParse(_controleur.text.trim());
    if (valeur == null || valeur <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre un nombre valide de kWh')),
      );
      return;
    }
    setState(() {
      _unitesRestantes = valeur;
      _unitesSaisies = valeur;
      _dejaSaisi = true;
    });
    _sauvegarderUnites(valeur);
    FocusScope.of(context).unfocus();
  }

  double get _consoJournaliere {
    final allumes = widget.appareils.where((a) => a.estAllume);
    final totalWatts = allumes.fold(0.0, (sum, a) => sum + a.watts);
    return (totalWatts * _heuresParJour) / 1000;
  }

  double get _joursRestants {
    if (_consoJournaliere <= 0) return double.infinity;
    return _unitesRestantes / _consoJournaliere;
  }

  List<Appareil> get _appareilsParConso {
    final liste = [...widget.appareils];
    liste.sort((a, b) => b.watts.compareTo(a.watts));
    return liste;
  }

  List<String> get _suggestions {
    final suggestions = <String>[];
    final jours = _joursRestants;

    if (jours.isInfinite) {
      suggestions.add('✅ Aucun appareil allumé — consommation nulle.');
      return suggestions;
    }

    if (jours < 7) {
      suggestions.add('🚨 Tes unités finissent dans moins d\'une semaine !');
    } else if (jours < 14) {
      suggestions.add('⚠️ Attention : moins de 2 semaines d\'autonomie.');
    }

    final plusGros = widget.appareils
        .where((a) => a.estAllume)
        .fold<Appareil?>(null, (max, a) =>
            max == null || a.watts > max.watts ? a : max);

    if (plusGros != null) {
      final gainJours = (plusGros.watts * _heuresParJour / 1000) /
          _consoJournaliere *
          jours;
      suggestions.add(
        '💡 Éteindre "${plusGros.nom}" (${plusGros.watts.toInt()} W) '
        'te ferait gagner environ ${gainJours.toStringAsFixed(0)} jours.',
      );
    }

    if (_consoJournaliere > 3) {
      suggestions.add(
          '🌿 Active le Mode Éco pour éteindre tous les appareils d\'un coup.');
    }

    return suggestions;
  }

  Color _couleurJauge() {
    if (_unitesSaisies <= 0) return Colors.grey;
    final ratio = _unitesRestantes / _unitesSaisies;
    if (ratio > 0.5) return Colors.green;
    if (ratio > 0.25) return Colors.orange;
    return Colors.red;
  }

  String _labelJours() {
    final j = _joursRestants;
    if (j.isInfinite) return '∞ jours';
    if (j >= 30) return '${j.toStringAsFixed(0)} jours';
    if (j >= 1) return '${j.toStringAsFixed(1)} jours';
    return '${(j * 24).toStringAsFixed(0)} heures';
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _unitesSaisies > 0
        ? (_unitesRestantes / _unitesSaisies).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestion unités SEEG')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saisie unités
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Unités disponibles au compteur',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controleur,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de kWh',
                              suffixText: 'kWh',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _validerSaisie,
                          child: const Text('Valider'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (_dejaSaisi) ...[
              const SizedBox(height: 16),

              // Jauge
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Unités restantes',
                              style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${_unitesRestantes.toStringAsFixed(1)} kWh',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _couleurJauge(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 20,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _couleurJauge()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // CORRECTION BUG N°1 : Expanded sur chaque colonne
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Conso. journalière estimée',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                                Text(
                                  '${_consoJournaliere.toStringAsFixed(2)} kWh/jour',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Autonomie estimée',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                                Text(
                                  _labelJours(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: _couleurJauge(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Suggestions
              if (_suggestions.isNotEmpty) ...[
                const Text('Suggestions',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ..._suggestions.map((s) => Card(
                      color: const Color(0xFFFFF8E1),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(s,
                            style: const TextStyle(fontSize: 14)),
                      ),
                    )),
                const SizedBox(height: 16),
              ],

              // Top consommateurs
              const Text('Top consommateurs',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: _appareilsParConso.map((a) {
                    final consoJour = (a.watts * _heuresParJour) / 1000;
                    return ListTile(
                      leading: Icon(
                        a.icone,
                        color:
                            a.estAllume ? Colors.amber : Colors.grey,
                      ),
                      title: Text(a.nom),
                      subtitle: Text(a.piece),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${a.watts.toInt()} W',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text(
                              '${consoJour.toStringAsFixed(2)} kWh/j',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }
}