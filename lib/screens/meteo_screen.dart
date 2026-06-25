import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/appareil.dart';

class MeteoScreen extends StatefulWidget {
  final List<Appareil> appareils;
  const MeteoScreen({super.key, required this.appareils});

  @override
  State<MeteoScreen> createState() => _MeteoScreenState();
}

class _MeteoScreenState extends State<MeteoScreen> {
  final String _apiKey = 'e63bcbf12bbfcc0ad98def1e750190a4';
  final String _ville = 'Libreville';

  bool _chargement = true;
  String? _erreur;
  String _description = '';
  double _temperature = 0;
  double _ressenti = 0;
  int _humidite = 0;
  double _vent = 0;
  String _iconeCode = '01d';
  String _nomVille = '';

  @override
  void initState() {
    super.initState();
    _chargerMeteo();
  }

  Future<void> _chargerMeteo() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?q=$_ville&appid=$_apiKey&units=metric&lang=fr',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _description = data['weather'][0]['description'];
          _temperature = (data['main']['temp'] as num).toDouble();
          _ressenti = (data['main']['feels_like'] as num).toDouble();
          _humidite = data['main']['humidity'];
          _vent = (data['wind']['speed'] as num).toDouble();
          _iconeCode = data['weather'][0]['icon'];
          _nomVille = data['name'];
          _chargement = false;
        });
      } else {
        setState(() {
          _erreur = 'Erreur ${response.statusCode}';
          _chargement = false;
        });
      }
    } catch (e) {
      setState(() {
        _erreur = 'Pas de connexion internet';
        _chargement = false;
      });
    }
  }

  List<Map<String, String>> _conseilsDynamiques() {
    final conseils = <Map<String, String>>[];
    final appareils = widget.appareils;

    final climatiseurs = appareils.where((a) =>
        a.nom.toLowerCase().contains('clim') || a.icone == Icons.ac_unit);
    final chauffages = appareils.where((a) =>
        a.nom.toLowerCase().contains('chauffage') || a.icone == Icons.thermostat);

    if (_temperature >= 30) {
      if (climatiseurs.any((a) => !a.estAllume)) {
        final noms = climatiseurs.where((a) => !a.estAllume).map((a) => a.nom).join(', ');
        conseils.add({'icone': '🥵', 'couleur': 'rouge', 'texte': 'Il fait ${_temperature.toStringAsFixed(0)}°C — allume le climatiseur : $noms'});
      }
      if (chauffages.any((a) => a.estAllume)) {
        final noms = chauffages.where((a) => a.estAllume).map((a) => a.nom).join(', ');
        conseils.add({'icone': '🔥', 'couleur': 'rouge', 'texte': 'Éteins le chauffage par cette chaleur : $noms'});
      }
      conseils.add({'icone': '🌿', 'couleur': 'vert', 'texte': 'Active le Mode Éco pour réduire ta consommation.'});
    } else if (_temperature >= 25) {
      if (chauffages.any((a) => a.estAllume)) {
        final noms = chauffages.where((a) => a.estAllume).map((a) => a.nom).join(', ');
        conseils.add({'icone': '♨️', 'couleur': 'orange', 'texte': 'Il fait chaud — éteins le chauffage : $noms'});
      }
      if (climatiseurs.isNotEmpty) {
        conseils.add({'icone': '❄️', 'couleur': 'bleu', 'texte': 'Température élevée — le climatiseur peut être utile.'});
      }
    } else if (_temperature < 18) {
      if (chauffages.any((a) => !a.estAllume)) {
        final noms = chauffages.where((a) => !a.estAllume).map((a) => a.nom).join(', ');
        conseils.add({'icone': '🧥', 'couleur': 'bleu', 'texte': 'Il fait frais — pense à allumer : $noms'});
      }
      if (climatiseurs.any((a) => a.estAllume)) {
        final noms = climatiseurs.where((a) => a.estAllume).map((a) => a.nom).join(', ');
        conseils.add({'icone': '❄️', 'couleur': 'orange', 'texte': 'Éteins le climatiseur par ce temps frais : $noms'});
      }
    } else {
      conseils.add({'icone': '✅', 'couleur': 'vert', 'texte': 'Température agréable (${_temperature.toStringAsFixed(0)}°C) — aucun appareil de climatisation nécessaire.'});
    }

    if (_humidite > 80) {
      conseils.add({'icone': '💧', 'couleur': 'bleu', 'texte': 'Humidité élevée ($_humidite%) — aère les pièces si possible.'});
    }

    if (conseils.isEmpty) {
      conseils.add({'icone': '✅', 'couleur': 'vert', 'texte': 'Tout est bien configuré pour la météo actuelle.'});
    }

    return conseils;
  }

  Color _couleurConseil(String couleur) {
    switch (couleur) {
      case 'rouge': return Colors.red.shade50;
      case 'orange': return Colors.orange.shade50;
      case 'bleu': return const Color(0xFFE3F2FD);
      default: return Colors.green.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Météo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: _chargerMeteo,
          ),
        ],
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(_erreur!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _chargerMeteo,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Carte principale
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text(_nomVille,
                                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Image.network(
                                'https://openweathermap.org/img/wn/$_iconeCode@2x.png',
                                width: 80, height: 80,
                              ),
                              Text(
                                '${_temperature.toStringAsFixed(1)}°C',
                                style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                              ),
                              Text(
                                _description.isNotEmpty
                                    ? _description[0].toUpperCase() + _description.substring(1)
                                    : '',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Carte détails
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            children: [
                              _lignDetail(Icons.thermostat, 'Ressenti', '${_ressenti.toStringAsFixed(1)}°C'),
                              const Divider(),
                              _lignDetail(Icons.water_drop, 'Humidité', '$_humidite%'),
                              const Divider(),
                              _lignDetail(Icons.air, 'Vent', '${_vent.toStringAsFixed(1)} m/s'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Conseils dynamiques
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Conseils personnalisés',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      ..._conseilsDynamiques().map((conseil) => Card(
                            color: _couleurConseil(conseil['couleur']!),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Text(conseil['icone']!, style: const TextStyle(fontSize: 24)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(conseil['texte']!, style: const TextStyle(fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
    );
  }

  Widget _lignDetail(IconData icone, String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icone, color: const Color(0xFF1565C0)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Text(valeur, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}