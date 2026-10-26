// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AIMessage {
  String get id;
  String get conversationId;
  MessageRole get role;
  String get content;
  String? get model;
  String? get provider;
  int get inputTokens;
  int get outputTokens;
  bool get hasImage;
  String? get imagePath;
  Map<String, dynamic> get metadata;
  DateTime get createdAt;

  /// Create a copy of AIMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AIMessageCopyWith<AIMessage> get copyWith =>
      _$AIMessageCopyWithImpl<AIMessage>(this as AIMessage, _$identity);

  /// Serializes this AIMessage to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as AIMessage;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AIMessage &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.conversationId, _this.conversationId) ||
                other.conversationId == _this.conversationId) &&
            (identical(other.role, _this.role) || other.role == _this.role) &&
            (identical(other.content, _this.content) ||
                other.content == _this.content) &&
            (identical(other.model, _this.model) ||
                other.model == _this.model) &&
            (identical(other.provider, _this.provider) ||
                other.provider == _this.provider) &&
            (identical(other.inputTokens, _this.inputTokens) ||
                other.inputTokens == _this.inputTokens) &&
            (identical(other.outputTokens, _this.outputTokens) ||
                other.outputTokens == _this.outputTokens) &&
            (identical(other.hasImage, _this.hasImage) ||
                other.hasImage == _this.hasImage) &&
            (identical(other.imagePath, _this.imagePath) ||
                other.imagePath == _this.imagePath) &&
            const DeepCollectionEquality()
                .equals(other.metadata, _this.metadata) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as AIMessage;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.conversationId,
        _this.role,
        _this.content,
        _this.model,
        _this.provider,
        _this.inputTokens,
        _this.outputTokens,
        _this.hasImage,
        _this.imagePath,
        const DeepCollectionEquality().hash(_this.metadata),
        _this.createdAt);
  }

  @override
  String toString() {
    final _this = this as AIMessage;
    return 'AIMessage(id: ${_this.id}, conversationId: ${_this.conversationId}, role: ${_this.role}, content: ${_this.content}, model: ${_this.model}, provider: ${_this.provider}, inputTokens: ${_this.inputTokens}, outputTokens: ${_this.outputTokens}, hasImage: ${_this.hasImage}, imagePath: ${_this.imagePath}, metadata: ${_this.metadata}, createdAt: ${_this.createdAt})';
  }
}

/// @nodoc
abstract mixin class $AIMessageCopyWith<$Res> {
  factory $AIMessageCopyWith(AIMessage value, $Res Function(AIMessage) _then) =
      _$AIMessageCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String conversationId,
      MessageRole role,
      String content,
      String? model,
      String? provider,
      int inputTokens,
      int outputTokens,
      bool hasImage,
      String? imagePath,
      Map<String, dynamic> metadata,
      DateTime createdAt});
}

/// @nodoc
class _$AIMessageCopyWithImpl<$Res> implements $AIMessageCopyWith<$Res> {
  _$AIMessageCopyWithImpl(this._self, this._then);

  final AIMessage _self;
  final $Res Function(AIMessage) _then;

