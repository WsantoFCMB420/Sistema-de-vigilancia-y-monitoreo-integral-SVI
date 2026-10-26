import 'dart:typed_data';

/// Agrega la duración a un video WebM grabado con MediaRecorder.
///
/// Chrome graba el WebM "en vivo": el archivo no dice cuánto dura. Sin ese
/// dato el reproductor muestra un tiempo falso y la barra no permite
/// adelantar ni retroceder. Esta función escribe el campo Duration dentro
/// del bloque Segment > Info del archivo (formato EBML/Matroska).
///
/// Si el archivo no tiene la forma esperada, se devuelve sin cambios.
Uint8List fixWebmDuration(Uint8List bytes, Duration duration) {
  try {
    return _fix(bytes, duration) ?? bytes;
  } catch (_) {
    return bytes;
  }
}

const int _idSegment = 0x18538067;
const int _idInfo = 0x1549A966;
const int _idDuration = 0x4489;
const int _idTimecodeScale = 0x2AD7B1;

class _Vint {
  final int value;
  final int length;
  final bool unknown;
  const _Vint(this.value, this.length, this.unknown);
}

/// ID de elemento EBML: se lee conservando el bit marcador.
_Vint _readId(Uint8List b, int pos) {
  final first = b[pos];
  int length = 1;
  int mask = 0x80;
  while (length <= 4 && (first & mask) == 0) {
    mask >>= 1;
    length++;
  }
  if (length > 4) throw const FormatException('ID EBML inválido');
  int value = 0;
  for (int i = 0; i < length; i++) {
    value = (value << 8) | b[pos + i];
  }
  return _Vint(value, length, false);
}

/// Tamaño EBML: se lee sin el bit marcador. Todo en 1 significa "desconocido".
_Vint _readSize(Uint8List b, int pos) {
  final first = b[pos];
  int length = 1;
  int mask = 0x80;
  while (length <= 8 && (first & mask) == 0) {
    mask >>= 1;
    length++;
  }
  if (length > 8) throw const FormatException('Tamaño EBML inválido');
  int value = first & (mask - 1);
  bool allOnes = value == mask - 1;
  for (int i = 1; i < length; i++) {
    value = (value << 8) | b[pos + i];
    if (b[pos + i] != 0xFF) allOnes = false;
  }
  return _Vint(value, length, allOnes);
}

/// Tamaño EBML escrito siempre con 8 bytes (0x01 + 7 bytes de valor).
List<int> _size8(int value) {
  final out = List<int>.filled(8, 0);
  out[0] = 0x01;
  int v = value;
  for (int i = 7; i >= 1; i--) {
    out[i] = v & 0xFF;
    v >>= 8;
  }
  return out;
}

Uint8List? _fix(Uint8List b, Duration duration) {
  int pos = 0;

  // 1. Saltar la cabecera EBML y ubicar el Segment.
  int segmentDataStart = -1;
  _Vint? segmentSize;
  while (pos < b.length) {
    final id = _readId(b, pos);
    final size = _readSize(b, pos + id.length);
    final dataStart = pos + id.length + size.length;
    if (id.value == _idSegment) {
      segmentSize = size;
      segmentDataStart = dataStart;
      break;
    }
    pos = dataStart + size.value;
  }
  if (segmentDataStart < 0 || segmentSize == null) return null;
  // Solo se corrigen archivos "en vivo" (tamaño de Segment desconocido), que es
  // como graba MediaRecorder. Un WebM normal ya trae su duración, y moverle
  // bytes desajustaría su índice (SeekHead).
  if (!segmentSize.unknown) return null;

  // 2. Buscar Info dentro del Segment.
  pos = segmentDataStart;
  int infoStart = -1;
  int infoDataStart = -1;
  int infoEnd = -1;
  while (pos < b.length) {
    final id = _readId(b, pos);
    final size = _readSize(b, pos + id.length);
    final dataStart = pos + id.length + size.length;
    if (id.value == _idInfo) {
      if (size.unknown) return null;
      infoStart = pos;
      infoDataStart = dataStart;
      infoEnd = dataStart + size.value;
      break;
    }
    if (size.unknown) return null; // llegó a un Cluster sin encontrar Info
    pos = dataStart + size.value;
  }
  if (infoStart < 0 || infoEnd > b.length) return null;

  // 3. Copiar los hijos de Info sin el Duration viejo y leer la escala de tiempo.
  int timecodeScale = 1000000; // valor por defecto: milisegundos
  final children = BytesBuilder(copy: false);
  pos = infoDataStart;
  while (pos < infoEnd) {
    final id = _readId(b, pos);
    final size = _readSize(b, pos + id.length);
    final dataStart = pos + id.length + size.length;
    final end = dataStart + size.value;
    if (id.value == _idTimecodeScale) {
      int v = 0;
      for (int i = dataStart; i < end; i++) {
        v = (v << 8) | b[i];
      }
      if (v > 0) timecodeScale = v;
    }
    if (id.value != _idDuration) {
      children.add(Uint8List.sublistView(b, pos, end));
    }
    pos = end;
  }

  // 4. Nuevo Duration (float de 8 bytes, en unidades de la escala de tiempo).
  final units = duration.inMicroseconds * 1000 / timecodeScale;
  final durationData = ByteData(8)..setFloat64(0, units);
  children.add([0x44, 0x89, 0x88]); // ID Duration + tamaño 8
  children.add(durationData.buffer.asUint8List());

  final newInfoData = children.takeBytes();
  final newInfo = BytesBuilder(copy: false)
    ..add([0x15, 0x49, 0xA9, 0x66])
    ..add(_size8(newInfoData.length))
    ..add(newInfoData);
  final newInfoBytes = newInfo.takeBytes();

  // 5. Armar el archivo con el nuevo bloque Info.
  final out = BytesBuilder(copy: false)
    ..add(Uint8List.sublistView(b, 0, infoStart))
    ..add(newInfoBytes);
  out.add(Uint8List.sublistView(b, infoEnd));
  return out.takeBytes();
}
