// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_conversation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AIConversation {
  String get id;
  String get userId;
  String get title;
  String? get documentId;
  String get taskType;
  int get totalInputTokens;
  int get totalOutputTokens;
  int get messageCount;
  bool get isPinned;
  DateTime get createdAt;
  DateTime get updatedAt;

  /// Create a copy of AIConversation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AIConversationCopyWith<AIConversation> get copyWith =>
      _$AIConversationCopyWithImpl<AIConversation>(
          this as AIConversation, _$identity);

  /// Serializes this AIConversation to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as AIConversation;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AIConversation &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.userId, _this.userId) ||
                other.userId == _this.userId) &&
            (identical(other.title, _this.title) ||
                other.title == _this.title) &&
            (identical(other.documentId, _this.documentId) ||
                other.documentId == _this.documentId) &&
            (identical(other.taskType, _this.taskType) ||
                other.taskType == _this.taskType) &&
            (identical(other.totalInputTokens, _this.totalInputTokens) ||
                other.totalInputTokens == _this.totalInputTokens) &&
            (identical(other.totalOutputTokens, _this.totalOutputTokens) ||
                other.totalOutputTokens == _this.totalOutputTokens) &&
            (identical(other.messageCount, _this.messageCount) ||
                other.messageCount == _this.messageCount) &&
            (identical(other.isPinned, _this.isPinned) ||
                other.isPinned == _this.isPinned) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as AIConversation;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.userId,
        _this.title,
        _this.documentId,
        _this.taskType,
        _this.totalInputTokens,
        _this.totalOutputTokens,
        _this.messageCount,
        _this.isPinned,
        _this.createdAt,
        _this.updatedAt);
  }

  @override
  String toString() {
    final _this = this as AIConversation;
    return 'AIConversation(id: ${_this.id}, userId: ${_this.userId}, title: ${_this.title}, documentId: ${_this.documentId}, taskType: ${_this.taskType}, totalInputTokens: ${_this.totalInputTokens}, totalOutputTokens: ${_this.totalOutputTokens}, messageCount: ${_this.messageCount}, isPinned: ${_this.isPinned}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
  }
}

