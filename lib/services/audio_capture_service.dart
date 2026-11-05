import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Fases do ciclo de vida da captura de áudio.
enum CapturePhase { idle, starting, recording, stopping }

/// Categorias de falha de captura, usadas pela UI para escolher a mensagem/ação.
enum CaptureErrorKind {
  permissionDenied,
  encoderUnsupported,
  startFailed,
  stopFailed,
  emptyRecording,
}

/// Erro operacional de captura com mensagem pronta para o usuário.
class CaptureException implements Exception {
  const CaptureException(this.kind, this.message, [this.cause]);

  final CaptureErrorKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() => 'CaptureException($kind): $message'
      '${cause != null ? ' — $cause' : ''}';
}

/// Encapsula o ciclo de vida do [AudioRecorder]:
/// permissão → início → monitoramento (cronômetro/nível) → parada/cancelamento
/// → liberação de recursos.
///
/// O arquivo entregue por [stop] é um WAV PCM 16-bit, 44,1 kHz, 2 canais —
/// exatamente o que `AudioAnalyzer.processWavFile` (via `Wav.readFile`) espera.
class AudioCaptureService extends ChangeNotifier {
  AudioCaptureService();

  /// Configuração de captura. Mantém os mesmos parâmetros acústicos originais
  /// (44,1 kHz, estéreo, sem AGC/eco/supressão, fonte UNPROCESSED no Android).
  ///
  /// Correção: o encoder original `AudioEncoder.pcm16bits` grava PCM cru SEM
  /// cabeçalho RIFF, o que impede `Wav.readFile` de abrir o arquivo.
  /// `AudioEncoder.wav` grava o mesmo PCM 16-bit, porém dentro do contêiner WAV.
  static const RecordConfig recordConfig = RecordConfig(
    encoder: AudioEncoder.wav, // PCM 16-bit linear com cabeçalho WAV
    sampleRate: 44100, // Amostragem de 44.1 kHz
    numChannels: 2, // Estéreo (o analisador lê o canal 1)
    autoGain: false, // Desativa Ganho Automático (AGC)
    echoCancel: false, // Desativa Cancelamento de Eco
    noiseSuppress: false, // Desativa Supressão de Ruído
    // Configurações do Android: força áudio cru (UNPROCESSED)
    androidConfig: AndroidRecordConfig(
      audioSource: AndroidAudioSource.unprocessed,
    ),
    iosConfig: IosRecordConfig(),
  );

  /// Tamanho do cabeçalho WAV canônico; arquivos deste tamanho não têm amostras.
  static const int _wavHeaderBytes = 44;
  static const double silenceDb = -160;
  static const Duration _tickInterval = Duration(milliseconds: 100);
  static const Duration _amplitudeInterval = Duration(milliseconds: 120);

  /// Instanciado sob demanda: nenhum recurso nativo é alocado até a 1ª gravação.
  AudioRecorder? _recorder;
  AudioRecorder get _rec => _recorder ??= AudioRecorder();

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  StreamSubscription<Amplitude>? _amplitudeSub;
  String? _activePath;
  bool _disposed = false;

  CapturePhase _phase = CapturePhase.idle;
  Duration _elapsed = Duration.zero;
  double? _levelDb;
  double _peakDb = silenceDb;

  CapturePhase get phase => _phase;
  bool get isRecording => _phase == CapturePhase.recording;
  bool get isBusy =>
      _phase == CapturePhase.starting || _phase == CapturePhase.stopping;

  /// Tempo decorrido da gravação atual (ou da última, após a parada).
  Duration get elapsed => _elapsed;

  /// Nível instantâneo em dBFS (null quando indisponível).
  double? get levelDb => _levelDb;

  /// Maior nível observado na gravação atual, em dBFS.
  double get peakDb => _peakDb;

  /// Nível normalizado (0–1) numa janela de 60 dB, para o medidor visual.
  double get levelFraction {
    final double? db = _levelDb;
    if (db == null) return 0;
    return ((db + 60) / 60).clamp(0.0, 1.0).toDouble();
  }

  /// Solicita permissão (se necessário) e inicia a gravação em arquivo temporário.
  ///
  /// Chamadas concorrentes (toques duplos) são ignoradas enquanto a fase
  /// não for [CapturePhase.idle].
  Future<void> start() async {
    if (_disposed || _phase != CapturePhase.idle) return;
    _setPhase(CapturePhase.starting);

    try {
      final bool granted = await _rec.hasPermission();
      if (_disposed) return;
      if (!granted) {
        throw const CaptureException(
          CaptureErrorKind.permissionDenied,
          'Permissão de microfone negada. Libere o acesso nas configurações '
          'do sistema para gravar.',
        );
      }

      final bool supported = await _rec.isEncoderSupported(
        recordConfig.encoder,
      );
      if (_disposed) return;
      if (!supported) {
        throw const CaptureException(
          CaptureErrorKind.encoderUnsupported,
          'Este dispositivo não suporta gravação WAV PCM 16-bit.',
        );
      }

      final Directory dir = await getTemporaryDirectory();
      final String path =
          '${dir.path}/audio_disparos_${DateTime.now().millisecondsSinceEpoch}.wav';

      if (_disposed) return;
      _activePath = path;
      await _rec.start(recordConfig, path: path);

      if (_disposed) return; // dispose() já liberou o gravador e o arquivo.
      _beginMonitoring();
      _setPhase(CapturePhase.recording);
    } on CaptureException {
      _setPhase(CapturePhase.idle);
      rethrow;
    } catch (error) {
      await _discardActiveRecording();
      _setPhase(CapturePhase.idle);
      throw CaptureException(
        CaptureErrorKind.startFailed,
        'Não foi possível iniciar a captura de áudio. Verifique se outro '
        'aplicativo está usando o microfone.',
        error,
      );
    }
  }

