import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Fases do ciclo de vida da captura de áudio.
enum CapturePhase { idle, starting, recording, stopping }

/// Categorias de falha operacional de captura para tratamento na UI.
enum CaptureErrorKind {
  permissionDenied,
  encoderUnsupported,
  startFailed,
  stopFailed,
  emptyRecording,
}

/// Exceção tipada de captura acústica com mensagem amigável para a UI.
class CaptureException implements Exception {
  const CaptureException(this.kind, this.message, [this.cause]);

  final CaptureErrorKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() => 'CaptureException($kind): $message'
      '${cause != null ? ' — $cause' : ''}';
}

/// Gerencia exclusivamente o ciclo de vida do [AudioRecorder]:
/// permissão → alocação sob demanda → captura WAV PCM 16-bit → monitoramento →
/// parada/cancelamento → liberação determinística da instância nativa.
///
/// Nenhuma lógica de DSP ou cálculo de cadência reside aqui: o arquivo `.wav`
/// gravado é entregue intacto ao `AudioAnalyzer.processWavFile`.
class AudioCaptureService extends ChangeNotifier {
  AudioCaptureService();

  /// Configuração acústica crua (sem AGC, sem cancelamento de eco, sem
  /// supressão de ruído e com fonte `UNPROCESSED` no Android).
  ///
  /// Usa `AudioEncoder.wav` (PCM 16-bit linear encapsulado com cabeçalho RIFF)
  /// para compatibilidade direta com `Wav.readFile` no `AudioAnalyzer`.
  static const RecordConfig recordConfig = RecordConfig(
    encoder: AudioEncoder.wav,
    sampleRate: 44100,
    numChannels: 2,
    autoGain: false,
    echoCancel: false,
    noiseSuppress: false,
    androidConfig: AndroidRecordConfig(
      audioSource: AndroidAudioSource.unprocessed,
    ),
    iosConfig: IosRecordConfig(),
  );

  /// Cabeçalho RIFF/WAV padrão possui 44 bytes; tamanhos <= 44 indicam 0 amostras.
  static const int _wavHeaderBytes = 44;
  static const double silenceDb = -160;
  static const Duration _tickInterval = Duration(milliseconds: 100);
  static const Duration _amplitudeInterval = Duration(milliseconds: 120);

  /// Instância nativa alocada apenas durante uma sessão ativa e descartada ao
  /// encerrar, prevenindo locks de microfone e vazamentos entre gravações.
  AudioRecorder? _recorder;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  StreamSubscription<Amplitude>? _amplitudeSub;
  StreamSubscription<RecordState>? _stateSub;
  String? _activePath;
  String? _interruptionMessage;
  bool _disposed = false;

  CapturePhase _phase = CapturePhase.idle;
  Duration _elapsed = Duration.zero;
  double? _levelDb;
  double _peakDb = silenceDb;

  CapturePhase get phase => _phase;
  bool get isRecording => _phase == CapturePhase.recording;
  bool get isBusy =>
      _phase == CapturePhase.starting || _phase == CapturePhase.stopping;

  /// Tempo decorrido da captura atual (ou da última captura encerrada).
  Duration get elapsed => _elapsed;

  /// Nível instantâneo em dBFS (null quando indisponível).
  double? get levelDb => _levelDb;

  /// Pico máximo observado na captura atual, em dBFS.
  double get peakDb => _peakDb;

  /// Nível normalizado (0.0 a 1.0) numa janela de 60 dB para feedback visual.
  double get levelFraction {
    final double? db = _levelDb;
    if (db == null) return 0;
    return ((db + 60) / 60).clamp(0.0, 1.0).toDouble();
  }

  /// Retorna e limpa eventual aviso de interrupção externa do sistema
  /// (ex.: chamada telefônica ou perda de foco do microfone).
  String? consumeInterruptionMessage() {
    final String? msg = _interruptionMessage;
    _interruptionMessage = null;
    return msg;
  }

  /// Solicita permissão (se necessário) e inicia uma nova gravação temporária.
  ///
  /// Ignora chamadas concorrentes enquanto não estiver em [CapturePhase.idle].
  Future<void> start() async {
    if (_disposed || _phase != CapturePhase.idle) return;
    _interruptionMessage = null;
    _setPhase(CapturePhase.starting);

    final AudioRecorder recorder = _recorder ??= AudioRecorder();

    try {
      final bool granted = await recorder.hasPermission();
      if (_disposed) {
        await _releaseRecorder();
        return;
      }
      if (!granted) {
        throw const CaptureException(
          CaptureErrorKind.permissionDenied,
          'Permissão de microfone negada. Libere o acesso nas configurações '
          'do dispositivo para gravar os disparos.',
        );
      }

      final bool supported = await recorder.isEncoderSupported(
        recordConfig.encoder,
      );
      if (_disposed) {
        await _releaseRecorder();
        return;
      }
      if (!supported) {
        throw const CaptureException(
          CaptureErrorKind.encoderUnsupported,
          'Este dispositivo não suporta gravação em formato WAV PCM 16-bit.',
        );
      }

      final Directory dir = await getTemporaryDirectory();
      final String path =
          '${dir.path}/audio_disparos_${DateTime.now().millisecondsSinceEpoch}.wav';

      if (_disposed) {
        await _releaseRecorder();
        return;
      }

      _activePath = path;
      await recorder.start(recordConfig, path: path);

      if (_disposed) {
        await _discardActiveRecording();
        return;
      }

      _beginMonitoring(recorder);
      _setPhase(CapturePhase.recording);
    } on CaptureException {
      await _discardActiveRecording();
      _setPhase(CapturePhase.idle);
      rethrow;
    } catch (error) {
      await _discardActiveRecording();
      _setPhase(CapturePhase.idle);
      throw CaptureException(
        CaptureErrorKind.startFailed,
        'Não foi possível iniciar o microfone. Verifique se outro aplicativo '
        'está utilizando o áudio.',
        error,
      );
    }
  }

