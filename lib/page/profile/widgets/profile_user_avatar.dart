import 'dart:convert';

import 'package:flutter/material.dart';

class ProfileUserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final double iconSize;
  final double editIconSize;
  final double editPadding;
  final VoidCallback? onEditTap;

  const ProfileUserAvatar({
    super.key,
    this.avatarUrl,
    this.size = 100,
    this.iconSize = 50,
    this.editIconSize = 16,
    this.editPadding = 6,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[100]!, width: 4),
            image: _buildAvatarImage(),
            color: Colors.grey[200],
          ),
          child:
              avatarUrl == null
                  ? Icon(Icons.person, size: iconSize, color: Colors.grey)
                  : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onEditTap,
              customBorder: const CircleBorder(),
              child: Container(
                padding: EdgeInsets.all(editPadding),
                decoration: const BoxDecoration(
                  color: Color(0xFF137FEC),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit, color: Colors.white, size: editIconSize),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DecorationImage? _buildAvatarImage() {
    if (avatarUrl == null || avatarUrl!.isEmpty) return null;

    if (avatarUrl!.startsWith('data:image')) {
      final commaIndex = avatarUrl!.indexOf(',');
      if (commaIndex == -1) return null;
      final base64Part = avatarUrl!.substring(commaIndex + 1);
      return DecorationImage(
        image: MemoryImage(base64Decode(base64Part)),
        fit: BoxFit.cover,
      );
    }

    return DecorationImage(
      image: NetworkImage(avatarUrl!),
      fit: BoxFit.cover,
    );
  }
}
