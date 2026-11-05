/// Formatação de valores para exibição (pt-BR). Apenas apresentação.
library;

/// Formata um número com [decimals] casas e vírgula decimal.
String formatDecimal(double value, {int decimals = 1}) =>
    value.toStringAsFixed(decimals).replaceAll('.', ',');

/// Cronômetro no formato `mm:ss.d`.
String formatClock(Duration duration) {
  final String minutes = duration.inMinutes.toString().padLeft(2, '0');
  final String seconds =
      duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final int tenths = duration.inMilliseconds.remainder(1000) ~/ 100;
  return '$minutes:$seconds.$tenths';
}

/// Duração em segundos no formato `12,3 s`.
String formatSeconds(double seconds, {int decimals = 1}) =>
    '${formatDecimal(seconds, decimals: decimals)} s';
