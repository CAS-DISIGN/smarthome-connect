import 'package:flutter/material.dart';

class Appareil {
  final String id;
  final String nom;
  final String piece;
  final IconData icone;
  bool estAllume;
  final double watts; // consommation en Watts

  Appareil({
    required this.id,
    required this.nom,
    required this.piece,
    required this.icone,
    this.estAllume = false,
    this.watts = 100,
  });

  static const _iconeMap = {
    'lightbulb': Icons.lightbulb,
    'ac_unit': Icons.ac_unit,
    'power': Icons.power,
    'blinds': Icons.blinds,
    'thermostat': Icons.thermostat,
    'tv': Icons.tv,
    'speaker': Icons.speaker,
    'computer': Icons.computer,
  };

  static IconData iconeDepuisNom(String nom) =>
      _iconeMap[nom] ?? Icons.devices_other;

  static String nomDepuisIcone(IconData icone) =>
      _iconeMap.entries.firstWhere(
        (e) => e.value == icone,
        orElse: () => const MapEntry('devices_other', Icons.devices_other),
      ).key;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'piece': piece,
        'icone': nomDepuisIcone(icone),
        'estAllume': estAllume,
        'watts': watts,
      };

  factory Appareil.fromJson(Map<String, dynamic> json) => Appareil(
        id: json['id'],
        nom: json['nom'],
        piece: json['piece'],
        icone: iconeDepuisNom(json['icone']),
        estAllume: json['estAllume'] ?? false,
        watts: (json['watts'] as num?)?.toDouble() ?? 100,
      );
}

List<Appareil> appareilsMock() {
  return [
    Appareil(id: '1', nom: 'Lampe salon',   piece: 'Salon',   icone: Icons.lightbulb, estAllume: true, watts: 15),
    Appareil(id: '2', nom: 'Climatiseur',   piece: 'Chambre', icone: Icons.ac_unit,   watts: 1500),
    Appareil(id: '3', nom: 'Prise TV',      piece: 'Salon',   icone: Icons.power,     watts: 120),
    Appareil(id: '4', nom: 'Volet roulant', piece: 'Chambre', icone: Icons.blinds,    watts: 50),
    Appareil(id: '5', nom: 'Chauffage',     piece: 'Cuisine', icone: Icons.thermostat,watts: 2000),
  ];
}