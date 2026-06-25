import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/appareil.dart';
import '../widgets/carte_appareil.dart';
import 'ajout_screen.dart';
import 'tableau_bord_screen.dart';
import 'simulation_screen.dart';
import 'meteo_screen.dart';
import 'seeg_screen.dart';
import 'coupures_screen.dart';
import 'assistant_screen.dart';

import 'profil_screen.dart';

class AccueilScreen extends StatefulWidget {
  final Future<void> Function(ThemeMode) onChangerTheme;
  final ThemeMode themeMode;

  const AccueilScreen({
    super.key,
    required this.onChangerTheme,
    required this.themeMode,
  });

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  List<Appareil> _appareils = [];
  bool _modeEcoActif = false;
  bool _chargement = true;
  double _unitesSeeg = 0;
  String _filtrepiece = 'Tous'; // ← filtre actif

  @override
  void initState() {
    super.initState();
    _chargerAppareils();
    _chargerUnites();
  }

  Future<void> _chargerAppareils() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('appareils');
    setState(() {
      if (data != null) {
        final List decoded = jsonDecode(data);
        _appareils = decoded.map((e) => Appareil.fromJson(e)).toList();
      } else {
        _appareils = appareilsMock();
      }
      _chargement = false;
    });
    if (data == null) await _sauvegarderAppareils();
  }

  Future<void> _chargerUnites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _unitesSeeg = prefs.getDouble('unites_seeg') ?? 0);
  }

  Future<void> _sauvegarderAppareils() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_appareils.map((a) => a.toJson()).toList());
    await prefs.setString('appareils', data);
  }

  void _toggleAppareil(String id) {
    setState(() {
      final appareil = _appareils.firstWhere((a) => a.id == id);
      appareil.estAllume = !appareil.estAllume;
    });
    _sauvegarderAppareils();
  }

  void _supprimerAppareil(String id) {
    setState(() => _appareils.removeWhere((a) => a.id == id));
    _sauvegarderAppareils();
  }

  Future<void> _ouvrirAjout() async {
    final nouvelAppareil = await Navigator.push<Appareil>(
      context,
      MaterialPageRoute(builder: (context) => const AjoutScreen()),
    );
    if (nouvelAppareil != null) {
      setState(() => _appareils.add(nouvelAppareil));
      _sauvegarderAppareils();
    }
  }

  void _toggleModeEco() {
    setState(() {
      _modeEcoActif = !_modeEcoActif;
      if (_modeEcoActif) {
        for (final appareil in _appareils) {
          appareil.estAllume = false;
        }
      }
    });
    _sauvegarderAppareils();
  }

  void _afficherMenuTheme() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('Système'),
              trailing: widget.themeMode == ThemeMode.system
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                widget.onChangerTheme(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Clair'),
              trailing: widget.themeMode == ThemeMode.light
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                widget.onChangerTheme(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Sombre'),
              trailing: widget.themeMode == ThemeMode.dark
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                widget.onChangerTheme(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconeParPiece(String piece) {
    switch (piece) {
      case 'Salon':
        return Icons.weekend;
      case 'Chambre':
        return Icons.bed;
      case 'Cuisine':
        return Icons.kitchen;
      case 'Salle de bain':
        return Icons.bathtub;
      case 'Bureau':
        return Icons.computer;
      default:
        return Icons.home;
    }
  }

  IconData get _iconeTheme {
    switch (widget.themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      default:
        return Icons.brightness_auto;
    }
  }

  // Liste des pièces disponibles + "Tous"
  List<String> get _pieces {
    final pieces = _appareils.map((a) => a.piece).toSet().toList();
    pieces.sort();
    return ['Tous', ...pieces];
  }

  // Appareils filtrés selon la pièce sélectionnée
  List<Appareil> get _appareilsFiltres {
    if (_filtrepiece == 'Tous') return _appareils;
    return _appareils.where((a) => a.piece == _filtrepiece).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allumes = _appareils.where((a) => a.estAllume).length;
    final filtres = _appareilsFiltres;

    if (_chargement) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartHome Connect'),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy),
            tooltip: 'Assistant IA',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AssistantScreen(
                  appareils: _appareils,
                  unitesSeeg: _unitesSeeg,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Mon profil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilScreen(
                  appareils: _appareils,
                  unitesSeeg: _unitesSeeg,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.wb_sunny),
            tooltip: 'Météo',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MeteoScreen(appareils: _appareils),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.flash_off),
            tooltip: 'Alertes coupures',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CoupuresScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.electric_meter),
            tooltip: 'Unités SEEG',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SeegScreen(appareils: _appareils),
              ),
            ),
          ),
          IconButton(
            icon: Icon(_iconeTheme),
            tooltip: 'Changer le thème',
            onPressed: _afficherMenuTheme,
          ),
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Simulation 2D',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SimulationScreen(appareils: _appareils),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: 'Tableau de bord',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TableauBordScreen(appareils: _appareils),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode Éco
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: _modeEcoActif
                ? Colors.green.shade700
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  _modeEcoActif ? Icons.eco : Icons.eco_outlined,
                  color: _modeEcoActif ? Colors.white : Colors.green.shade700,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _modeEcoActif
                        ? 'Mode Éco actif — tous les appareils sont éteints'
                        : 'Mode Éco désactivé',
                    style: TextStyle(
                      color: _modeEcoActif ? Colors.white : null,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: _modeEcoActif,
                  onChanged: (_) => _toggleModeEco(),
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.green.shade500,
                ),
              ],
            ),
          ),

          // Compteur + filtre par pièce
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Icon(Icons.bolt, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$allumes / ${_appareils.length} allumé${allumes > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          // Chips de filtre par pièce
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _pieces.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final piece = _pieces[index];
                final selectionne = piece == _filtrepiece;
                return FilterChip(
                  label: Text(piece),
                  selected: selectionne,
                  onSelected: (_) => setState(() => _filtrepiece = piece),
                  selectedColor: const Color(0xFF1565C0),
                  labelStyle: TextStyle(
                    color: selectionne ? Colors.white : null,
                    fontWeight: selectionne ? FontWeight.bold : null,
                  ),
                  checkmarkColor: Colors.white,
                );
              },
            ),
          ),
          const SizedBox(height: 4),

          // Liste des appareils filtrés
          Expanded(
            child: filtres.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.devices_other,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filtrepiece == 'Tous'
                              ? 'Aucun appareil\nAppuyez sur + pour en ajouter'
                              : 'Aucun appareil dans "$_filtrepiece"',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: filtres.length,
                    itemBuilder: (context, index) {
                      final appareil = filtres[index];
                      return CarteAppareil(
                        appareil: appareil,
                        iconePiece: _iconeParPiece(appareil.piece),
                        modeEcoActif: _modeEcoActif,
                        onToggle: () => _toggleAppareil(appareil.id),
                        onDelete: () => _supprimerAppareil(appareil.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ouvrirAjout,
        tooltip: 'Ajouter un appareil',
        child: const Icon(Icons.add),
      ),
    );
  }
}
