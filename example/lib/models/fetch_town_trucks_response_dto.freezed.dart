// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fetch_town_trucks_response_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FetchTownTrucksResponseDTO {
  int get page;
  set page(int value);
  int get offset;
  set offset(int value);
  int get totalPages;
  set totalPages(int value);
  int get total;
  set total(int value);
  List<TownTruckDTO> get data;
  set data(List<TownTruckDTO> value);

  /// Create a copy of FetchTownTrucksResponseDTO
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FetchTownTrucksResponseDTOCopyWith<FetchTownTrucksResponseDTO>
      get copyWith =>
          _$FetchTownTrucksResponseDTOCopyWithImpl<FetchTownTrucksResponseDTO>(
              this as FetchTownTrucksResponseDTO, _$identity);

  /// Serializes this FetchTownTrucksResponseDTO to a JSON map.
  Map<String, dynamic> toJson();

  @override
  String toString() {
    return 'FetchTownTrucksResponseDTO(page: $page, offset: $offset, totalPages: $totalPages, total: $total, data: $data)';
  }
}

/// @nodoc
abstract mixin class $FetchTownTrucksResponseDTOCopyWith<$Res> {
  factory $FetchTownTrucksResponseDTOCopyWith(FetchTownTrucksResponseDTO value,
          $Res Function(FetchTownTrucksResponseDTO) _then) =
      _$FetchTownTrucksResponseDTOCopyWithImpl;
  @useResult
  $Res call(
      {int page,
      int offset,
      int totalPages,
      int total,
      List<TownTruckDTO> data});
}

/// @nodoc
class _$FetchTownTrucksResponseDTOCopyWithImpl<$Res>
    implements $FetchTownTrucksResponseDTOCopyWith<$Res> {
  _$FetchTownTrucksResponseDTOCopyWithImpl(this._self, this._then);

  final FetchTownTrucksResponseDTO _self;
  final $Res Function(FetchTownTrucksResponseDTO) _then;

  /// Create a copy of FetchTownTrucksResponseDTO
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? page = null,
    Object? offset = null,
    Object? totalPages = null,
    Object? total = null,
    Object? data = null,
  }) {
    return _then(_self.copyWith(
      page: null == page
          ? _self.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      offset: null == offset
          ? _self.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
      totalPages: null == totalPages
          ? _self.totalPages
          : totalPages // ignore: cast_nullable_to_non_nullable
              as int,
      total: null == total
          ? _self.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      data: null == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as List<TownTruckDTO>,
    ));
  }
}

/// Adds pattern-matching-related methods to [FetchTownTrucksResponseDTO].
extension FetchTownTrucksResponseDTOPatterns on FetchTownTrucksResponseDTO {
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
    TResult Function(_FetchTownTrucksResponseDTO value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FetchTownTrucksResponseDTO() when $default != null:
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
    TResult Function(_FetchTownTrucksResponseDTO value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FetchTownTrucksResponseDTO():
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
    TResult? Function(_FetchTownTrucksResponseDTO value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FetchTownTrucksResponseDTO() when $default != null:
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
    TResult Function(int page, int offset, int totalPages, int total,
            List<TownTruckDTO> data)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FetchTownTrucksResponseDTO() when $default != null:
        return $default(_that.page, _that.offset, _that.totalPages, _that.total,
            _that.data);
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
    TResult Function(int page, int offset, int totalPages, int total,
            List<TownTruckDTO> data)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FetchTownTrucksResponseDTO():
        return $default(_that.page, _that.offset, _that.totalPages, _that.total,
            _that.data);
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
    TResult? Function(int page, int offset, int totalPages, int total,
            List<TownTruckDTO> data)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FetchTownTrucksResponseDTO() when $default != null:
        return $default(_that.page, _that.offset, _that.totalPages, _that.total,
            _that.data);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _FetchTownTrucksResponseDTO implements FetchTownTrucksResponseDTO {
  _FetchTownTrucksResponseDTO(
      {required this.page,
      required this.offset,
      required this.totalPages,
      required this.total,
      this.data = const []});
  factory _FetchTownTrucksResponseDTO.fromJson(Map<String, dynamic> json) =>
      _$FetchTownTrucksResponseDTOFromJson(json);

  @override
  int page;
  @override
  int offset;
  @override
  int totalPages;
  @override
  int total;
  @override
  @JsonKey()
  List<TownTruckDTO> data;

  /// Create a copy of FetchTownTrucksResponseDTO
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FetchTownTrucksResponseDTOCopyWith<_FetchTownTrucksResponseDTO>
      get copyWith => __$FetchTownTrucksResponseDTOCopyWithImpl<
          _FetchTownTrucksResponseDTO>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FetchTownTrucksResponseDTOToJson(
      this,
    );
  }

  @override
  String toString() {
    return 'FetchTownTrucksResponseDTO(page: $page, offset: $offset, totalPages: $totalPages, total: $total, data: $data)';
  }
}

/// @nodoc
abstract mixin class _$FetchTownTrucksResponseDTOCopyWith<$Res>
    implements $FetchTownTrucksResponseDTOCopyWith<$Res> {
  factory _$FetchTownTrucksResponseDTOCopyWith(
          _FetchTownTrucksResponseDTO value,
          $Res Function(_FetchTownTrucksResponseDTO) _then) =
      __$FetchTownTrucksResponseDTOCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int page,
      int offset,
      int totalPages,
      int total,
      List<TownTruckDTO> data});
}

/// @nodoc
class __$FetchTownTrucksResponseDTOCopyWithImpl<$Res>
    implements _$FetchTownTrucksResponseDTOCopyWith<$Res> {
  __$FetchTownTrucksResponseDTOCopyWithImpl(this._self, this._then);

  final _FetchTownTrucksResponseDTO _self;
  final $Res Function(_FetchTownTrucksResponseDTO) _then;

  /// Create a copy of FetchTownTrucksResponseDTO
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? page = null,
    Object? offset = null,
    Object? totalPages = null,
    Object? total = null,
    Object? data = null,
  }) {
    return _then(_FetchTownTrucksResponseDTO(
      page: null == page
          ? _self.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      offset: null == offset
          ? _self.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
      totalPages: null == totalPages
          ? _self.totalPages
          : totalPages // ignore: cast_nullable_to_non_nullable
              as int,
      total: null == total
          ? _self.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      data: null == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as List<TownTruckDTO>,
    ));
  }
}

// dart format on
