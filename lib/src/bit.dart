import 'dart:typed_data';
import 'utils.dart';

class Bit {
  final List<bool> _vec;

  const Bit(this._vec);

  factory Bit.fromBinary(Uint8List bytes) {
    var buf = new ByteData.view(bytes.buffer, bytes.offsetInBytes);
    var length = buf.getInt32(0);

    var vec = <bool>[];
    for (var i = 0; i < length; i++) {
      vec.add((bytes[4 + (i / 8).toInt()] >> (7 - (i % 8))) & 1 == 1);
    }

    return Bit(vec);
  }

  List<bool> toList() {
    return _vec;
  }

  @override
  String toString() {
    return _vec.map((v) => v ? '1' : '0').join();
  }

  @override
  bool operator ==(Object other) =>
      other is Bit && listEquals(other._vec, _vec);

  @override
  int get hashCode => _vec.hashCode;
}
