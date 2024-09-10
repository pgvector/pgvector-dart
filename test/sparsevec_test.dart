import 'package:pgvector/pgvector.dart';
import 'package:test/test.dart';

void main() {
  test('works', () {
    var vec = SparseVector([1, 0, 2, 0, 3, 0]);
    expect(vec.toString(), equals('{1:1.0,3:2.0,5:3.0}/6'));
    expect(vec.toList(), equals([1, 0, 2, 0, 3, 0]));
    expect(vec.dimensions, equals(6));
    expect(vec.indices, equals([0, 2, 4]));
    expect(vec.values, equals([1, 2, 3]));
  });
}
