import 'package:flutter/material.dart';

class ReelUserInfo extends StatelessWidget {
  final String userId;
  final String? userName;
  final String? userAvatar;
  final VoidCallback? onUserTap;

  const ReelUserInfo({
    super.key,
    required this.userId,
    this.userName,
    this.userAvatar,
    this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUserTap,
      child: Row(
        children: [
          // User Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[800],
            backgroundImage: userAvatar != null ? NetworkImage(userAvatar!) : null,
            child: userAvatar == null
                ? const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  )
                : null,
          ),
          
          const SizedBox(width: 12),
          
          // User Name
          Expanded(
            child: Text(
              userName ?? 'User ${userId.substring(0, 8)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
