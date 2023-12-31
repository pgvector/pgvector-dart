import 'dart:io';
import 'package:pgvector/pgvector.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test('works', () async {
    var connection = PostgreSQLConnection(
        "localhost", 5432, "pgvector_dart_test",
        username: Platform.environment["USER"]);
    await connection.open();

    await connection.execute("CREATE EXTENSION IF NOT EXISTS vector");
    await connection.execute("DROP TABLE IF EXISTS items");

    await connection.execute(
        "CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3))");

    await connection.execute(
        "INSERT INTO items (embedding) VALUES (@a), (@b), (@c)",
        substitutionValues: {
          "a": pgvector.encode([1, 1, 1]),
          "b": pgvector.encode([2, 2, 2]),
          "c": pgvector.encode([1, 1, 2])
        });

    List<List<dynamic>> results = await connection.query(
        "SELECT id, embedding FROM items ORDER BY embedding <-> @embedding LIMIT 5",
        substitutionValues: {
          "embedding": pgvector.encode([1, 1, 1])
        });
    for (final row in results) {
      print(row[0]);
      print(pgvector.decode(row[1]));
    }

    await connection
        .execute("CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)");
  });
}
