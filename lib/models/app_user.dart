import 'user_profile.dart';

enum UserRole { user, admin }

class AppUser {
  final String username;
  final String salt;
  final String passwordHash;
  final UserRole role;
  final UserProfile? profile;

  const AppUser({
    required this.username,
    required this.salt,
    required this.passwordHash,
    required this.role,
    this.profile,
  });

  AppUser copyWith({UserRole? role, UserProfile? profile}) => AppUser(
    username: username,
    salt: salt,
    passwordHash: passwordHash,
    role: role ?? this.role,
    profile: profile ?? this.profile,
  );

  Map<String, dynamic> toJson() => {
    'username': username,
    'salt': salt,
    'passwordHash': passwordHash,
    'role': role.name,
    'profile': profile?.toJson(),
  };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    username: j['username'] as String,
    salt: j['salt'] as String,
    passwordHash: j['passwordHash'] as String,
    role: UserRole.values.byName(j['role'] as String),
    profile: j['profile'] == null
        ? null
        : UserProfile.fromJson(j['profile'] as Map<String, dynamic>),
  );
}
