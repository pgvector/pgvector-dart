import 'dart:io';
import 'package:pgvector/pgvector.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test('works', () async {
    var connection = await Connection.open(
        Endpoint(
            host: "localhost",
            port: 5432,
            database: "pgvector_dart_test",
            username: Platform.environment["USER"]),
        settings: ConnectionSettings(sslMode: SslMode.disable));

    await connection.execute("CREATE EXTENSION IF NOT EXISTS vector");
    await connection.execute("DROP TABLE IF EXISTS items");

    await connection.execute(
        "CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3), half_embedding halfvec(3), binary_embedding bit(3), sparse_embedding sparsevec(3))");

    await connection.execute(
        Sql.named(
            "INSERT INTO items (embedding, half_embedding, binary_embedding, sparse_embedding) VALUES (@a, @d, @g, @j), (@b, @e, @h, @k), (@c, @f, @i, @l)"),
        parameters: {
          "a": Vector([1, 1, 1]).toString(),
          "b": Vector([2, 2, 2]).toString(),
          "c": Vector([1, 1, 2]).toString(),
          "d": HalfVector([1, 1, 1]).toString(),
          "e": HalfVector([2, 2, 2]).toString(),
          "f": HalfVector([1, 1, 2]).toString(),
          "g": "000",
          "h": "101",
          "i": "111",
          "j": SparseVector([1, 1, 1]).toString(),
          "k": SparseVector([2, 2, 2]).toString(),
          "l": SparseVector([1, 1, 2]).toString()
        });

    List<List<dynamic>> results = await connection.execute(
        Sql.named(
            "SELECT id, embedding, sparse_embedding FROM items ORDER BY embedding <-> @embedding LIMIT 5"),
        parameters: {
          "embedding": Vector([1, 1, 1]).toString()
        });
    for (final row in results) {
      print(row[0]);
      print(Vector.fromBinary(row[1].bytes));
      print(SparseVector.fromBinary(row[2].bytes));
    }

    await connection
        .execute("CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)");
  });
}
