/// Supabase user model mapping for the auth feature.
import 'package:example_app/features/auth/domain/entities/user.dart' as domain;
import 'package:supabase_flutter/supabase_flutter.dart';

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory UserModel.fromSupabaseUser(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      displayName: _readString(metadata, const ['display_name', 'full_name', 'name']),
      photoUrl: _readString(metadata, const ['avatar_url', 'photo_url', 'picture']),
      createdAt: DateTime.parse(user.createdAt),
      lastLoginAt: user.lastSignInAt == null ? null : DateTime.parse(user.lastSignInAt!),
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt: json['last_login_at'] == null
          ? null
          : DateTime.parse(json['last_login_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  domain.User toEntity() {
    return domain.User(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  static String? _readString(
    Map<String, dynamic> metadata,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = metadata[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}
