class HalfVector {
  final List<double> vec;

  const HalfVector(this.vec);

  List<double> toList() {
    return vec;
  }

  @override
  String toString() {
    return vec.toString();
  }
}
