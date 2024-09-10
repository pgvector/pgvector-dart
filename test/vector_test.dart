import 'package:pgvector/pgvector.dart';
import 'package:test/test.dart';

void main() {
  test('works', () {
    var vec = Vector([1, 2, 3]);
    expect(vec.toString(), equals('[1.0, 2.0, 3.0]'));
    expect(vec.toList(), equals([1, 2, 3]));
  });

  test('equals', () {
    var a = Vector([1, 2, 3]);
    var b = Vector([1, 2, 3]);
    var c = Vector([1, 2, 4]);

    expect(a, equals(b));
    expect(a, isNot(equals(c)));
  });
}
