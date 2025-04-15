import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pgvector/pgvector.dart';
import 'package:postgres/postgres.dart';

Future<List<dynamic>> embed(
    List<String> texts, String inputType, String apiKey) async {
  var url = Uri.https('api.cohere.com', 'v2/embed');
  var headers = {
    'Authorization': 'Bearer ${apiKey}',
    'Content-Type': 'application/json'
  };
  var data = {
    'texts': texts,
    'model': 'embed-v4.0',
    'input_type': inputType,
    'embedding_types': ['ubinary']
  };

  var response = await http.post(url, body: jsonEncode(data), headers: headers);
  var embeddings = jsonDecode(response.body)['embeddings']['ubinary']
      .map((v) => v.map((d) => d.toRadixString(2).padLeft(8, '0')).join())
      .toList();
  return Future<List<dynamic>>.value(embeddings);
}

void main() async {
  var apiKey = Platform.environment['CO_API_KEY'];
  if (apiKey == null) {
    print('Set CO_API_KEY');
    exit(0);
  }

  var connection = await Connection.open(
      Endpoint(
          host: 'localhost',
          port: 5432,
          database: 'pgvector_example',
          username: Platform.environment['USER']),
      settings: ConnectionSettings(sslMode: SslMode.disable));

  await connection.execute('CREATE EXTENSION IF NOT EXISTS vector');

  await connection.execute('DROP TABLE IF EXISTS documents');
  await connection.execute(
      'CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding bit(1536))');

  var input = [
    'The dog is barking',
    'The cat is purring',
    'The bear is growling'
  ];
  var embeddings = await embed(input, 'search_document', apiKey);
  for (var i = 0; i < input.length; i++) {
    await connection.execute(
        Sql.named(
            'INSERT INTO documents (content, embedding) VALUES (@content, @embedding)'),
        parameters: {'content': input[i], 'embedding': embeddings[i]});
  }

  var query = 'forest';
  var queryEmbedding = (await embed([query], 'search_query', apiKey))[0];
  var result = await connection.execute(
      Sql.named(
          'SELECT content FROM documents ORDER BY embedding <~> @embedding LIMIT 5'),
      parameters: {'embedding': queryEmbedding});
  for (final row in result) {
    print(row[0]);
  }

  await connection.close();
}
