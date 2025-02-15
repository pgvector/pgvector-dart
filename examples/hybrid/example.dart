import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pgvector/pgvector.dart';
import 'package:postgres/postgres.dart';

Future<List<List<double>>> fetchEmbeddings(List<String> input) async {
  var url = Uri.http('localhost:11434', 'api/embed');
  var headers = {'Content-Type': 'application/json'};
  var data = {'input': input, 'model': 'nomic-embed-text'};

  var response = await http.post(url, body: jsonEncode(data), headers: headers);
  var embeddings = jsonDecode(response.body)['embeddings'];
  return Future.value([for (var v in embeddings) List<double>.from(v)]);
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
      'CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding vector(768))');
  await connection.execute(
      "CREATE INDEX ON documents USING GIN (to_tsvector('english', content))");

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
        parameters: {'content': input[i], 'embedding': Vector(embeddings[i])});
  }

  var sql = """
  WITH semantic_search AS (
      SELECT id, RANK () OVER (ORDER BY embedding <=> @embedding) AS rank
      FROM documents
      ORDER BY embedding <=> @embedding
      LIMIT 20
  ),
  keyword_search AS (
      SELECT id, RANK () OVER (ORDER BY ts_rank_cd(to_tsvector('english', content), query) DESC)
      FROM documents, plainto_tsquery('english', @query) query
      WHERE to_tsvector('english', content) @@ query
      ORDER BY ts_rank_cd(to_tsvector('english', content), query) DESC
      LIMIT 20
  )
  SELECT
      COALESCE(semantic_search.id, keyword_search.id) AS id,
      COALESCE(1.0 / (@k + semantic_search.rank), 0.0) +
      COALESCE(1.0 / (@k + keyword_search.rank), 0.0) AS score
  FROM semantic_search
  FULL OUTER JOIN keyword_search ON semantic_search.id = keyword_search.id
  ORDER BY score DESC
  LIMIT 5
  """;
  var query = 'growling bear';
  var queryEmbedding = (await fetchEmbeddings([query]))[0];
  var k = 60;
  var result = await connection.execute(Sql.named(sql), parameters: {
    'query': query,
    'embedding': Vector(queryEmbedding),
    'k': k
  });
  for (final row in result) {
    print('document: ${row[0]}, RRF score: ${row[1]}');
  }

  await connection.close();
}
