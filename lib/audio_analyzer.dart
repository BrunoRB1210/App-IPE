import 'dart:math' as math;

import 'package:wav/wav.dart';

class AnalysisResult {
  final List<double> audioData;
  final int sampleRate;
  final List<double> frameEnergy;
  final double energyThreshold;
  final List<double> shootingTimes;
  final double? maxCadence;
  final double? minCadence;
  final double? meanCadence;

  AnalysisResult({
    required this.audioData,
    required this.sampleRate,
    required this.frameEnergy,
    required this.energyThreshold,
    required this.shootingTimes,
    this.maxCadence,
    this.minCadence,
    this.meanCadence,
  });
}

class AudioAnalyzer {
  /// Algoritmo Peak Finder compatível com o peakfinder.m do MATLAB
  static List<int> peakFinder(List<double> x, double sel) {
    List<int> peakIndices = [];
    if (x.isEmpty) return peakIndices;

    double minVal = double.infinity;
    double maxVal = -double.infinity;
    int minPos = 0;
    int maxPos = 0;
    bool lookForMax = true;

    for (int i = 0; i < x.length; i++) {
      double val = x[i];

      if (val > maxVal) {
        maxVal = val;
        maxPos = i;
      }
      if (val < minVal) {
        minVal = val;
        minPos = i;
      }

      if (lookForMax) {
        if (val < maxVal - sel) {
          if (maxVal >= sel) {
            peakIndices.add(maxPos);
          }
          minVal = val;
          minPos = i;
          lookForMax = false;
        }
      } else {
        if (val > minVal + sel) {
          maxVal = val;
          maxPos = i;
          lookForMax = true;
        }
      }
    }

    return peakIndices;
  }

  static Future<AnalysisResult> processWavFile(String path) async {
    final wav = await Wav.readFile(path);
    int fs = wav.samplesPerSecond;

    // x = x(:,1) -> Canal 1
    int numSamples = wav.channels[0].length;
    List<double> audioData = List.filled(numSamples, 0.0);

    double maxAbs = 0.0;
    for (int i = 0; i < numSamples; i++) {
      double val = wav.channels[0][i];
      audioData[i] = val;
      if (val.abs() > maxAbs) {
        maxAbs = val.abs();
      }
    }

    // x = x / max(abs(x))
    if (maxAbs > 0) {
      for (int i = 0; i < numSamples; i++) {
        audioData[i] = audioData[i] / maxAbs;
      }
    }

    // Parâmetros de detecção ajustados para o MATLAB (30 ms)
    int windowSize = (0.03 * fs).round();
    int overlap = (windowSize / 2).round(); // 50% de sobreposição
    int hopSize = windowSize - overlap;

    // Cálculo da energia por janela (x.^8)
    List<double> frameEnergy = [];
    double maxEnergy = 0.0;
    for (int i = 0; i + windowSize <= audioData.length; i += hopSize) {
      double energy = 0.0;
      for (int j = 0; j < windowSize; j++) {
        energy += math.pow(audioData[i + j], 8);
      }
      frameEnergy.add(energy);
      if (energy > maxEnergy) {
        maxEnergy = energy;
      }
    }

    // Limiar no MATLAB: max(frameEnergy) * 0.05
    double energyThreshold = maxEnergy * 0.05;

    // Localização dos picos usando peakfinder (substitui o diff(shootingEvents) == 1)
    List<int> eventIndices = peakFinder(frameEnergy, energyThreshold);

    // Cálculo dos tempos equivalentes à fórmula do MATLAB
    // shootingTimes = (eventIndices * (windowSize - overlap) + windowSize / 2) / fs;
    List<double> shootingTimes = [];
    for (int idx in eventIndices) {
      // (idx + 1) ajusta do índice 0 do Dart para o índice 1 do MATLAB
      double timeInSeconds = ((idx + 1) * hopSize + windowSize / 2) / fs;
      shootingTimes.add(timeInSeconds);
    }

    // Cálculo da cadência (filtro [1 -1] do MATLAB)
    List<double> intervals = [];
    for (int i = 1; i < shootingTimes.length; i++) {
      intervals.add(shootingTimes[i] - shootingTimes[i - 1]);
    }

    double? maxCadence, minCadence, meanCadence;
    if (intervals.isNotEmpty) {
      double minInterval = intervals.reduce(math.min);
      double maxInterval = intervals.reduce(math.max);
      double meanInterval =
          intervals.reduce((a, b) => a + b) / intervals.length;

      if (minInterval > 0) maxCadence = 60.0 / minInterval;
      if (maxInterval > 0) minCadence = 60.0 / maxInterval;
      if (meanInterval > 0) meanCadence = 60.0 / meanInterval;
    }

    return AnalysisResult(
      audioData: audioData,
      sampleRate: fs,
      frameEnergy: frameEnergy,
      energyThreshold: energyThreshold,
      shootingTimes: shootingTimes,
      maxCadence: maxCadence,
      minCadence: minCadence,
      meanCadence: meanCadence,
    );
  }
}
