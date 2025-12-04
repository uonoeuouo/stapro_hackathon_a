import 'dart:convert';
import 'dart:io';

/// Abstract interface for the scanning service
abstract class ScanService {
  Future<Map<String, dynamic>> scanCard(String cardId);
}

/// Real implementation using the backend API
class RealScanService implements ScanService {
  final String baseUrl;

  RealScanService({this.baseUrl = 'http://127.0.0.1:8000'});

  @override
  Future<Map<String, dynamic>> scanCard(String cardId) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse('$baseUrl/api/scan'));
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
      request.add(utf8.encode(jsonEncode({'card_id': cardId})));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        throw Exception('Server returned ${response.statusCode}: $responseBody');
      }
    } finally {
      client.close();
    }
  }
}


