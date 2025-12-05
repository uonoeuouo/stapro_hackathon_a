//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'clock_out_request.g.dart';

/// ClockOutRequest
///
/// Properties:
/// * [cardId] 
/// * [transportCost] 
/// * [classCount] 
/// * [isAutoSubmit] 
@BuiltValue()
abstract class ClockOutRequest implements Built<ClockOutRequest, ClockOutRequestBuilder> {
  @BuiltValueField(wireName: r'card_id')
  String get cardId;

  @BuiltValueField(wireName: r'transport_cost')
  int get transportCost;

  @BuiltValueField(wireName: r'class_count')
  int get classCount;

  @BuiltValueField(wireName: r'is_auto_submit')
  bool? get isAutoSubmit;

  ClockOutRequest._();

  factory ClockOutRequest([void updates(ClockOutRequestBuilder b)]) = _$ClockOutRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ClockOutRequestBuilder b) => b
      ..isAutoSubmit = false;

  @BuiltValueSerializer(custom: true)
  static Serializer<ClockOutRequest> get serializer => _$ClockOutRequestSerializer();
}

class _$ClockOutRequestSerializer implements PrimitiveSerializer<ClockOutRequest> {
  @override
  final Iterable<Type> types = const [ClockOutRequest, _$ClockOutRequest];

  @override
  final String wireName = r'ClockOutRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ClockOutRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'card_id';
    yield serializers.serialize(
      object.cardId,
      specifiedType: const FullType(String),
    );
    yield r'transport_cost';
    yield serializers.serialize(
      object.transportCost,
      specifiedType: const FullType(int),
    );
    yield r'class_count';
    yield serializers.serialize(
      object.classCount,
      specifiedType: const FullType(int),
    );
    if (object.isAutoSubmit != null) {
      yield r'is_auto_submit';
      yield serializers.serialize(
        object.isAutoSubmit,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ClockOutRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ClockOutRequestBuilder result,
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
        case r'transport_cost':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.transportCost = valueDes;
          break;
        case r'class_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.classCount = valueDes;
          break;
        case r'is_auto_submit':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isAutoSubmit = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ClockOutRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ClockOutRequestBuilder();
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

