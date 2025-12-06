// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ScanRequest extends ScanRequest {
  @override
  final String cardId;

  factory _$ScanRequest([void Function(ScanRequestBuilder)? updates]) =>
      (ScanRequestBuilder()..update(updates))._build();

  _$ScanRequest._({required this.cardId}) : super._();
  @override
  ScanRequest rebuild(void Function(ScanRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ScanRequestBuilder toBuilder() => ScanRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ScanRequest && cardId == other.cardId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, cardId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ScanRequest',
    )..add('cardId', cardId)).toString();
  }
}

class ScanRequestBuilder implements Builder<ScanRequest, ScanRequestBuilder> {
  _$ScanRequest? _$v;

  String? _cardId;
  String? get cardId => _$this._cardId;
  set cardId(String? cardId) => _$this._cardId = cardId;

  ScanRequestBuilder() {
    ScanRequest._defaults(this);
  }

  ScanRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _cardId = $v.cardId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ScanRequest other) {
    _$v = other as _$ScanRequest;
  }

  @override
  void update(void Function(ScanRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ScanRequest build() => _build();

  _$ScanRequest _build() {
    final _$result =
        _$v ??
        _$ScanRequest._(
          cardId: BuiltValueNullFieldError.checkNotNull(
            cardId,
            r'ScanRequest',
            'cardId',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
