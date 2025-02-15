// good resources
// https://opensearch.org/blog/improving-document-retrieval-with-sparse-semantic-encoders/
// https://huggingface.co/opensearch-project/opensearch-neural-sparse-encoding-v1
//
// run with
// text-embeddings-router --model-id opensearch-project/opensearch-neural-sparse-encoding-v1 --pooling splade

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pgvector/pgvector.dart';
import 'package:postgres/postgres.dart';

Future<List<dynamic>> fetchEmbeddings(List<String> inputs) async {
  var url = Uri.http('localhost:3000', 'embed_sparse');
  var headers = {'Content-Type': 'application/json'};
  var data = {'inputs': inputs};

  var response = await http.post(url, body: jsonEncode(data), headers: headers);
  var embeddings = jsonDecode(response.body)
      .map((v) => <int, double>{for (var e in v) e['index']: e['value']})
      .toList();
  return Future<List<dynamic>>.value(embeddings);
}

void main() async {
  var connection = await Connection.open(
      Endpoint(
          host: 'localhost',
          port: 5432,
          database: 'pgvector_example',
          username: Platform.environment['USER']),
      settings: ConnectionSettings(
          sslMode: SslMode.disable,
          typeRegistry: TypeRegistry(encoders: [pgvectorEncoder])));

  await connection.execute('CREATE EXTENSION IF NOT EXISTS vector');

  await connection.execute('DROP TABLE IF EXISTS documents');
  await connection.execute(
      'CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding sparsevec(30522))');

  var input = [
    'The dog is barking',
    'The cat is purring',
    'The bear is growling'
  ];
  var embeddings = await fetchEmbeddings(input);
  for (var i = 0; i < input.length; i++) {
    await connection.execute(
        Sql.named(
            'INSERT INTO documents (content, embedding) VALUES (@content, @embedding)'),
        parameters: {
          'content': input[i],
          'embedding': SparseVector.fromMap(embeddings[i], 30522)
        });
  }

  var query = 'forest';
  var queryEmbedding = (await fetchEmbeddings([query]))[0];
  var result = await connection.execute(
      Sql.named(
          'SELECT content FROM documents ORDER BY embedding <#> @embedding LIMIT 5'),
      parameters: {'embedding': SparseVector.fromMap(queryEmbedding, 30522)});
  for (final row in result) {
    print(row[0]);
  }

  await connection.close();
}
