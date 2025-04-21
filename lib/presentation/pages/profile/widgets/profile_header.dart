// lib/presentation/pages/profile/widgets/profile_header.dart
import 'package:flutter/material.dart';
import '../../../../core/models/profile_model.dart';

class ProfileHeader extends StatelessWidget {
  final ProfileModel profileData;

  const ProfileHeader({
    Key? key,
    required this.profileData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFFF7A2E),
      ),
      child: Column(
        children: [
          // Profile picture
          profileData.profilePicture != null
              ? CircleAvatar(
                  radius: 48,
                  backgroundImage: NetworkImage(profileData.profilePicture!),
                )
              : const CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Color(0xFFFF7A2E),
                  ),
                ),
          const SizedBox(height: 12),
          // User name
          Text(
            profileData.fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          // Email
          Text(
            profileData.email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
