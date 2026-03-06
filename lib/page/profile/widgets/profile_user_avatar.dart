import 'package:flutter/material.dart';

class ProfileUserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final double iconSize;
  final double editIconSize;
  final double editPadding;

  const ProfileUserAvatar({
    super.key,
    this.avatarUrl,
    this.size = 100,
    this.iconSize = 50,
    this.editIconSize = 16,
    this.editPadding = 6,
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
            image:
                avatarUrl != null
                    ? DecorationImage(
                      image: NetworkImage(avatarUrl!),
                      fit: BoxFit.cover,
                    )
                    : null,
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
          child: Container(
            padding: EdgeInsets.all(editPadding),
            decoration: const BoxDecoration(
              color: Color(0xFF137FEC),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.edit, color: Colors.white, size: editIconSize),
          ),
        ),
      ],
    );
  }
}
