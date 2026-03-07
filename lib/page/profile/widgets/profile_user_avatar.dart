import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';

class ProfileUserAvatar extends StatelessWidget {
  final String? avatarUrl;

  /// Ảnh từ bytes (ảnh vừa chọn hoặc ảnh đã lưu dạng local)
  final Uint8List? avatarBytes;
  final double size;
  final double iconSize;
  final double editIconSize;
  final double editPadding;

  /// Bấm vào avatar để đổi ảnh (null = không cho đổi)
  final VoidCallback? onTap;

  const ProfileUserAvatar({
    super.key,
    this.avatarUrl,
    this.avatarBytes,
    this.size = 100,
    this.iconSize = 50,
    this.editIconSize = 16,
    this.editPadding = 6,
    this.onTap,
  });

  bool get _hasImage =>
      avatarBytes != null || (avatarUrl != null && avatarUrl != '__local__');

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[100]!, width: 4),
            image: _buildDecorationImage(),
            color: Colors.grey[200],
          ),
          child:
              !_hasImage
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

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }

  DecorationImage? _buildDecorationImage() {
    if (avatarBytes != null && avatarBytes!.isNotEmpty) {
      return DecorationImage(
        image: MemoryImage(avatarBytes!),
        fit: BoxFit.cover,
      );
    }
    if (avatarUrl != null && avatarUrl != '__local__') {
      return DecorationImage(
        image: NetworkImage(avatarUrl!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }
}
