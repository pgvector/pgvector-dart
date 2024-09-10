class HalfVector {
  final List<double> _vec;

  const HalfVector(this._vec);

  List<double> toList() {
    return _vec;
  }

  @override
  String toString() {
    return _vec.toString();
  }
}
