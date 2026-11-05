import 'package:flutter/material.dart';

/// Tipo de silhueta vetorial minimalista exibida no placeholder quando nenhuma
/// imagem externa (`imageAsset`) estiver configurada.
enum WeaponSilhouetteKind { fal, parafal, ia2, mag, generic }

/// Perfil visual de armamento para identificação do ensaio na interface.
///
/// Dado estritamente de apresentação (UI): NÃO altera nenhum parâmetro, filtro
/// ou cálculo do analisador de áudio (`AudioAnalyzer`).
@immutable
class WeaponProfile {
  const WeaponProfile({
    required this.id,
    required this.name,
    required this.fullName,
    required this.caliber,
    required this.icon,
    required this.silhouette,
    this.imageAsset,
  });

  final String id;
  final String name;
  final String fullName;
  final String caliber;
  final IconData icon;
  final WeaponSilhouetteKind silhouette;

  /// Caminho opcional para imagem externa (ex.: `'assets/weapons/fal.png'`).
  /// Caso seja `null` ou falhe ao carregar, o placeholder vetorial padronizado
  /// mantém o layout íntegro.
  final String? imageAsset;
}

/// Catálogo de armamentos do ArsenalWave.
const List<WeaponProfile> kWeaponProfiles = <WeaponProfile>[
  WeaponProfile(
    id: 'fal',
    name: 'FAL',
    fullName: 'Fuzil 7,62 mm M964 (FAL)',
    caliber: '7,62×51 mm',
    icon: Icons.gps_fixed,
    silhouette: WeaponSilhouetteKind.fal,
  ),
  WeaponProfile(
    id: 'parafal',
    name: 'ParaFAL',
    fullName: 'Fuzil 7,62 mm M964A1 (ParaFAL)',
    caliber: '7,62×51 mm',
    icon: Icons.my_location,
    silhouette: WeaponSilhouetteKind.parafal,
  ),
  WeaponProfile(
    id: 'ia2',
    name: 'IA2',
    fullName: 'Fuzil de Assalto IMBEL IA2',
    caliber: '5,56 / 7,62 mm',
    icon: Icons.adjust,
    silhouette: WeaponSilhouetteKind.ia2,
  ),
  WeaponProfile(
    id: 'mag',
    name: 'MAG',
    fullName: 'Metralhadora FN MAG M971',
    caliber: '7,62×51 mm',
    icon: Icons.track_changes,
    silhouette: WeaponSilhouetteKind.mag,
  ),
  WeaponProfile(
    id: 'outro',
    name: 'Outro',
    fullName: 'Outro Armamento (Ensaio Geral)',
    caliber: 'Padrão WAV',
    icon: Icons.tune,
    silhouette: WeaponSilhouetteKind.generic,
  ),
];
