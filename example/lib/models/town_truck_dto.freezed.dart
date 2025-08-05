// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'town_truck_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TownTruckDTO {
  String get id;
  set id(String value);
  String get organizationId;
  set organizationId(String value);
  String get name;
  set name(String value);
  String? get document;
  set document(String? value);
  List<String> get phones;
  set phones(List<String> value);
  String? get email;
  set email(String? value);
  String? get city;
  set city(String? value);
  String? get state;
  set state(String? value);
  String? get zipCode;
  set zipCode(String? value);
  String get externalId;
  set externalId(String value);
  ActiveInactiveStatus get status;
  set status(ActiveInactiveStatus value);

  /// Create a copy of TownTruckDTO
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TownTruckDTOCopyWith<TownTruckDTO> get copyWith =>
      _$TownTruckDTOCopyWithImpl<TownTruckDTO>(
          this as TownTruckDTO, _$identity);

  /// Serializes this TownTruckDTO to a JSON map.
  Map<String, dynamic> toJson();

  @override
  String toString() {
    return 'TownTruckDTO(id: $id, organizationId: $organizationId, name: $name, document: $document, phones: $phones, email: $email, city: $city, state: $state, zipCode: $zipCode, externalId: $externalId, status: $status)';
  }
}

/// @nodoc
abstract mixin class $TownTruckDTOCopyWith<$Res> {
  factory $TownTruckDTOCopyWith(
          TownTruckDTO value, $Res Function(TownTruckDTO) _then) =
      _$TownTruckDTOCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String organizationId,
      String name,
      String? document,
      List<String> phones,
      String? email,
      String? city,
      String? state,
      String? zipCode,
      String externalId,
      ActiveInactiveStatus status});
}

/// @nodoc
class _$TownTruckDTOCopyWithImpl<$Res> implements $TownTruckDTOCopyWith<$Res> {
  _$TownTruckDTOCopyWithImpl(this._self, this._then);

  final TownTruckDTO _self;
  final $Res Function(TownTruckDTO) _then;

  /// Create a copy of TownTruckDTO
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? organizationId = null,
    Object? name = null,
    Object? document = freezed,
    Object? phones = null,
    Object? email = freezed,
    Object? city = freezed,
    Object? state = freezed,
    Object? zipCode = freezed,
    Object? externalId = null,
    Object? status = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      organizationId: null == organizationId
          ? _self.organizationId
          : organizationId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      document: freezed == document
          ? _self.document
          : document // ignore: cast_nullable_to_non_nullable
              as String?,
      phones: null == phones
          ? _self.phones
          : phones // ignore: cast_nullable_to_non_nullable
              as List<String>,
      email: freezed == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _self.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      state: freezed == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as String?,
      zipCode: freezed == zipCode
          ? _self.zipCode
          : zipCode // ignore: cast_nullable_to_non_nullable
              as String?,
      externalId: null == externalId
          ? _self.externalId
          : externalId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ActiveInactiveStatus,
    ));
  }
}

