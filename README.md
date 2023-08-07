# pgvector-dart

[pgvector](https://github.com/pgvector/pgvector) examples for Dart

Supports the [postgres](https://github.com/isoos/postgresql-dart) package

[![Build Status](https://github.com/pgvector/pgvector-dart/workflows/build/badge.svg?branch=master)](https://github.com/pgvector/pgvector-dart/actions)

## Getting Started

Follow the instructions for your database library:

- [postgres](#postgres)

## postgres

Create a table

```dart
await connection.execute(
    "CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3))");
```

Insert vectors

```dart
await connection.execute(
    "INSERT INTO items (embedding) VALUES (@a), (@b), (@c)",
    substitutionValues: {
      "a": [1, 1, 1].toString(),
      "b": [2, 2, 2].toString(),
      "c": [1, 1, 2].toString()
    });
```

Get the nearest neighbors

```dart
List<List<dynamic>> results = await connection.query(
    "SELECT id, embedding::text FROM items ORDER BY embedding <-> @embedding LIMIT 5",
    substitutionValues: {
      "embedding": [1, 1, 1].toString()
    });
for (final row in results) {
  print(row[0]);
  print(row[1]);
}
```

See a [full example](test/postgres_test.dart)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/pgvector/pgvector-dart/issues)
- Fix bugs and [submit pull requests](https://github.com/pgvector/pgvector-dart/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/pgvector/pgvector-dart.git
cd pgvector-dart
createdb pgvector_dart_test
dart test
```