  /// Finaliza a gravação e devolve o caminho do WAV gerado.
  ///
  /// O chamador é responsável por apagar o arquivo após a análise
  /// (ver [deleteRecording]).
  Future<String> stop() async {
    if (_phase != CapturePhase.recording) {
      throw StateError('stop() chamado sem gravação ativa (fase: $_phase).');
    }
    _setPhase(CapturePhase.stopping);
    _endMonitoring();
    final String? expectedPath = _activePath;

    try {
      final String? output = await _rec.stop() ?? expectedPath;
      if (output == null) {
        throw const CaptureException(
          CaptureErrorKind.emptyRecording,
          'Nenhum arquivo de áudio foi gerado.',
        );
      }

      final File file = File(output);
      if (!await file.exists() || await file.length() <= _wavHeaderBytes) {
        await deleteRecording(output);
        throw const CaptureException(
          CaptureErrorKind.emptyRecording,
          'A gravação está vazia. Verifique o microfone e tente novamente.',
        );
      }
      return output;
    } on CaptureException {
      rethrow;
    } catch (error) {
      await _discardActiveRecording();
      throw CaptureException(
        CaptureErrorKind.stopFailed,
        'Falha ao finalizar a gravação.',
        error,
      );
    } finally {
      _activePath = null;
      _setPhase(CapturePhase.idle);
    }
  }

  /// Interrompe a gravação atual descartando o arquivo.
  Future<void> cancel() async {
    if (_phase != CapturePhase.recording) return;
    _setPhase(CapturePhase.stopping);
    _endMonitoring();
    await _discardActiveRecording();
    _setPhase(CapturePhase.idle);
  }

  /// Remove um arquivo de gravação temporário (falhas são ignoradas).
  static Future<void> deleteRecording(String path) async {
    try {
      final File file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Arquivo temporário: o sistema operacional o removerá posteriormente.
    }
  }

  Future<void> _discardActiveRecording() async {
    final String? path = _activePath;
    _activePath = null;
    final AudioRecorder? recorder = _recorder;
    if (recorder != null) {
      try {
        await recorder.cancel(); // Para a captura nativa e apaga o arquivo.
      } catch (_) {
        // O gravador pode já estar parado; segue para a limpeza do arquivo.
      }
    }
    if (path != null) await deleteRecording(path);
  }

  void _beginMonitoring() {
    _elapsed = Duration.zero;
    _levelDb = null;
    _peakDb = silenceDb;
    _stopwatch
      ..reset()
      ..start();

    _ticker?.cancel();
    _ticker = Timer.periodic(_tickInterval, (Timer _) {
      _elapsed = _stopwatch.elapsed;
      _notify();
    });

    unawaited(_amplitudeSub?.cancel());
    _amplitudeSub = _rec.onAmplitudeChanged(_amplitudeInterval).listen(
      (Amplitude amplitude) {
        final double db = amplitude.current;
        if (!db.isFinite) return;
        _levelDb = db;
        if (db > _peakDb) _peakDb = db;
      },
      onError: (Object error, StackTrace stackTrace) {
        // O medidor de nível é apenas informativo; a gravação continua.
        _levelDb = null;
      },
    );
  }

  void _endMonitoring() {
    _ticker?.cancel();
    _ticker = null;
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _elapsed = _stopwatch.elapsed;
    }
    unawaited(_amplitudeSub?.cancel());
    _amplitudeSub = null;
    _levelDb = null;
  }

  void _setPhase(CapturePhase phase) {
    _phase = phase;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _endMonitoring();
    final AudioRecorder? recorder = _recorder;
    final String? pending = _activePath;
    _recorder = null;
    _activePath = null;
    if (recorder != null) unawaited(_release(recorder, pending));
    super.dispose();
  }

  /// Libera a instância nativa (para a captura, se ativa) e apaga o arquivo
  /// pendente — evita vazamento de memória e microfone preso entre sessões.
  static Future<void> _release(AudioRecorder recorder, String? pending) async {
    try {
      await recorder.dispose();
    } catch (_) {
      // Instância já liberada pelo plugin.
    }
    if (pending != null) await deleteRecording(pending);
  }
}
