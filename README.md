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

Or check out some examples:

- [Embeddings](https://github.com/pgvector/pgvector-dart/blob/master/examples/openai/example.dart) with OpenAI
- [Binary embeddings](https://github.com/pgvector/pgvector-dart/blob/master/examples/cohere/example.dart) with Cohere
- [Hybrid search](https://github.com/pgvector/pgvector-dart/blob/master/examples/hybrid/example.dart) with Ollama (Reciprocal Rank Fusion)
- [Sparse search](https://github.com/pgvector/pgvector-dart/blob/master/examples/sparse/example.dart) with Text Embeddings Inference

## postgres

Import the library

```dart
import 'package:pgvector/pgvector.dart';
```

Add the encoder

```dart
var connection = await Connection.open(endpoint,
    settings: ConnectionSettings(
        typeRegistry: TypeRegistry(encoders: [pgvectorEncoder])));
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
      'a': Vector([1, 1, 1]),
      'b': Vector([2, 2, 2]),
      'c': Vector([1, 1, 2])
    });
```

Get the nearest neighbors

```dart
List<List<dynamic>> results = await connection.execute(
    Sql.named('SELECT id, embedding FROM items ORDER BY embedding <-> @embedding LIMIT 5'),
    parameters: {
      'embedding': Vector([1, 1, 1])
    });
for (final row in results) {
  print(row[0]);
  print(Vector.fromBinary(row[1].bytes));
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

## Reference

### Vectors

Create a vector from a list

```dart
var vec = Vector([1, 2, 3]);
```

Get a list

```dart
var list = vec.toList();
```

### Half Vectors

Create a half vector from a list

```dart
var vec = HalfVector([1, 2, 3]);
```

Get a list

```dart
var list = vec.toList();
```

### Binary Vectors

Create a binary vector from a list

```dart
var vec = Bit([true, false, true]);
```

Or a string

```dart
var vec = Bit("101");
```

Get a list

```dart
var list = vec.toList();
```

Get a string

```dart
var str = vec.toString();
```

### Sparse Vectors

Create a sparse vector from a list

```dart
var vec = SparseVector([1, 0, 2, 0, 3, 0]);
```

Or a map of non-zero elements

```dart
var vec = SparseVector.fromMap({0: 1.0, 2: 2.0, 4: 3.0}, 6);
```

Note: Indices start at 0

Get the number of dimensions

```dart
var dim = vec.dimensions;
```

Get the indices of non-zero elements

```dart
var indices = vec.indices;
```

Get the values of non-zero elements

```dart
var values = vec.values;
```

Get a list

```dart
var list = vec.toList();
```

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
dart pub get
dart run example.dart
```
