/// Formatação de valores e Grupo Data-Hora (GDH) para exibição (pt-BR).
/// Camada estritamente de apresentação e nomenclatura de arquivo.
library;

const List<String> _kMonthsPtBr = <String>[
  'JAN',
  'FEV',
  'MAR',
  'ABR',
  'MAI',
  'JUN',
  'JUL',
  'AGO',
  'SET',
  'OUT',
  'NOV',
  'DEZ',
];

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

/// Formata um [DateTime] no padrão militar GDH (Grupo Data-Hora):
/// `DDHHMM` + `MMM` + `AA` (ex.: `042316NOV26`).
String formatGdh(DateTime dateTime) {
  final DateTime local = dateTime.toLocal();
  final String day = local.day.toString().padLeft(2, '0');
  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');
  final String month = _kMonthsPtBr[local.month - 1];
  final String year = (local.year % 100).toString().padLeft(2, '0');
  return '$day$hour$minute$month$year';
}

/// Formata data e hora legível (`DD/MM/AAAA HH:MM:SS`).
String formatDateTimeBr(DateTime dateTime) {
  final DateTime local = dateTime.toLocal();
  final String d = local.day.toString().padLeft(2, '0');
  final String m = local.month.toString().padLeft(2, '0');
  final String y = local.year.toString();
  final String hh = local.hour.toString().padLeft(2, '0');
  final String mm = local.minute.toString().padLeft(2, '0');
  final String ss = local.second.toString().padLeft(2, '0');
  return '$d/$m/$y $hh:$mm:$ss';
}

/// Gera nome de arquivo WAV padronizado com o armamento e o GDH do registro.
/// Exemplo: `ArsenalWave_FAL_GDH_042316NOV26_52s.wav`.
String buildGdhWavFileName({
  required String weaponName,
  required DateTime timestamp,
}) {
  final String sanitizedWeapon =
      weaponName.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  final String gdh = formatGdh(timestamp);
  final String sec = timestamp.toLocal().second.toString().padLeft(2, '0');
  return 'ArsenalWave_${sanitizedWeapon}_GDH_${gdh}_${sec}s.wav';
}
