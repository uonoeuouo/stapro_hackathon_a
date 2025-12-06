cdimport 'dart:convert';
import 'dart:io';

/// Abstract interface for the scanning service
abstract class ScanService {
  Future<Map<String, dynamic>> scanCard(String cardId);
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

/// Real implementation using the backend API
class RealScanService implements ScanService {
  final String baseUrl;

  RealScanService({String? baseUrl}) 
      : baseUrl = baseUrl ?? (Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000');

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
        throw ApiException(response.statusCode, responseBody);
      }
    } finally {
      client.close();
    }
  }
}


