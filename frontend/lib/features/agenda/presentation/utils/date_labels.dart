// Fechas en español escritas a mano, para no sumar el paquete intl solo por esto
// (decision del proyecto: dependencias minimas).

const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'];
const _monthsLong = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];
// DateTime.weekday va de 1 (lunes) a 7 (domingo).
const _weekdays = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];

/// "3:05 p. m."
String timeLabel(DateTime d) {
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minutes = d.minute.toString().padLeft(2, '0');
  final period = d.hour < 12 ? 'a. m.' : 'p. m.';
  return '$hour12:$minutes $period';
}

/// "Hoy, 3:05 p. m." / "Mañana, ..." / "20 sept, ..." (con año si no es el actual).
String dueLabel(DateTime d, {DateTime? now}) {
  final today = _dayOnly(now ?? DateTime.now());
  final days = _dayOnly(d).difference(today).inDays;

  final String day;
  if (days == 0) {
    day = 'Hoy';
  } else if (days == 1) {
    day = 'Mañana';
  } else if (days == -1) {
    day = 'Ayer';
  } else {
    final year = d.year == today.year ? '' : ' ${d.year}';
    day = '${d.day} ${_months[d.month - 1]}$year';
  }
  return '$day, ${timeLabel(d)}';
}

/// "viernes 20 de septiembre de 2026"
String longDateLabel(DateTime d) => '${_weekdays[d.weekday - 1]} ${d.day} de ${_monthsLong[d.month - 1]} de ${d.year}';

/// "Viernes 11 de septiembre" (cabecera de la agenda: sin año, con mayúscula inicial).
String headerDateLabel(DateTime d) {
  final day = _weekdays[d.weekday - 1];
  return '${day[0].toUpperCase()}${day.substring(1)} ${d.day} de ${_monthsLong[d.month - 1]}';
}

/// "VIE" (selector de días del formulario).
String weekdayShort(DateTime d) => const ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'][d.weekday - 1];

/// "11 sept" (fecha corta, sin hora).
String shortDateLabel(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// Días entre la fecha y hoy, por día calendario (0 = hoy, 1 = mañana, -1 = ayer).
int daysFromToday(DateTime d, {DateTime? now}) => _dayOnly(d).difference(_dayOnly(now ?? DateTime.now())).inDays;

// Se compara por dia calendario y no restando horas: a las 11 p. m., algo de mañana
// a la 1 a. m. esta a 2 horas pero es "Mañana", no "Hoy".
DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
