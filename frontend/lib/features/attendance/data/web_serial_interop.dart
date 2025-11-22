@JS()
library web_serial;

import 'package:js/js.dart';
import 'dart:html' as html;
import 'dart:typed_data';

/// JavaScript interop for Web Serial API
@JS('navigator.serial')
external Serial get serial;

@JS()
@anonymous
class Serial {
  external Future<SerialPort> requestPort([SerialPortRequestOptions? options]);
  external Future<List<SerialPort>> getPorts();
}

@JS()
@anonymous
class SerialPortRequestOptions {
  external factory SerialPortRequestOptions({List<SerialPortFilter>? filters});
}

@JS()
@anonymous
class SerialPortFilter {
  external factory SerialPortFilter({int? usbVendorId, int? usbProductId});
}

@JS()
@anonymous
class SerialPort {
  external Future<void> open(SerialOptions options);
  external Future<void> close();
  external ReadableStream get readable;
  external WritableStream get writable;
}

@JS()
@anonymous
class SerialOptions {
  external factory SerialOptions({
    required int baudRate,
    int? dataBits,
    int? stopBits,
    String? parity,
  });
}

@JS()
@anonymous
class ReadableStream {
  external ReadableStreamDefaultReader getReader();
}

@JS()
@anonymous
class WritableStream {
  external WritableStreamDefaultWriter getWriter();
}

@JS()
@anonymous
class ReadableStreamDefaultReader {
  external Future<ReadResult> read();
  external void releaseLock();
}

@JS()
@anonymous
class WritableStreamDefaultWriter {
  external Future<void> write(Uint8List data);
  external void releaseLock();
}

@JS()
@anonymous
class ReadResult {
  external Uint8List? get value;
  external bool get done;
}
