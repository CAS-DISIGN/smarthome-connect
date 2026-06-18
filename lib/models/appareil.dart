import 'package:flutter/material.dart';

class Appareil {
  final String id;
  final String nom;
  final String piece;
  final IconData icone;
  bool estAllume;

  Appareil({
    required this.id,
    required this.nom,
    required this.piece,
    required this.icone,
    this.estAllume = false,
  });
}

List<Appareil> appareilsMock() {
  return [
    Appareil(id: '1', nom: 'Lampe salon', piece: 'Salon', icone: Icons.lightbulb, estAllume: true),
    Appareil(id: '2', nom: 'Climatiseur', piece: 'Chambre', icone: Icons.ac_unit),
    Appareil(id: '3', nom: 'Prise TV', piece: 'Salon', icone: Icons.power),
    Appareil(id: '4', nom: 'Volet roulant', piece: 'Chambre', icone: Icons.blinds),
    Appareil(id: '5', nom: 'Chauffage', piece: 'Cuisine', icone: Icons.thermostat),
  ];
}