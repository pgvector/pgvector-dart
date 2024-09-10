# pgvector-dart

[pgvector](https://github.com/pgvector/pgvector) support for Dart

Supports the [postgres](https://github.com/isoos/postgresql-dart) package

[![Build Status](https://github.com/pgvector/pgvector-dart/actions/workflows/build.yml/badge.svg)](https://github.com/pgvector/pgvector-dart/actions)

## Getting Started

Run:

```sh
dart pub add pgvector
```

And follow the instructions for your database library:

- [postgres](#postgres)

Or check out an example:

- [Embeddings](https://github.com/pgvector/pgvector-dart/blob/master/examples/openai/example.dart) with OpenAI

## postgres

Import the library

```dart
import 'package:pgvector/pgvector.dart';
```

Enable the extension

```dart
await connection.execute('CREATE EXTENSION IF NOT EXISTS vector');
```

Create a table

```dart
await connection.execute('CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3))');
```

Insert vectors

```dart
await connection.execute(
    Sql.named('INSERT INTO items (embedding) VALUES (@a), (@b), (@c)'),
    parameters: {
      'a': pgvector.encode([1, 1, 1]),
      'b': pgvector.encode([2, 2, 2]),
      'c': pgvector.encode([1, 1, 2])
    });
```

Get the nearest neighbors

```dart
List<List<dynamic>> results = await connection.execute(
    Sql.named('SELECT id, embedding FROM items ORDER BY embedding <-> @embedding LIMIT 5'),
    parameters: {
      'embedding': pgvector.encode([1, 1, 1])
    });
for (final row in results) {
  print(row[0]);
  print(pgvector.decode(row[1].bytes));
}
```

Add an approximate index

```dart
await connection.execute('CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)');
// or
await connection.execute('CREATE INDEX ON items USING ivfflat (embedding vector_l2_ops) WITH (lists = 100)');
```

Use `vector_ip_ops` for inner product and `vector_cosine_ops` for cosine distance

See a [full example](test/postgres_test.dart)

## History

View the [changelog](https://github.com/pgvector/pgvector-dart/blob/master/CHANGELOG.md)

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

To run an example:

```sh
cd examples/openai
createdb pgvector_example
dart run example.dart
```
