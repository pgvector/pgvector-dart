import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'bit.dart';
import 'halfvec.dart';
import 'sparsevec.dart';
import 'vector.dart';

EncodedValue? pgvectorEncoder(TypedValue input, CodecContext context) {
  final value = input.value;

  if (value is Vector) {
    final v = value as Vector;
    return EncodedValue.binary(v.toBinary());
  }

  if (value is HalfVector) {
    final v = value as HalfVector;
    return EncodedValue.text(utf8.encode(v.toString()));
  }

  if (value is Bit) {
    final v = value as Bit;
    return EncodedValue.binary(v.toBinary());
  }

  if (value is SparseVector) {
    final v = value as SparseVector;
    return EncodedValue.binary(v.toBinary());
  }

  return null;
}
