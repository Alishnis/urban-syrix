import 'package:hackathon_net/features/auth/domain/app_role.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.role,
  });

  final String id;
  final String email;
  final AppRole role;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      role: AppRole.fromKey(map['role'] as String?),
    );
  }
}
