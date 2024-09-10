import 'dart:io';
import 'package:pgvector/pgvector.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test('works', () async {
    var connection = await Connection.open(
        Endpoint(
            host: 'localhost',
            port: 5432,
            database: 'pgvector_dart_test',
            username: Platform.environment['USER']),
        settings: ConnectionSettings(sslMode: SslMode.disable));

    await connection.execute('CREATE EXTENSION IF NOT EXISTS vector');
    await connection.execute('DROP TABLE IF EXISTS items');

    await connection.execute(
        'CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3), half_embedding halfvec(3), binary_embedding bit(3), sparse_embedding sparsevec(3))');

    await connection.execute(
        Sql.named(
            'INSERT INTO items (embedding, half_embedding, binary_embedding, sparse_embedding) VALUES (@embedding1, @half_embedding1, @binary_embedding1, @sparse_embedding1), (@embedding2, @half_embedding2, @binary_embedding2, @sparse_embedding2), (@embedding3, @half_embedding3, @binary_embedding3, @sparse_embedding3)'),
        parameters: {
          'embedding1': Vector([1, 1, 1]).toString(),
          'embedding2': Vector([2, 2, 2]).toString(),
          'embedding3': Vector([1, 1, 2]).toString(),
          'half_embedding1': HalfVector([1, 1, 1]).toString(),
          'half_embedding2': HalfVector([2, 2, 2]).toString(),
          'half_embedding3': HalfVector([1, 1, 2]).toString(),
          'binary_embedding1': '000',
          'binary_embedding2': '101',
          'binary_embedding3': '111',
          'sparse_embedding1': SparseVector([1, 1, 1]).toString(),
          'sparse_embedding2': SparseVector([2, 2, 2]).toString(),
          'sparse_embedding3': SparseVector([1, 1, 2]).toString()
        });

    List<List<dynamic>> results = await connection.execute(
        Sql.named(
            'SELECT id, embedding, sparse_embedding FROM items ORDER BY embedding <-> @embedding LIMIT 5'),
        parameters: {
          'embedding': Vector([1, 1, 1]).toString()
        });
    expect(results.map((r) => r[0]), equals([1, 3, 2]));
    expect(Vector.fromBinary(results[1][1].bytes), equals(Vector([1, 1, 2])));
    expect(SparseVector.fromBinary(results[1][2].bytes),
        equals(SparseVector([1, 1, 2])));

    await connection
        .execute('CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)');
  });
}