/// @nodoc
abstract mixin class $AIConversationCopyWith<$Res> {
  factory $AIConversationCopyWith(
          AIConversation value, $Res Function(AIConversation) _then) =
      _$AIConversationCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String userId,
      String title,
      String? documentId,
      String taskType,
      int totalInputTokens,
      int totalOutputTokens,
      int messageCount,
      bool isPinned,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$AIConversationCopyWithImpl<$Res>
    implements $AIConversationCopyWith<$Res> {
  _$AIConversationCopyWithImpl(this._self, this._then);

  final AIConversation _self;
  final $Res Function(AIConversation) _then;

  /// Create a copy of AIConversation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? documentId = freezed,
    Object? taskType = null,
    Object? totalInputTokens = null,
    Object? totalOutputTokens = null,
    Object? messageCount = null,
    Object? isPinned = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(AIConversation(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      documentId: freezed == documentId
          ? _self.documentId
          : documentId // ignore: cast_nullable_to_non_nullable
              as String?,
      taskType: null == taskType
          ? _self.taskType
          : taskType // ignore: cast_nullable_to_non_nullable
              as String,
      totalInputTokens: null == totalInputTokens
          ? _self.totalInputTokens
          : totalInputTokens // ignore: cast_nullable_to_non_nullable
              as int,
      totalOutputTokens: null == totalOutputTokens
          ? _self.totalOutputTokens
          : totalOutputTokens // ignore: cast_nullable_to_non_nullable
              as int,
      messageCount: null == messageCount
          ? _self.messageCount
          : messageCount // ignore: cast_nullable_to_non_nullable
              as int,
      isPinned: null == isPinned
          ? _self.isPinned
          : isPinned // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [AIConversation].
extension AIConversationPatterns on AIConversation {
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
    TResult Function(_AIConversation value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AIConversation() when $default != null:
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
    TResult Function(_AIConversation value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AIConversation():
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
    TResult? Function(_AIConversation value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AIConversation() when $default != null:
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
            String userId,
            String title,
            String? documentId,
            String taskType,
            int totalInputTokens,
            int totalOutputTokens,
            int messageCount,
            bool isPinned,
            DateTime createdAt,
            DateTime updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AIConversation() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.title,
            _that.documentId,
            _that.taskType,
            _that.totalInputTokens,
            _that.totalOutputTokens,
            _that.messageCount,
            _that.isPinned,
            _that.createdAt,
            _that.updatedAt);
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
            String userId,
            String title,
            String? documentId,
            String taskType,
            int totalInputTokens,
            int totalOutputTokens,
            int messageCount,
            bool isPinned,
            DateTime createdAt,
            DateTime updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AIConversation():
        return $default(
            _that.id,
            _that.userId,
            _that.title,
            _that.documentId,
            _that.taskType,
            _that.totalInputTokens,
            _that.totalOutputTokens,
            _that.messageCount,
            _that.isPinned,
            _that.createdAt,
            _that.updatedAt);
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
            String userId,
            String title,
            String? documentId,
            String taskType,
            int totalInputTokens,
            int totalOutputTokens,
            int messageCount,
            bool isPinned,
            DateTime createdAt,
            DateTime updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AIConversation() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.title,
            _that.documentId,
            _that.taskType,
            _that.totalInputTokens,
            _that.totalOutputTokens,
            _that.messageCount,
            _that.isPinned,
            _that.createdAt,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AIConversation implements AIConversation {
  const _AIConversation(
      {required this.id,
      required this.userId,
      this.title = 'Yeni Sohbet',
      this.documentId,
      this.taskType = 'chat',
      this.totalInputTokens = 0,
      this.totalOutputTokens = 0,
      this.messageCount = 0,
      this.isPinned = false,
      required this.createdAt,
      required this.updatedAt});
  factory _AIConversation.fromJson(Map<String, dynamic> json) =>
      _$AIConversationFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  @JsonKey()
  final String title;
  @override
  final String? documentId;
  @override
  @JsonKey()
  final String taskType;
  @override
  @JsonKey()
  final int totalInputTokens;
  @override
  @JsonKey()
  final int totalOutputTokens;
  @override
  @JsonKey()
  final int messageCount;
  @override
  @JsonKey()
  final bool isPinned;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  /// Create a copy of AIConversation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AIConversationCopyWith<_AIConversation> get copyWith =>
      __$AIConversationCopyWithImpl<_AIConversation>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AIConversationToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AIConversation &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.documentId, documentId) ||
                other.documentId == documentId) &&
            (identical(other.taskType, taskType) ||
                other.taskType == taskType) &&
            (identical(other.totalInputTokens, totalInputTokens) ||
                other.totalInputTokens == totalInputTokens) &&
            (identical(other.totalOutputTokens, totalOutputTokens) ||
                other.totalOutputTokens == totalOutputTokens) &&
            (identical(other.messageCount, messageCount) ||
                other.messageCount == messageCount) &&
            (identical(other.isPinned, isPinned) ||
                other.isPinned == isPinned) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        id,
        userId,
        title,
        documentId,
        taskType,
        totalInputTokens,
        totalOutputTokens,
        messageCount,
        isPinned,
        createdAt,
        updatedAt);
  }

  @override
  String toString() {
    return 'AIConversation(id: $id, userId: $userId, title: $title, documentId: $documentId, taskType: $taskType, totalInputTokens: $totalInputTokens, totalOutputTokens: $totalOutputTokens, messageCount: $messageCount, isPinned: $isPinned, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$AIConversationCopyWith<$Res>
    implements $AIConversationCopyWith<$Res> {
  factory _$AIConversationCopyWith(
          _AIConversation value, $Res Function(_AIConversation) _then) =
      __$AIConversationCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String title,
      String? documentId,
      String taskType,
      int totalInputTokens,
      int totalOutputTokens,
      int messageCount,
      bool isPinned,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$AIConversationCopyWithImpl<$Res>
    implements _$AIConversationCopyWith<$Res> {
  __$AIConversationCopyWithImpl(this._self, this._then);

  final _AIConversation _self;
  final $Res Function(_AIConversation) _then;

  /// Create a copy of AIConversation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? documentId = freezed,
    Object? taskType = null,
    Object? totalInputTokens = null,
    Object? totalOutputTokens = null,
    Object? messageCount = null,
    Object? isPinned = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_AIConversation(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      documentId: freezed == documentId
          ? _self.documentId
          : documentId // ignore: cast_nullable_to_non_nullable
              as String?,
      taskType: null == taskType
          ? _self.taskType
          : taskType // ignore: cast_nullable_to_non_nullable
              as String,
      totalInputTokens: null == totalInputTokens
          ? _self.totalInputTokens
          : totalInputTokens // ignore: cast_nullable_to_non_nullable
              as int,
      totalOutputTokens: null == totalOutputTokens
          ? _self.totalOutputTokens
          : totalOutputTokens // ignore: cast_nullable_to_non_nullable
              as int,
      messageCount: null == messageCount
          ? _self.messageCount
          : messageCount // ignore: cast_nullable_to_non_nullable
              as int,
      isPinned: null == isPinned
          ? _self.isPinned
          : isPinned // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
