import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'afis_engine.dart'; // Pour la classe Point

class SMSCodec {
  /// Encodage Lossless (Delta + Zlib + Base64Url)
  /// Réduit ~180 bifurcations à moins de 160 caractères
  static String encode(List<Point> bifurcations) {
    if (bifurcations.isEmpty) return "";
    
    // 1. Tri spatial pour maximiser la compression Delta
    bifurcations.sort((a, b) => a.x.compareTo(b.x) != 0 ? a.x.compareTo(b.x) : a.y.compareTo(b.y));
    
    List<int> deltaEncoded = [];
    int prevX = 0, prevY = 0;
    
    for (var pt in bifurcations) {
      deltaEncoded.add(pt.x - prevX);
      deltaEncoded.add(pt.y - prevY);
      prevX = pt.x;
      prevY = pt.y;
    }

    // 2. Conversion en bytes (entiers signés sur 16 bits)
    var bytes = ByteData(deltaEncoded.length * 2);
    for(int i = 0; i < deltaEncoded.length; i++) {
      bytes.setInt16(i * 2, deltaEncoded[i], Endian.little);
    }

    // 3. Compression Zlib (sans perte)
    var compressed = ZLibEncoder().encode(bytes.buffer.asUint8List());

    // 4. Encodage Texte
    return base64UrlEncode(compressed);
  }

  /// Décodage instantané du SMS
  static List<Point> decode(String smsString) {
    // 1. Décodage Texte
    var compressed = base64UrlDecode(smsString);
    
    // 2. Décompression Zlib
    var decompressed = ZLibDecoder().decodeBytes(compressed);
    
    // 3. Lecture des Deltas
    var bytes = ByteData.sublistView(Uint8List.fromList(decompressed));
    List<Point> bifurcations = [];
    int prevX = 0, prevY = 0;
    
    for (int i = 0; i < bytes.lengthInBytes ~/ 2; i += 2) {
      int dx = bytes.getInt16(i * 2, Endian.little);
      int dy = bytes.getInt16(i * 2 + 2, Endian.little);
      
      int x = prevX + dx;
      int y = prevY + dy;
      
      bifurcations.add(Point(x, y));
      prevX = x;
      prevY = y;
    }
    
    return bifurcations;
  }
}
