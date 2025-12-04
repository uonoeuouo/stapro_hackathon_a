//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'scan_response.g.dart';

/// ScanResponse
///
/// Properties:
/// * [status] 
/// * [userName] 
/// * [message] 
/// * [defaultCost] 
/// * [estimatedClassCount] 
/// * [transportPresets] 
/// * [attendanceId] 
/// * [clockInAt] 
/// * [externalActive] 
@BuiltValue()
abstract class ScanResponse implements Built<ScanResponse, ScanResponseBuilder> {
  @BuiltValueField(wireName: r'status')
  String get status;

  @BuiltValueField(wireName: r'user_name')
  String get userName;

  @BuiltValueField(wireName: r'message')
  String get message;

  @BuiltValueField(wireName: r'default_cost')
  int? get defaultCost;

  @BuiltValueField(wireName: r'estimated_class_count')
  int? get estimatedClassCount;

  @BuiltValueField(wireName: r'transport_presets')
  BuiltList<BuiltMap<JsonObject?>?>? get transportPresets;

  @BuiltValueField(wireName: r'attendance_id')
  int? get attendanceId;

  @BuiltValueField(wireName: r'clock_in_at')
  String? get clockInAt;

  @BuiltValueField(wireName: r'external_active')
  bool? get externalActive;

  ScanResponse._();

  factory ScanResponse([void updates(ScanResponseBuilder b)]) = _$ScanResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ScanResponseBuilder b) => b
      ..defaultCost = 0
      ..estimatedClassCount = 0
      ..externalActive = false;

  @BuiltValueSerializer(custom: true)
  static Serializer<ScanResponse> get serializer => _$ScanResponseSerializer();
}

class _$ScanResponseSerializer implements PrimitiveSerializer<ScanResponse> {
  @override
  final Iterable<Type> types = const [ScanResponse, _$ScanResponse];

  @override
  final String wireName = r'ScanResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ScanResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(String),
    );
    yield r'user_name';
    yield serializers.serialize(
      object.userName,
      specifiedType: const FullType(String),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(String),
    );
    if (object.defaultCost != null) {
      yield r'default_cost';
      yield serializers.serialize(
        object.defaultCost,
        specifiedType: const FullType(int),
      );
    }
    if (object.estimatedClassCount != null) {
      yield r'estimated_class_count';
      yield serializers.serialize(
        object.estimatedClassCount,
        specifiedType: const FullType(int),
      );
    }
    if (object.transportPresets != null) {
      yield r'transport_presets';
      yield serializers.serialize(
        object.transportPresets,
        specifiedType: const FullType(BuiltList, [FullType.nullable(BuiltMap, [FullType.nullable(JsonObject)])]),
      );
    }
    if (object.attendanceId != null) {
      yield r'attendance_id';
      yield serializers.serialize(
        object.attendanceId,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.clockInAt != null) {
      yield r'clock_in_at';
      yield serializers.serialize(
        object.clockInAt,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.externalActive != null) {
      yield r'external_active';
      yield serializers.serialize(
        object.externalActive,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ScanResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ScanResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.status = valueDes;
          break;
        case r'user_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.userName = valueDes;
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.message = valueDes;
          break;
        case r'default_cost':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.defaultCost = valueDes;
          break;
        case r'estimated_class_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.estimatedClassCount = valueDes;
          break;
        case r'transport_presets':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType.nullable(BuiltMap, [FullType.nullable(JsonObject)])]),
          ) as BuiltList<BuiltMap<JsonObject?>?>;
          result.transportPresets.replace(valueDes);
          break;
        case r'attendance_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.attendanceId = valueDes;
          break;
        case r'clock_in_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.clockInAt = valueDes;
          break;
        case r'external_active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.externalActive = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ScanResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ScanResponseBuilder();
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

