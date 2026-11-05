import 'package:flutter/material.dart';

/// Perfil de armamento exibido na interface.
///
/// É um dado puramente de apresentação: identifica o ensaio na tela de
/// resultados e NÃO altera nenhum parâmetro do analisador de áudio.
@immutable
class WeaponProfile {
  const WeaponProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.imageAsset,
  });

  final String id;
  final String name;
  final String description;

  /// Ícone vetorial usado como ilustração enquanto não houver imagem.
  final IconData icon;

  /// Caminho opcional de uma ilustração (ex.: `assets/weapons/fuzil.png`).
  /// Para usar, declare o arquivo na seção `assets` do `pubspec.yaml`.
  final String? imageAsset;
}

/// Catálogo de armamentos disponíveis para seleção.
const List<WeaponProfile> kWeaponProfiles = <WeaponProfile>[
  WeaponProfile(
    id: 'fuzil',
    name: 'Fuzil',
    description: 'Fuzil automático / de assalto',
    icon: Icons.gps_fixed,
  ),
  WeaponProfile(
    id: 'metralhadora',
    name: 'Metralhadora',
    description: 'Metralhadora leve ou média',
    icon: Icons.track_changes,
  ),
  WeaponProfile(
    id: 'submetralhadora',
    name: 'Submetralhadora',
    description: 'Submetralhadora / pistola-metralhadora',
    icon: Icons.adjust,
  ),
  WeaponProfile(
    id: 'pistola',
    name: 'Pistola',
    description: 'Pistola semiautomática ou automática',
    icon: Icons.my_location,
  ),
  WeaponProfile(
    id: 'outro',
    name: 'Outro',
    description: 'Armamento não listado',
    icon: Icons.tune,
  ),
];
