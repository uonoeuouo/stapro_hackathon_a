# openapi.api.DefaultApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**clockInApiClockInPost**](DefaultApi.md#clockinapiclockinpost) | **POST** /api/clock-in | Clock In
[**clockOutApiClockOutPost**](DefaultApi.md#clockoutapiclockoutpost) | **POST** /api/clock-out | Clock Out
[**healthCheckGet**](DefaultApi.md#healthcheckget) | **GET** / | Health Check
[**scanCardApiScanPost**](DefaultApi.md#scancardapiscanpost) | **POST** /api/scan | Scan Card


# **clockInApiClockInPost**
> clockInApiClockInPost(clockInRequest)

Clock In

出勤打刻

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDefaultApi();
final ClockInRequest clockInRequest = ; // ClockInRequest | 

try {
    api.clockInApiClockInPost(clockInRequest);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->clockInApiClockInPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **clockInRequest** | [**ClockInRequest**](ClockInRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **clockOutApiClockOutPost**
> clockOutApiClockOutPost(clockOutRequest)

Clock Out

退勤打刻 + 外部連携

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDefaultApi();
final ClockOutRequest clockOutRequest = ; // ClockOutRequest | 

try {
    api.clockOutApiClockOutPost(clockOutRequest);
} catch on DioException (e) {
    print('Exception when calling DefaultApi->clockOutApiClockOutPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **clockOutRequest** | [**ClockOutRequest**](ClockOutRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **healthCheckGet**
> healthCheckGet()

Health Check

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getDefaultApi();

try {
    api.healthCheckGet();
} catch on DioException (e) {
    print('Exception when calling DefaultApi->healthCheckGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **scanCardApiScanPost**
> ScanResponse scanCardApiScanPost(scanRequest)

Scan Card

カードをスキャンした時の状態判定

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

[**ScanResponse**](ScanResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