/// Adds pattern-matching-related methods to [TownTruckDTO].
extension TownTruckDTOPatterns on TownTruckDTO {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_TownTruckDTO value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TownTruckDTO() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_TownTruckDTO value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TownTruckDTO():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_TownTruckDTO value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TownTruckDTO() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
            String organizationId,
            String name,
            String? document,
            List<String> phones,
            String? email,
            String? city,
            String? state,
            String? zipCode,
            String externalId,
            ActiveInactiveStatus status)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TownTruckDTO() when $default != null:
        return $default(
            _that.id,
            _that.organizationId,
            _that.name,
            _that.document,
            _that.phones,
            _that.email,
            _that.city,
            _that.state,
            _that.zipCode,
            _that.externalId,
            _that.status);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
            String organizationId,
            String name,
            String? document,
            List<String> phones,
            String? email,
            String? city,
            String? state,
            String? zipCode,
            String externalId,
            ActiveInactiveStatus status)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TownTruckDTO():
        return $default(
            _that.id,
            _that.organizationId,
            _that.name,
            _that.document,
            _that.phones,
            _that.email,
            _that.city,
            _that.state,
            _that.zipCode,
            _that.externalId,
            _that.status);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
            String organizationId,
            String name,
            String? document,
            List<String> phones,
            String? email,
            String? city,
            String? state,
            String? zipCode,
            String externalId,
            ActiveInactiveStatus status)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TownTruckDTO() when $default != null:
        return $default(
            _that.id,
            _that.organizationId,
            _that.name,
            _that.document,
            _that.phones,
            _that.email,
            _that.city,
            _that.state,
            _that.zipCode,
            _that.externalId,
            _that.status);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TownTruckDTO implements TownTruckDTO {
  _TownTruckDTO(
      {required this.id,
      required this.organizationId,
      required this.name,
      this.document,
      this.phones = const [],
      this.email,
      this.city,
      this.state,
      this.zipCode,
      required this.externalId,
      this.status = ActiveInactiveStatus.active});
  factory _TownTruckDTO.fromJson(Map<String, dynamic> json) =>
      _$TownTruckDTOFromJson(json);

  @override
  String id;
  @override
  String organizationId;
  @override
  String name;
  @override
  String? document;
  @override
  @JsonKey()
  List<String> phones;
  @override
  String? email;
  @override
  String? city;
  @override
  String? state;
  @override
  String? zipCode;
  @override
  String externalId;
  @override
  @JsonKey()
  ActiveInactiveStatus status;

  /// Create a copy of TownTruckDTO
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TownTruckDTOCopyWith<_TownTruckDTO> get copyWith =>
      __$TownTruckDTOCopyWithImpl<_TownTruckDTO>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TownTruckDTOToJson(
      this,
    );
  }

  @override
  String toString() {
    return 'TownTruckDTO(id: $id, organizationId: $organizationId, name: $name, document: $document, phones: $phones, email: $email, city: $city, state: $state, zipCode: $zipCode, externalId: $externalId, status: $status)';
  }
}

/// @nodoc
abstract mixin class _$TownTruckDTOCopyWith<$Res>
    implements $TownTruckDTOCopyWith<$Res> {
  factory _$TownTruckDTOCopyWith(
          _TownTruckDTO value, $Res Function(_TownTruckDTO) _then) =
      __$TownTruckDTOCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String organizationId,
      String name,
      String? document,
      List<String> phones,
      String? email,
      String? city,
      String? state,
      String? zipCode,
      String externalId,
      ActiveInactiveStatus status});
}

/// @nodoc
class __$TownTruckDTOCopyWithImpl<$Res>
    implements _$TownTruckDTOCopyWith<$Res> {
  __$TownTruckDTOCopyWithImpl(this._self, this._then);

  final _TownTruckDTO _self;
  final $Res Function(_TownTruckDTO) _then;

  /// Create a copy of TownTruckDTO
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? organizationId = null,
    Object? name = null,
    Object? document = freezed,
    Object? phones = null,
    Object? email = freezed,
    Object? city = freezed,
    Object? state = freezed,
    Object? zipCode = freezed,
    Object? externalId = null,
    Object? status = null,
  }) {
    return _then(_TownTruckDTO(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      organizationId: null == organizationId
          ? _self.organizationId
          : organizationId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      document: freezed == document
          ? _self.document
          : document // ignore: cast_nullable_to_non_nullable
              as String?,
      phones: null == phones
          ? _self.phones
          : phones // ignore: cast_nullable_to_non_nullable
              as List<String>,
      email: freezed == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _self.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      state: freezed == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as String?,
      zipCode: freezed == zipCode
          ? _self.zipCode
          : zipCode // ignore: cast_nullable_to_non_nullable
              as String?,
      externalId: null == externalId
          ? _self.externalId
          : externalId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ActiveInactiveStatus,
    ));
  }
}

// dart format on