  /// Create a copy of AIMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? role = null,
    Object? content = null,
    Object? model = freezed,
    Object? provider = freezed,
    Object? inputTokens = null,
    Object? outputTokens = null,
    Object? hasImage = null,
    Object? imagePath = freezed,
    Object? metadata = null,
    Object? createdAt = null,
  }) {
    return _then(AIMessage(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      conversationId: null == conversationId
          ? _self.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _self.role
          : role // ignore: cast_nullable_to_non_nullable
              as MessageRole,
      content: null == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      model: freezed == model
          ? _self.model
          : model // ignore: cast_nullable_to_non_nullable
              as String?,
      provider: freezed == provider
          ? _self.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as String?,
      inputTokens: null == inputTokens
          ? _self.inputTokens
          : inputTokens // ignore: cast_nullable_to_non_nullable
              as int,
      outputTokens: null == outputTokens
          ? _self.outputTokens
          : outputTokens // ignore: cast_nullable_to_non_nullable
              as int,
      hasImage: null == hasImage
          ? _self.hasImage
          : hasImage // ignore: cast_nullable_to_non_nullable
              as bool,
      imagePath: freezed == imagePath
          ? _self.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [AIMessage].
extension AIMessagePatterns on AIMessage {
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
    TResult Function(_AIMessage value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AIMessage() when $default != null:
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
    TResult Function(_AIMessage value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AIMessage():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
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
    TResult? Function(_AIMessage value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AIMessage() when $default != null:
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
            String conversationId,
            MessageRole role,
            String content,
            String? model,
            String? provider,
            int inputTokens,
            int outputTokens,
            bool hasImage,
            String? imagePath,
            Map<String, dynamic> metadata,
            DateTime createdAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AIMessage() when $default != null:
        return $default(
            _that.id,
            _that.conversationId,
            _that.role,
            _that.content,
            _that.model,
            _that.provider,
            _that.inputTokens,
            _that.outputTokens,
            _that.hasImage,
            _that.imagePath,
            _that.metadata,
            _that.createdAt);
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
            String conversationId,
            MessageRole role,
            String content,
            String? model,
            String? provider,
            int inputTokens,
            int outputTokens,
            bool hasImage,
            String? imagePath,
            Map<String, dynamic> metadata,
            DateTime createdAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AIMessage():
        return $default(
            _that.id,
            _that.conversationId,
            _that.role,
            _that.content,
            _that.model,
            _that.provider,
            _that.inputTokens,
            _that.outputTokens,
            _that.hasImage,
            _that.imagePath,
            _that.metadata,
            _that.createdAt);
      case _:
        throw StateError('Unexpected subclass');
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
            String conversationId,
            MessageRole role,
            String content,
            String? model,
            String? provider,
            int inputTokens,
            int outputTokens,
            bool hasImage,
            String? imagePath,
            Map<String, dynamic> metadata,
            DateTime createdAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AIMessage() when $default != null:
        return $default(
            _that.id,
            _that.conversationId,
            _that.role,
            _that.content,
            _that.model,
            _that.provider,
            _that.inputTokens,
            _that.outputTokens,
            _that.hasImage,
            _that.imagePath,
            _that.metadata,
            _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AIMessage implements AIMessage {
  const _AIMessage(
      {required this.id,
      required this.conversationId,
      required this.role,
      required this.content,
      this.model,
      this.provider,
      this.inputTokens = 0,
      this.outputTokens = 0,
      this.hasImage = false,
      this.imagePath,
      Map<String, dynamic> metadata = const {},
      required this.createdAt})
      : _metadata = metadata;
  factory _AIMessage.fromJson(Map<String, dynamic> json) =>
      _$AIMessageFromJson(json);

  @override
  final String id;
  @override
  final String conversationId;
  @override
  final MessageRole role;
  @override
  final String content;
  @override
  final String? model;
  @override
  final String? provider;
  @override
  @JsonKey()
  final int inputTokens;
  @override
  @JsonKey()
  final int outputTokens;
  @override
  @JsonKey()
  final bool hasImage;
  @override
  final String? imagePath;
  final Map<String, dynamic> _metadata;
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  final DateTime createdAt;

  /// Create a copy of AIMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AIMessageCopyWith<_AIMessage> get copyWith =>
      __$AIMessageCopyWithImpl<_AIMessage>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AIMessageToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AIMessage &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.provider, provider) ||
                other.provider == provider) &&
            (identical(other.inputTokens, inputTokens) ||
                other.inputTokens == inputTokens) &&
            (identical(other.outputTokens, outputTokens) ||
                other.outputTokens == outputTokens) &&
            (identical(other.hasImage, hasImage) ||
                other.hasImage == hasImage) &&
            (identical(other.imagePath, imagePath) ||
                other.imagePath == imagePath) &&
            const DeepCollectionEquality().equals(other.metadata, _metadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        id,
        conversationId,
        role,
        content,
        model,
        provider,
        inputTokens,
        outputTokens,
        hasImage,
        imagePath,
        const DeepCollectionEquality().hash(_metadata),
        createdAt);
  }

  @override
  String toString() {
    return 'AIMessage(id: $id, conversationId: $conversationId, role: $role, content: $content, model: $model, provider: $provider, inputTokens: $inputTokens, outputTokens: $outputTokens, hasImage: $hasImage, imagePath: $imagePath, metadata: $metadata, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$AIMessageCopyWith<$Res>
    implements $AIMessageCopyWith<$Res> {
  factory _$AIMessageCopyWith(
          _AIMessage value, $Res Function(_AIMessage) _then) =
      __$AIMessageCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String conversationId,
      MessageRole role,
      String content,
      String? model,
      String? provider,
      int inputTokens,
      int outputTokens,
      bool hasImage,
      String? imagePath,
      Map<String, dynamic> metadata,
      DateTime createdAt});
}

/// @nodoc
class __$AIMessageCopyWithImpl<$Res> implements _$AIMessageCopyWith<$Res> {
  __$AIMessageCopyWithImpl(this._self, this._then);

  final _AIMessage _self;
  final $Res Function(_AIMessage) _then;

  /// Create a copy of AIMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? role = null,
    Object? content = null,
    Object? model = freezed,
    Object? provider = freezed,
    Object? inputTokens = null,
    Object? outputTokens = null,
    Object? hasImage = null,
    Object? imagePath = freezed,
    Object? metadata = null,
    Object? createdAt = null,
  }) {
    return _then(_AIMessage(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      conversationId: null == conversationId
          ? _self.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _self.role
          : role // ignore: cast_nullable_to_non_nullable
              as MessageRole,
      content: null == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      model: freezed == model
          ? _self.model
          : model // ignore: cast_nullable_to_non_nullable
              as String?,
      provider: freezed == provider
          ? _self.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as String?,
      inputTokens: null == inputTokens
          ? _self.inputTokens
          : inputTokens // ignore: cast_nullable_to_non_nullable
              as int,
      outputTokens: null == outputTokens
          ? _self.outputTokens
          : outputTokens // ignore: cast_nullable_to_non_nullable
              as int,
      hasImage: null == hasImage
          ? _self.hasImage
          : hasImage // ignore: cast_nullable_to_non_nullable
              as bool,
      imagePath: freezed == imagePath
          ? _self.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: null == metadata
          ? _self._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
