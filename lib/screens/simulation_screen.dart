import 'package:flutter/material.dart';
import '../models/appareil.dart';

class SimulationScreen extends StatefulWidget {
  final List<Appareil> appareils;

  const SimulationScreen({super.key, required this.appareils});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<Map<String, dynamic>> _pieces = [
    {'nom': 'Salon', 'x': 0.02, 'y': 0.02, 'w': 0.45, 'h': 0.40, 'couleur': Colors.blue},
    {'nom': 'Chambre', 'x': 0.53, 'y': 0.02, 'w': 0.45, 'h': 0.35, 'couleur': Colors.purple},
    {'nom': 'Cuisine', 'x': 0.02, 'y': 0.55, 'w': 0.30, 'h': 0.35, 'couleur': Colors.orange},
    {'nom': 'Salle de bain', 'x': 0.38, 'y': 0.55, 'w': 0.25, 'h': 0.35, 'couleur': Colors.teal},
    {'nom': 'Bureau', 'x': 0.69, 'y': 0.42, 'w': 0.29, 'h': 0.48, 'couleur': Colors.indigo},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _pieceHasAllume(String nomPiece) {
    return widget.appareils.any((a) => a.piece == nomPiece && a.estAllume);
  }

  int _countAllumes(String nomPiece) {
    return widget.appareils.where((a) => a.piece == nomPiece && a.estAllume).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulation 2D')),
      body: Column(
        children: [
          // Légende
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Allumé', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 24),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Éteint', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),

          // Plan 2D
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  return Stack(
                    children: [
                      // Fond du plan
                      Container(
                        width: w,
                        height: h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border.all(color: Colors.black, width: 3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),

                      // Pièces dessinées
                      ..._pieces.map((piece) {
                        final px = piece['x'] as double;
                        final py = piece['y'] as double;
                        final pw = piece['w'] as double;
                        final ph = piece['h'] as double;
                        final couleur = piece['couleur'] as Color;
                        final nomPiece = piece['nom'] as String;
                        final allume = _pieceHasAllume(nomPiece);
                        final countOn = _countAllumes(nomPiece);

                        return Positioned(
                          left: px * w,
                          top: py * h,
                          width: pw * w,
                          height: ph * h,
                          child: Container(
                            decoration: BoxDecoration(
                              color: allume
                                  ? couleur.withValues(alpha: 0.15)
                                  : Colors.grey.shade200,
                              border: Border.all(color: couleur, width: 2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Stack(
                              children: [
                                // Nom de la pièce
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  right: 6,
                                  child: Text(
                                    nomPiece,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: couleur,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                // Pastille lumineuse animée
                                Center(
                                  child: AnimatedBuilder(
                                    animation: _animation,
                                    builder: (context, child) {
                                      return Container(
                                        width: allume ? 28 * _animation.value : 20,
                                        height: allume ? 28 * _animation.value : 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: allume
                                              ? Colors.amber.withValues(alpha: _animation.value)
                                              : Colors.grey.shade800,
                                          boxShadow: allume
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.amber.withValues(
                                                        alpha: _animation.value * 0.6),
                                                    blurRadius: 12,
                                                    spreadRadius: 4,
                                                  ),
                                                ]
                                              : [],
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // Compteur appareils allumés
                                if (countOn > 0)
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$countOn 💡',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),

          // Résumé en bas
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _pieces.map((piece) {
                final nomPiece = piece['nom'] as String;
                final couleur = piece['couleur'] as Color;
                final allume = _pieceHasAllume(nomPiece);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      allume ? Icons.lightbulb : Icons.lightbulb_outline,
                      color: allume ? Colors.amber : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nomPiece.split(' ').first,
                      style: TextStyle(
                        fontSize: 10,
                        color: allume ? couleur : Colors.grey,
                        fontWeight: allume ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}