# openapi.api.DefaultApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**readRootGet**](DefaultApi.md#readrootget) | **GET** / | Read Root
[**scanCardApiScanPost**](DefaultApi.md#scancardapiscanpost) | **POST** /api/scan | Scan Card


# **readRootGet**
> JsonObject readRootGet()

Read Root

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDefaultApi();

try {
    final response = api.readRootGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->readRootGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **scanCardApiScanPost**
> JsonObject scanCardApiScanPost(scanRequest)

Scan Card

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDefaultApi();
final ScanRequest scanRequest = ; // ScanRequest | 

try {
    final response = api.scanCardApiScanPost(scanRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->scanCardApiScanPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **scanRequest** | [**ScanRequest**](ScanRequest.md)|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

