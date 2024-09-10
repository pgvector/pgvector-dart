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

  @override
  String toString() {
    var elements = [
      for (var i = 0; i < indices.length; i++) "${indices[i] + 1}:${values[i]}"
    ].join(",");
    return "{${elements}}/${this.dimensions}";
  }
}
