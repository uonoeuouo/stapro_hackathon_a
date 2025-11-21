//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'scan_request.g.dart';

/// ScanRequest
///
/// Properties:
/// * [cardId] 
@BuiltValue()
abstract class ScanRequest implements Built<ScanRequest, ScanRequestBuilder> {
  @BuiltValueField(wireName: r'card_id')
  String get cardId;

  ScanRequest._();

  factory ScanRequest([void updates(ScanRequestBuilder b)]) = _$ScanRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ScanRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ScanRequest> get serializer => _$ScanRequestSerializer();
}

class _$ScanRequestSerializer implements PrimitiveSerializer<ScanRequest> {
  @override
  final Iterable<Type> types = const [ScanRequest, _$ScanRequest];

  @override
  final String wireName = r'ScanRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ScanRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'card_id';
    yield serializers.serialize(
      object.cardId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ScanRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ScanRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'card_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.cardId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ScanRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ScanRequestBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

