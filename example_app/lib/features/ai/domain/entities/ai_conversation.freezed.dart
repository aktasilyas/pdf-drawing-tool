// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_conversation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AIConversation _$AIConversationFromJson(Map<String, dynamic> json) {
  return _AIConversation.fromJson(json);
}

/// @nodoc
mixin _$AIConversation {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get documentId => throw _privateConstructorUsedError;
  String get taskType => throw _privateConstructorUsedError;
  int get totalInputTokens => throw _privateConstructorUsedError;
  int get totalOutputTokens => throw _privateConstructorUsedError;
  int get messageCount => throw _privateConstructorUsedError;
  bool get isPinned => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this AIConversation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AIConversation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AIConversationCopyWith<AIConversation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AIConversationCopyWith<$Res> {
  factory $AIConversationCopyWith(
          AIConversation value, $Res Function(AIConversation) then) =
      _$AIConversationCopyWithImpl<$Res, AIConversation>;
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
class _$AIConversationCopyWithImpl<$Res, $Val extends AIConversation>
    implements $AIConversationCopyWith<$Res> {
  _$AIConversationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      documentId: freezed == documentId
          ? _value.documentId
          : documentId // ignore: cast_nullable_to_non_nullable
              as String?,
      taskType: null == taskType
          ? _value.taskType
          : taskType // ignore: cast_nullable_to_non_nullable
              as String,
      totalInputTokens: null == totalInputTokens
          ? _value.totalInputTokens
          : totalInputTokens // ignore: cast_nullable_to_non_nullable
              as int,
      totalOutputTokens: null == totalOutputTokens
          ? _value.totalOutputTokens
          : totalOutputTokens // ignore: cast_nullable_to_non_nullable
              as int,
      messageCount: null == messageCount
          ? _value.messageCount
          : messageCount // ignore: cast_nullable_to_non_nullable
              as int,
      isPinned: null == isPinned
          ? _value.isPinned
          : isPinned // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AIConversationImplCopyWith<$Res>
    implements $AIConversationCopyWith<$Res> {
  factory _$$AIConversationImplCopyWith(_$AIConversationImpl value,
          $Res Function(_$AIConversationImpl) then) =
      __$$AIConversationImplCopyWithImpl<$Res>;
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
class __$$AIConversationImplCopyWithImpl<$Res>
    extends _$AIConversationCopyWithImpl<$Res, _$AIConversationImpl>
    implements _$$AIConversationImplCopyWith<$Res> {
  __$$AIConversationImplCopyWithImpl(
      _$AIConversationImpl _value, $Res Function(_$AIConversationImpl) _then)
      : super(_value, _then);

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
    return _then(_$AIConversationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      documentId: freezed == documentId
          ? _value.documentId
          : documentId // ignore: cast_nullable_to_non_nullable
              as String?,
      taskType: null == taskType
          ? _value.taskType
          : taskType // ignore: cast_nullable_to_non_nullable
              as String,
      totalInputTokens: null == totalInputTokens
          ? _value.totalInputTokens
          : totalInputTokens // ignore: cast_nullable_to_non_nullable
              as int,
      totalOutputTokens: null == totalOutputTokens
          ? _value.totalOutputTokens
          : totalOutputTokens // ignore: cast_nullable_to_non_nullable
              as int,
      messageCount: null == messageCount
          ? _value.messageCount
          : messageCount // ignore: cast_nullable_to_non_nullable
              as int,
      isPinned: null == isPinned
          ? _value.isPinned
          : isPinned // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AIConversationImpl implements _AIConversation {
  const _$AIConversationImpl(
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

  factory _$AIConversationImpl.fromJson(Map<String, dynamic> json) =>
      _$$AIConversationImplFromJson(json);

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

  @override
  String toString() {
    return 'AIConversation(id: $id, userId: $userId, title: $title, documentId: $documentId, taskType: $taskType, totalInputTokens: $totalInputTokens, totalOutputTokens: $totalOutputTokens, messageCount: $messageCount, isPinned: $isPinned, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AIConversationImpl &&
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
  int get hashCode => Object.hash(
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

  /// Create a copy of AIConversation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AIConversationImplCopyWith<_$AIConversationImpl> get copyWith =>
      __$$AIConversationImplCopyWithImpl<_$AIConversationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AIConversationImplToJson(
      this,
    );
  }
}

abstract class _AIConversation implements AIConversation {
  const factory _AIConversation(
      {required final String id,
      required final String userId,
      final String title,
      final String? documentId,
      final String taskType,
      final int totalInputTokens,
      final int totalOutputTokens,
      final int messageCount,
      final bool isPinned,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$AIConversationImpl;

  factory _AIConversation.fromJson(Map<String, dynamic> json) =
      _$AIConversationImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get title;
  @override
  String? get documentId;
  @override
  String get taskType;
  @override
  int get totalInputTokens;
  @override
  int get totalOutputTokens;
  @override
  int get messageCount;
  @override
  bool get isPinned;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of AIConversation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AIConversationImplCopyWith<_$AIConversationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
