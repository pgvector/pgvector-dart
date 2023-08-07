import 'dart:convert';
import 'dart:io';
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
          "a": [1, 1, 1].toString(),
          "b": [2, 2, 2].toString(),
          "c": [1, 1, 2].toString()
        });

    List<List<dynamic>> results = await connection.query(
        "SELECT id, embedding::text FROM items ORDER BY embedding <-> @embedding LIMIT 5",
        substitutionValues: {
          "embedding": [1, 1, 1].toString()
        });
    for (final row in results) {
      print(row[0]);
      print(jsonDecode(row[1]));
    }
  });
}
