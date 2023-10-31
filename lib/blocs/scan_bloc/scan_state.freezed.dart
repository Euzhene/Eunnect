// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scan_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$ScanState {
  Set<DeviceInfo> get foundDevices => throw _privateConstructorUsedError;
  Set<ScanPairedDevice> get pairedDevices => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ScanStateCopyWith<ScanState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScanStateCopyWith<$Res> {
  factory $ScanStateCopyWith(ScanState value, $Res Function(ScanState) then) =
      _$ScanStateCopyWithImpl<$Res, ScanState>;
  @useResult
  $Res call(
      {Set<DeviceInfo> foundDevices, Set<ScanPairedDevice> pairedDevices});
}

/// @nodoc
class _$ScanStateCopyWithImpl<$Res, $Val extends ScanState>
    implements $ScanStateCopyWith<$Res> {
  _$ScanStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? foundDevices = null,
    Object? pairedDevices = null,
  }) {
    return _then(_value.copyWith(
      foundDevices: null == foundDevices
          ? _value.foundDevices
          : foundDevices // ignore: cast_nullable_to_non_nullable
              as Set<DeviceInfo>,
      pairedDevices: null == pairedDevices
          ? _value.pairedDevices
          : pairedDevices // ignore: cast_nullable_to_non_nullable
              as Set<ScanPairedDevice>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScanStateImplCopyWith<$Res>
    implements $ScanStateCopyWith<$Res> {
  factory _$$ScanStateImplCopyWith(
          _$ScanStateImpl value, $Res Function(_$ScanStateImpl) then) =
      __$$ScanStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Set<DeviceInfo> foundDevices, Set<ScanPairedDevice> pairedDevices});
}

/// @nodoc
class __$$ScanStateImplCopyWithImpl<$Res>
    extends _$ScanStateCopyWithImpl<$Res, _$ScanStateImpl>
    implements _$$ScanStateImplCopyWith<$Res> {
  __$$ScanStateImplCopyWithImpl(
      _$ScanStateImpl _value, $Res Function(_$ScanStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? foundDevices = null,
    Object? pairedDevices = null,
  }) {
    return _then(_$ScanStateImpl(
      foundDevices: null == foundDevices
          ? _value._foundDevices
          : foundDevices // ignore: cast_nullable_to_non_nullable
              as Set<DeviceInfo>,
      pairedDevices: null == pairedDevices
          ? _value._pairedDevices
          : pairedDevices // ignore: cast_nullable_to_non_nullable
              as Set<ScanPairedDevice>,
    ));
  }
}

/// @nodoc

class _$ScanStateImpl implements _ScanState {
  const _$ScanStateImpl(
      {final Set<DeviceInfo> foundDevices = const {},
      final Set<ScanPairedDevice> pairedDevices = const {}})
      : _foundDevices = foundDevices,
        _pairedDevices = pairedDevices;

  final Set<DeviceInfo> _foundDevices;
  @override
  @JsonKey()
  Set<DeviceInfo> get foundDevices {
    if (_foundDevices is EqualUnmodifiableSetView) return _foundDevices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_foundDevices);
  }

  final Set<ScanPairedDevice> _pairedDevices;
  @override
  @JsonKey()
  Set<ScanPairedDevice> get pairedDevices {
    if (_pairedDevices is EqualUnmodifiableSetView) return _pairedDevices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_pairedDevices);
  }

  @override
  String toString() {
    return 'ScanState(foundDevices: $foundDevices, pairedDevices: $pairedDevices)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScanStateImpl &&
            const DeepCollectionEquality()
                .equals(other._foundDevices, _foundDevices) &&
            const DeepCollectionEquality()
                .equals(other._pairedDevices, _pairedDevices));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_foundDevices),
      const DeepCollectionEquality().hash(_pairedDevices));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ScanStateImplCopyWith<_$ScanStateImpl> get copyWith =>
      __$$ScanStateImplCopyWithImpl<_$ScanStateImpl>(this, _$identity);
}

abstract class _ScanState implements ScanState {
  const factory _ScanState(
      {final Set<DeviceInfo> foundDevices,
      final Set<ScanPairedDevice> pairedDevices}) = _$ScanStateImpl;

  @override
  Set<DeviceInfo> get foundDevices;
  @override
  Set<ScanPairedDevice> get pairedDevices;
  @override
  @JsonKey(ignore: true)
  _$$ScanStateImplCopyWith<_$ScanStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
