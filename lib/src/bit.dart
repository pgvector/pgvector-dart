import 'dart:typed_data';
import 'utils.dart';

class Bit {
  final int _len;
  final Uint8List _data;

  const Bit._(this._len, this._data);

  factory Bit(List<bool> value) {
    var length = value.length;
    var data = Uint8List(((length + 7) / 8).toInt());
    for (var i = 0; i < length; i++) {
      data[(i / 8).toInt()] |= (value[i] ? 1 : 0) << (7 - (i % 8));
    }
    return Bit._(length, data);
  }

  factory Bit.fromBinary(Uint8List bytes) {
    var buf = new ByteData.view(bytes.buffer, bytes.offsetInBytes);
    var length = buf.getInt32(0);
    return Bit._(length, Uint8List.sublistView(bytes, 4));
  }

  List<bool> toList() {
    var vec = <bool>[];
    for (var i = 0; i < _len; i++) {
      vec.add((_data[(i / 8).toInt()] >> (7 - (i % 8))) & 1 == 1);
    }
    return vec;
  }

  @override
  String toString() {
    return toList().map((v) => v ? '1' : '0').join();
  }

  @override
  bool operator ==(Object other) =>
      other is Bit && other._len == _len && listEquals(other._data, _data);

  @override
  int get hashCode => Object.hash(_len, _data);
}
