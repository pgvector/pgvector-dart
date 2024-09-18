import 'dart:io';
import 'package:pgvector/pgvector.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

class VectorCodec extends Codec {
  @override
  EncodedValue? encode(TypedValue input, CodecContext context) {
    final value = input.value;
    if (value == null) {
      return null;
    }
    final v = value as Vector;
    return EncodedValue.binary(v.toBinary());
  }

  @override
  Vector? decode(EncodedValue input, CodecContext context) {
    final bytes = input.bytes;
    if (bytes == null) {
      return null;
    }
    return Vector.fromBinary(bytes);
  }
}

class SparseVectorCodec extends Codec {
  @override
  EncodedValue? encode(TypedValue input, CodecContext context) {
    final value = input.value;
    if (value == null) {
      return null;
    }
    final v = value as SparseVector;
    return EncodedValue.binary(v.toBinary());
  }

  @override
  SparseVector? decode(EncodedValue input, CodecContext context) {
    final bytes = input.bytes;
    if (bytes == null) {
      return null;
    }
    return SparseVector.fromBinary(bytes);
  }
}

class BitCodec extends Codec {
  @override
  EncodedValue? encode(TypedValue input, CodecContext context) {
    final value = input.value;
    if (value == null) {
      return null;
    }
    final v = value as Bit;
    return EncodedValue.binary(v.toBinary());
  }

  @override
  Bit? decode(EncodedValue input, CodecContext context) {
    final bytes = input.bytes;
    if (bytes == null) {
      return null;
    }
    return Bit.fromBinary(bytes);
  }
}

EncodedValue? PgvectorEncoder(TypedValue input, CodecContext context) {
  if (input.value is Vector) {
    return VectorCodec().encode(input, context);
  }
  if (input.value is SparseVector) {
    return SparseVectorCodec().encode(input, context);
  }
  if (input.value is Bit) {
    return BitCodec().encode(input, context);
  }
  return null;
}

void main() {
  test('works', () async {
    var connection = await Connection.open(
        Endpoint(
            host: 'localhost',
            port: 5432,
            database: 'pgvector_dart_test',
            username: Platform.environment['USER']),
        settings: ConnectionSettings(
            sslMode: SslMode.disable,
            typeRegistry: TypeRegistry(codecs: {
              10455062: VectorCodec(),
              10455310: SparseVectorCodec(),
              1560: BitCodec()
            }, encoders: [
              PgvectorEncoder
            ])));

    await connection.execute('CREATE EXTENSION IF NOT EXISTS vector');
    await connection.execute('DROP TABLE IF EXISTS items');

    await connection.execute(
        'CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3), half_embedding halfvec(3), binary_embedding bit(3), sparse_embedding sparsevec(3))');

    await connection.execute(
        Sql.named(
            'INSERT INTO items (embedding, half_embedding, binary_embedding, sparse_embedding) VALUES (@embedding1, @half_embedding1, @binary_embedding1, @sparse_embedding1), (@embedding2, @half_embedding2, @binary_embedding2, @sparse_embedding2), (@embedding3, @half_embedding3, @binary_embedding3, @sparse_embedding3)'),
        parameters: {
          'embedding1': Vector([1, 1, 1]),
          'embedding2': Vector([2, 2, 2]),
          'embedding3': Vector([1, 1, 2]),
          'half_embedding1': HalfVector([1, 1, 1]).toString(),
          'half_embedding2': HalfVector([2, 2, 2]).toString(),
          'half_embedding3': HalfVector([1, 1, 2]).toString(),
          'binary_embedding1': Bit([false, false, false]),
          'binary_embedding2': Bit([true, false, true]),
          'binary_embedding3': Bit([true, true, true]),
          'sparse_embedding1': SparseVector([1, 1, 1]).toString(),
          'sparse_embedding2': SparseVector([2, 2, 2]).toString(),
          'sparse_embedding3': SparseVector([1, 1, 2]).toString()
        });

    List<List<dynamic>> results = await connection.execute(
        Sql.named(
            'SELECT id, embedding, binary_embedding, sparse_embedding FROM items ORDER BY embedding <-> @embedding LIMIT 5'),
        parameters: {
          'embedding': Vector([1, 1, 1])
        });
    expect(results.map((r) => r[0]), equals([1, 3, 2]));
    expect(results[1][1], equals(Vector([1, 1, 2])));
    expect(results[2][2], equals(Bit([true, false, true])));
    expect(results[1][3], equals(SparseVector([1, 1, 2])));

    await connection
        .execute('CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)');
  });
}
