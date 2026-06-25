import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appareil.dart';

class ProfilScreen extends StatefulWidget {
  final List<Appareil> appareils;
  final double unitesSeeg;

  const ProfilScreen({
    super.key,
    required this.appareils,
    required this.unitesSeeg,
  });

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final _nomControleur = TextEditingController();
  bool _enregistrement = false;

  @override
  void initState() {
    super.initState();
    _nomControleur.text = _user?.displayName ?? '';
  }

  Future<void> _enregistrerNom() async {
    final nom = _nomControleur.text.trim();
    if (nom.isEmpty) return;
    setState(() => _enregistrement = true);
    try {
      await _user?.updateDisplayName(nom);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nom mis à jour !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      setState(() => _enregistrement = false);
    }
  }

  Future<void> _deconnecter() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _supprimerCompte() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
            'Es-tu sûr de vouloir supprimer ton compte ? Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirme == true) {
      try {
        await _user?.delete();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e')),
          );
        }
      }
    }
  }

  // Stats résumées
  int get _totalAppareils => widget.appareils.length;
  int get _appareilsAllumes => widget.appareils.where((a) => a.estAllume).length;
  double get _consoTotale =>
      widget.appareils.where((a) => a.estAllume).fold(0.0, (s, a) => s + a.watts);
  double get _autonomieJours => _consoTotale > 0
      ? widget.unitesSeeg / (_consoTotale * 6 / 1000)
      : double.infinity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Avatar + email
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFF1565C0),
                      child: Text(
                        (_user?.displayName?.isNotEmpty == true
                                ? _user!.displayName![0]
                                : _user?.email?[0] ?? '?')
                            .toUpperCase(),
                        style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user?.displayName?.isNotEmpty == true
                                ? _user!.displayName!
                                : 'Utilisateur',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _user?.email ?? '',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Membre depuis ${_user?.metadata.creationTime?.year ?? '—'}',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Stats rapides
            const Text('Résumé de ton installation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _carteStatut('Total appareils', '$_totalAppareils', Icons.devices, Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _carteStatut('Allumés', '$_appareilsAllumes', Icons.power, Colors.green)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _carteStatut('Conso. actuelle', '${_consoTotale.toInt()} W', Icons.bolt, Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: _carteStatut(
                  'Autonomie SEEG',
                  _autonomieJours.isInfinite ? '∞ j' : '${_autonomieJours.toStringAsFixed(1)} j',
                  Icons.electric_meter,
                  _autonomieJours < 7 ? Colors.red : Colors.teal,
                )),
              ],
            ),

            const SizedBox(height: 16),

            // Modifier le nom
            const Text('Modifier le nom',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nomControleur,
                        decoration: const InputDecoration(
                          labelText: 'Nom affiché',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _enregistrement ? null : _enregistrerNom,
                      child: _enregistrement
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('OK'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Actions compte
            const Text('Mon compte',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.orange),
                    title: const Text('Se déconnecter'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _deconnecter,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Supprimer mon compte',
                        style: TextStyle(color: Colors.red)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _supprimerCompte,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carteStatut(String label, String valeur, IconData icone, Color couleur) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icone, color: couleur, size: 28),
            const SizedBox(height: 6),
            Text(valeur,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: couleur)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomControleur.dispose();
    super.dispose();
  }
}