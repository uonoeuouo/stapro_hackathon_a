import 'package:dio/dio.dart';
import 'package:openapi/openapi.dart';
import '../models/scan_response.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late final Openapi _apiClient;
  late final DefaultApi _defaultApi;

  // Backend API base URL - デフォルトはlocalhost
  static const String baseUrl = 'http://localhost:8000';

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    // Dio インスタンスを作成
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // OpenAPI クライアントを初期化
    _apiClient = Openapi(dio: dio);
    _defaultApi = _apiClient.getDefaultApi();
  }

  /// カードスキャンAPIを呼び出す
  /// 
  /// Returns: ScanResponse
  /// Throws: DioException (404 for unregistered cards, network errors, etc.)
  Future<ScanResponse> scanCard(String cardId) async {
    try {
      // ScanRequest を作成
      final scanRequest = ScanRequestBuilder()
        ..cardId = cardId;

      // API呼び出し
      final response = await _defaultApi.scanCardApiScanPost(
        scanRequest: scanRequest.build(),
      );

      // レスポンスをパース
      if (response.data != null) {
        final jsonData = response.data!.asMap as Map<String, dynamic>;
        return ScanResponse.fromJson(jsonData);
      } else {
        throw Exception('Empty response from server');
      }
    } on DioException catch (e) {
      // エラーハンドリング
      if (e.response?.statusCode == 404) {
        // 404エラーの場合は再スロー(カード未登録)
        rethrow;
      } else {
        // その他のエラー
        print('API Error: ${e.message}');
        rethrow;
      }
    }
  }
}
