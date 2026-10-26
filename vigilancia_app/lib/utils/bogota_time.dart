/// Hora oficial de Colombia: Bogotá, Bogotá D.C. (UTC-5, sin horario de verano).
///
/// Las fechas del backend llegan en UTC. Aquí se convierten a Bogotá de forma
/// fija, así web y APK muestran la misma hora aunque el navegador o el
/// celular estén configurados en otra zona horaria.
class BogotaTime {
  static const Duration offset = Duration(hours: -5);

  static const List<String> _months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  /// Momento actual expresado en hora de Bogotá.
  /// El DateTime resultante es "de pared": sus campos (hour, day…) ya son los de Bogotá.
  static DateTime now() => _wall(DateTime.now().toUtc().add(offset));

  /// Convierte un ISO-8601 del backend a hora de Bogotá.
  /// Si el texto no trae zona (sin "Z" ni "+hh:mm") se asume UTC, que es como
  /// Laravel guarda las fechas.
  static DateTime? parse(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    var text = iso.trim().replaceFirst(' ', 'T');
    final hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(text);
    if (!hasZone) text = '${text}Z';
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    return _wall(parsed.toUtc().add(offset));
  }

  /// Usa la fecha/hora local que ya calcula el backend; si no viene, convierte el ISO.
  static DateTime fromApi({String? iso, String? localDate, String? localTime}) {
    if (localDate != null && localDate.isNotEmpty && localTime != null && localTime.isNotEmpty) {
      final d = DateTime.tryParse('${localDate}T$localTime:00Z');
      if (d != null) return d;
    }
    return parse(iso) ?? now();
  }

  /// 13:05 → "1:05 p. m."
  static String hourLabel(DateTime t) {
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final mm = t.minute.toString().padLeft(2, '0');
    final suffix = t.hour < 12 ? 'a. m.' : 'p. m.';
    return '$h12:$mm $suffix';
  }

  /// "Hoy", "Ayer" o "25 oct 2026".
  static String dayLabel(DateTime t) {
    final today = now();
    final d0 = DateTime.utc(today.year, today.month, today.day);
    final d1 = DateTime.utc(t.year, t.month, t.day);
    final diff = d0.difference(d1).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return '${t.day} ${_months[t.month - 1]} ${t.year}';
  }

  /// "25 oct 2026, 1:05 p. m."
  static String full(DateTime t) => '${t.day} ${_months[t.month - 1]} ${t.year}, ${hourLabel(t)}';

  // "Hora de pared": se guarda como DateTime UTC para que los campos se lean
  // tal cual y no les afecte la zona horaria ni el horario de verano del equipo.
  static DateTime _wall(DateTime utcShifted) => DateTime.utc(
        utcShifted.year,
        utcShifted.month,
        utcShifted.day,
        utcShifted.hour,
        utcShifted.minute,
        utcShifted.second,
      );
}