  /// Encerra a gravação ativa, libera o hardware de captura e retorna o caminho
  /// do arquivo `.wav` pronto para o `AudioAnalyzer.processWavFile`.
  Future<String> stop() async {
    if (_phase != CapturePhase.recording) {
      throw StateError('stop() chamado fora do estado de gravação ($_phase).');
    }
    _setPhase(CapturePhase.stopping);
    await _stopMonitoring();

    final AudioRecorder? recorder = _recorder;
    final String? expectedPath = _activePath;

    try {
      final String? output = await recorder?.stop() ?? expectedPath;
      if (output == null) {
        throw const CaptureException(
          CaptureErrorKind.emptyRecording,
          'Nenhum arquivo de áudio foi gerado pela captura.',
        );
      }

      if (!kIsWeb) {
        final File file = File(output);
        if (!await file.exists() || await file.length() <= _wavHeaderBytes) {
          await deleteRecording(output);
          throw const CaptureException(
            CaptureErrorKind.emptyRecording,
            'A gravação ficou vazia. Verifique o microfone e tente novamente.',
          );
        }
      }
      return output;
    } on CaptureException {
      rethrow;
    } catch (error) {
      if (expectedPath != null) await deleteRecording(expectedPath);
      throw CaptureException(
        CaptureErrorKind.stopFailed,
        'Falha ao finalizar e salvar a gravação de áudio.',
        error,
      );
    } finally {
      _activePath = null;
      await _releaseRecorder();
      _setPhase(CapturePhase.idle);
    }
  }

  /// Cancela a gravação em andamento, apaga o arquivo parcial e libera o mic.
  Future<void> cancel() async {
    if (_phase != CapturePhase.recording) return;
    _setPhase(CapturePhase.stopping);
    await _stopMonitoring();
    await _discardActiveRecording();
    _setPhase(CapturePhase.idle);
  }

  /// Remove com segurança um arquivo WAV temporário após o processamento.
  static Future<void> deleteRecording(String path) async {
    if (kIsWeb) return;
    try {
      final File file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Falha benigna de limpeza em diretório temporário do SO.
    }
  }

  void _beginMonitoring(AudioRecorder recorder) {
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

    _amplitudeSub = recorder.onAmplitudeChanged(_amplitudeInterval).listen(
      (Amplitude amplitude) {
        final double db = amplitude.current;
        if (!db.isFinite) return;
        _levelDb = db;
        if (db > _peakDb) _peakDb = db;
      },
      onError: (Object error, StackTrace stackTrace) {
        _levelDb = null;
      },
    );

    _stateSub = recorder.onStateChanged().listen(
      (RecordState state) {
        // Se o SO interromper a gravação externamente enquanto ainda estamos
        // em CapturePhase.recording, libera o gravador para evitar estado travado.
        if (state == RecordState.stop && _phase == CapturePhase.recording) {
          unawaited(_handleUnexpectedStop());
        }
      },
      onError: (Object error, StackTrace stackTrace) {},
    );
  }

  Future<void> _handleUnexpectedStop() async {
    if (_phase != CapturePhase.recording) return;
    _setPhase(CapturePhase.stopping);
    await _stopMonitoring();
    await _discardActiveRecording();
    _interruptionMessage =
        'A gravação foi interrompida pelo sistema operacional.';
    _setPhase(CapturePhase.idle);
  }

  Future<void> _stopMonitoring() async {
    _ticker?.cancel();
    _ticker = null;
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _elapsed = _stopwatch.elapsed;
    }

    final StreamSubscription<Amplitude>? ampSub = _amplitudeSub;
    final StreamSubscription<RecordState>? stateSub = _stateSub;
    _amplitudeSub = null;
    _stateSub = null;
    _levelDb = null;

    try {
      await ampSub?.cancel();
    } catch (_) {}
    try {
      await stateSub?.cancel();
    } catch (_) {}
  }

  Future<void> _discardActiveRecording() async {
    final String? path = _activePath;
    _activePath = null;
    final AudioRecorder? recorder = _recorder;
    if (recorder != null) {
      try {
        await recorder.cancel();
      } catch (_) {}
    }
    await _releaseRecorder();
    if (path != null) {
      await deleteRecording(path);
    }
  }

  Future<void> _releaseRecorder() async {
    final AudioRecorder? recorder = _recorder;
    _recorder = null;
    if (recorder == null) return;
    try {
      await recorder.dispose();
    } catch (_) {}
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
    _ticker?.cancel();
    _ticker = null;
    if (_stopwatch.isRunning) _stopwatch.stop();

    final StreamSubscription<Amplitude>? ampSub = _amplitudeSub;
    final StreamSubscription<RecordState>? stateSub = _stateSub;
    final AudioRecorder? recorder = _recorder;
    final String? pending = _activePath;

    _amplitudeSub = null;
    _stateSub = null;
    _recorder = null;
    _activePath = null;

    unawaited(_disposeAsync(ampSub, stateSub, recorder, pending));
    super.dispose();
  }

  static Future<void> _disposeAsync(
    StreamSubscription<Amplitude>? ampSub,
    StreamSubscription<RecordState>? stateSub,
    AudioRecorder? recorder,
    String? pendingPath,
  ) async {
    try {
      await ampSub?.cancel();
    } catch (_) {}
    try {
      await stateSub?.cancel();
    } catch (_) {}
    if (recorder != null) {
      try {
        await recorder.dispose();
      } catch (_) {}
    }
    if (pendingPath != null) {
      await deleteRecording(pendingPath);
    }
  }
}
