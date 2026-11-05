import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../audio_analyzer.dart';
import '../models/recording_entry.dart';
import '../models/weapon.dart';
import '../utils/formatters.dart';

/// Gerencia o salvamento das gravações com nomenclatura GDH (Grupo Data-Hora)
/// e o histórico persistente de gravações realizadas no aplicativo.
class RecordingHistoryService extends ChangeNotifier {
  RecordingHistoryService();

  static const String _folderName = 'arsenalwave_recordings';
  static const String _indexFileName = 'history.json';

  final List<RecordingEntry> _entries = <RecordingEntry>[];
  bool _loaded = false;
  bool _disposed = false;

  List<RecordingEntry> get entries => List<RecordingEntry>.unmodifiable(_entries);
  bool get isLoaded => _loaded;

  /// Carrega o histórico salvo no armazenamento local do aplicativo.
  Future<void> load() async {
    if (_loaded || kIsWeb) {
      _loaded = true;
      return;
    }

    try {
      final Directory dir = await _recordingsDirectory();
      final File indexFile = File('${dir.path}/$_indexFileName');
      if (!await indexFile.exists()) {
        _loaded = true;
        _notify();
        return;
      }

      final String raw = await indexFile.readAsString();
      final Object? decoded = jsonDecode(raw);
      if (decoded is List<Object?>) {
        final List<RecordingEntry> valid = <RecordingEntry>[];
        for (final Object? item in decoded) {
          if (item is Map<String, Object?>) {
            final RecordingEntry entry = RecordingEntry.fromJson(item);
            if (entry.filePath.isNotEmpty &&
                await File(entry.filePath).exists()) {
              valid.add(entry);
            }
          }
        }
        _entries
          ..clear()
          ..addAll(valid);
      }
    } catch (_) {
      // Caso o índice esteja ausente ou corrompido, inicia histórico vazio.
    } finally {
      _loaded = true;
      _notify();
    }
  }

  /// Salva o arquivo WAV com o GDH no diretório permanente do aplicativo e
  /// adiciona o registro ao histórico.
  Future<RecordingEntry> saveRecording({
    required String sourcePath,
    required WeaponProfile weapon,
    required DateTime timestamp,
    required AnalysisResult result,
  }) async {
    if (!_loaded) {
      await load();
    }

    final String gdh = formatGdh(timestamp);
    final String fileName = buildGdhWavFileName(
      weaponName: weapon.name,
      timestamp: timestamp,
    );

    String savedPath = sourcePath;
    if (!kIsWeb) {
      final Directory dir = await _recordingsDirectory();
      savedPath = '${dir.path}/$fileName';
      if (sourcePath != savedPath) {
        await File(sourcePath).copy(savedPath);
      }
    }

    final RecordingEntry entry = RecordingEntry(
      id: '${timestamp.millisecondsSinceEpoch}_${weapon.id}',
      fileName: fileName,
      filePath: savedPath,
      gdh: gdh,
      recordedAt: timestamp,
      weaponId: weapon.id,
      weaponName: weapon.name,
      shotCount: result.shootingTimes.length,
      meanCadence: result.meanCadence,
      maxCadence: result.maxCadence,
      minCadence: result.minCadence,
    );

    _entries.removeWhere((RecordingEntry e) => e.filePath == savedPath);
    _entries.insert(0, entry);
    await _persistIndex();
    _notify();
    return entry;
  }

  /// Abre a caixa de diálogo nativa do sistema para exportar/salvar uma cópia
  /// do arquivo WAV já nomeado com o GDH em qualquer pasta escolhida pelo usuário.
  Future<String?> exportWavWithGdh({
    required String sourcePath,
    required WeaponProfile weapon,
    required DateTime timestamp,
  }) async {
    if (kIsWeb) return null;
    final File file = File(sourcePath);
    if (!await file.exists()) {
      throw const FileSystemException('Arquivo de áudio não encontrado.');
    }

    final Uint8List bytes = await file.readAsBytes();
    final String fileName = buildGdhWavFileName(
      weaponName: weapon.name,
      timestamp: timestamp,
    );

    final String? targetPath = await FilePicker.saveFile(
      dialogTitle: 'Salvar gravação WAV com GDH',
      fileName: fileName,
      bytes: bytes,
    );
    return targetPath;
  }

  /// Remove uma gravação específica do histórico e apaga seu arquivo WAV local.
  Future<void> deleteEntry(String id) async {
    final int index =
        _entries.indexWhere((RecordingEntry e) => e.id == id);
    if (index < 0) return;

    final RecordingEntry removed = _entries.removeAt(index);
    if (!kIsWeb) {
      try {
        final File file = File(removed.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    await _persistIndex();
    _notify();
  }

  /// Limpa todo o histórico de gravações do aplicativo.
  Future<void> clearAll() async {
    final List<RecordingEntry> copy = List<RecordingEntry>.from(_entries);
    _entries.clear();
    if (!kIsWeb) {
      for (final RecordingEntry entry in copy) {
        try {
          final File f = File(entry.filePath);
          if (await f.exists()) {
            await f.delete();
          }
        } catch (_) {}
      }
    }
    await _persistIndex();
    _notify();
  }

  Future<Directory> _recordingsDirectory() async {
    final Directory docs = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${docs.path}/$_folderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _persistIndex() async {
    if (kIsWeb) return;
    try {
      final Directory dir = await _recordingsDirectory();
      final File indexFile = File('${dir.path}/$_indexFileName');
      final String encoded = jsonEncode(
        _entries.map((RecordingEntry e) => e.toJson()).toList(),
      );
      await indexFile.writeAsString(encoded, flush: true);
    } catch (_) {}
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
