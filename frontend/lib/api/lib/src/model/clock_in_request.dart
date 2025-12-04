//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'clock_in_request.g.dart';

/// ClockInRequest
///
/// Properties:
/// * [cardId] 
@BuiltValue()
abstract class ClockInRequest implements Built<ClockInRequest, ClockInRequestBuilder> {
  @BuiltValueField(wireName: r'card_id')
  String get cardId;

  ClockInRequest._();

  factory ClockInRequest([void updates(ClockInRequestBuilder b)]) = _$ClockInRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ClockInRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ClockInRequest> get serializer => _$ClockInRequestSerializer();
}

class _$ClockInRequestSerializer implements PrimitiveSerializer<ClockInRequest> {
  @override
  final Iterable<Type> types = const [ClockInRequest, _$ClockInRequest];

  @override
  final String wireName = r'ClockInRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ClockInRequest object, {
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
    ClockInRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ClockInRequestBuilder result,
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
  ClockInRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ClockInRequestBuilder();
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

