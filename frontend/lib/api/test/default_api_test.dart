import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for DefaultApi
void main() {
  final instance = Openapi().getDefaultApi();

  group(DefaultApi, () {
    // Read Root
    //
    //Future<JsonObject> readRootGet() async
    test('test readRootGet', () async {
      // TODO
    });

    // Scan Card
    //
    //Future<JsonObject> scanCardApiScanPost(ScanRequest scanRequest) async
    test('test scanCardApiScanPost', () async {
      // TODO
    });

  });
}
