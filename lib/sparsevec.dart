import 'dart:typed_data';

class SparseVector {
  final int dimensions;
  final List<int> indices;
  final List<double> values;

  SparseVector._(this.dimensions, this.indices, this.values);

  factory SparseVector(List<double> value) {
    var dimensions = value.length;
    var indices = <int>[];
    var values = <double>[];

    for (var i = 0; i < value.length; i++) {
      if (value[i] != 0) {
        indices.add(i);
        values.add(value[i]);
      }
    }

    return SparseVector._(dimensions, indices, values);
  }

  factory SparseVector.fromBinary(Uint8List bytes) {
    var buf = new ByteData.view(bytes.buffer, bytes.offsetInBytes);
    var dimensions = buf.getInt32(0);
    var nnz = buf.getInt32(4);

    var unused = buf.getInt32(8);
    if (unused != 0) {
      throw FormatException('expected unused to be 0');
    }

    var indices = <int>[];
    for (var i = 0; i < nnz; i++) {
      indices.add(buf.getInt32(12 + i * 4));
    }

    var values = <double>[];
    for (var i = 0; i < nnz; i++) {
      values.add(buf.getFloat32(12 + 4 * nnz + i * 4));
    }

    return SparseVector._(dimensions, indices, values);
  }

  List<double> toList() {
    var vec = List<double>.filled(dimensions, 0.0);
    for (var i = 0; i < indices.length; i++) {
      vec[indices[i]] = values[i];
    }
    return vec;
  }

  @override
  String toString() {
    var elements = [
      for (var i = 0; i < indices.length; i++) '${indices[i] + 1}:${values[i]}'
    ].join(',');
    return '{${elements}}/${dimensions}';
  }
}
