import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pgvector/pgvector.dart';
import 'package:postgres/postgres.dart';

Future<List<List<double>>> embed(List<String> input, String apiKey) async {
  var url = Uri.https('api.openai.com', 'v1/embeddings');
  var headers = {
    'Authorization': 'Bearer ${apiKey}',
    'Content-Type': 'application/json'
  };
  var data = {'input': input, 'model': 'text-embedding-3-small'};

  var response = await http.post(url, body: jsonEncode(data), headers: headers);
  var embeddings =
      jsonDecode(response.body)['data'].map(((v) => v['embedding'])).toList();
  return Future.value([for (var v in embeddings) List<double>.from(v)]);
}

void main() async {
  var apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null) {
    print('Set OPENAI_API_KEY');
    exit(0);
  }

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
      'CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding vector(1536))');

  var input = [
    'The dog is barking',
    'The cat is purring',
    'The bear is growling'
  ];
  var embeddings = await embed(input, apiKey);
  for (var i = 0; i < input.length; i++) {
    await connection.execute(
        Sql.named(
            'INSERT INTO documents (content, embedding) VALUES (@content, @embedding)'),
        parameters: {'content': input[i], 'embedding': Vector(embeddings[i])});
  }

  var query = 'forest';
  var queryEmbedding = (await embed([query], apiKey))[0];
  var result = await connection.execute(
      Sql.named(
          'SELECT content FROM documents ORDER BY embedding <=> @embedding LIMIT 5'),
      parameters: {'embedding': Vector(queryEmbedding)});
  for (final row in result) {
    print(row[0]);
  }

  await connection.close();
}
