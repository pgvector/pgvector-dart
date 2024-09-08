import 'dart:typed_data';

class Vector {
  final List<double> vec;

  const Vector(this.vec);

  factory Vector.fromBinary(Uint8List bytes) {
    var bdata = new ByteData.view(bytes.buffer, bytes.offsetInBytes);
    var dim = bdata.getUint16(0);
    var unused = bdata.getUint16(2);
    if (unused != 0) {
      throw FormatException('expected unused to be 0');
    }
    var vec = <double>[];
    for (var i = 0; i < dim; i++) {
      vec.add(bdata.getFloat32(4 + i * 4));
    }
    return Vector(vec);
  }

  List<double> toList() {
    return vec;
  }

  @override
  String toString() {
    return vec.toString();
  }
}
