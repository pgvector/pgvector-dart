import 'dart:convert';
import 'dart:typed_data';

class Pgvector {
  const Pgvector();

  // encode as text
  String encode(List<double> input) {
    return input.toString();
  }

  // decode from binary
  // TODO find a way to make encode/decode consistent
  List<double> decode(dynamic? input) {
    // PostgresBinaryDecoder in the postgres package
    // tries to decode as utf8 for unknown types
    // sometimes it succeeds, other times it fails
    // so need to handle both cases
    if (input is String) {
      input = Uint8List.fromList(utf8.encode(input));
    }
    var bdata = new ByteData.view(input.buffer, input.offsetInBytes);
    var dim = bdata.getUint16(0);
    var unused = bdata.getUint16(2);
    if (unused != 0) {
      throw FormatException('expected unused to be 0');
    }
    var vec = <double>[];
    for (var i = 0; i < dim; i++) {
      vec.add(bdata.getFloat32(4 + i * 4));
    }
    return vec;
  }
}

const Pgvector pgvector = Pgvector();
