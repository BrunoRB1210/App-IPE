import 'package:flutter/foundation.dart';

/// Registro de uma gravação salva pelo ArsenalWave com seu Grupo Data-Hora (GDH).
///
/// Armazena apenas metadados de identificação e os valores já retornados pelo
/// `AudioAnalyzer`, sem modificar nenhuma lógica de DSP.
@immutable
class RecordingEntry {
  const RecordingEntry({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.gdh,
    required this.recordedAt,
    required this.weaponId,
    required this.weaponName,
    required this.shotCount,
    this.meanCadence,
    this.maxCadence,
    this.minCadence,
  });

  factory RecordingEntry.fromJson(Map<String, Object?> json) {
    return RecordingEntry(
      id: (json['id'] as String?) ?? '',
      fileName: (json['fileName'] as String?) ?? '',
      filePath: (json['filePath'] as String?) ?? '',
      gdh: (json['gdh'] as String?) ?? '',
      recordedAt: DateTime.tryParse((json['recordedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      weaponId: (json['weaponId'] as String?) ?? 'fal',
      weaponName: (json['weaponName'] as String?) ?? 'FAL',
      shotCount: (json['shotCount'] as num?)?.toInt() ?? 0,
      meanCadence: (json['meanCadence'] as num?)?.toDouble(),
      maxCadence: (json['maxCadence'] as num?)?.toDouble(),
      minCadence: (json['minCadence'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String fileName;
  final String filePath;
  final String gdh;
  final DateTime recordedAt;
  final String weaponId;
  final String weaponName;
  final int shotCount;
  final double? meanCadence;
  final double? maxCadence;
  final double? minCadence;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'fileName': fileName,
        'filePath': filePath,
        'gdh': gdh,
        'recordedAt': recordedAt.toIso8601String(),
        'weaponId': weaponId,
        'weaponName': weaponName,
        'shotCount': shotCount,
        'meanCadence': meanCadence,
        'maxCadence': maxCadence,
        'minCadence': minCadence,
      };
}
