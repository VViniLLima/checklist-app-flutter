import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_controller.dart';

class UserAvatarWidget extends StatelessWidget {
  const UserAvatarWidget({
    super.key,
    this.radius = 22,
    this.backgroundColor,
    this.showAccentDot = false,
  });

  final double radius;
  final Color? backgroundColor;
  final bool showAccentDot;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final localAvatarPath = auth.localAvatarPath;
    final avatarUrl = auth.userAvatarUrl;

    ImageProvider? backgroundImage;
    if (localAvatarPath != null && File(localAvatarPath!).existsSync()) {
      backgroundImage = FileImage(File(localAvatarPath));
    } else if (avatarUrl != null) {
      backgroundImage = NetworkImage(avatarUrl!);
    } else {
      backgroundImage = const AssetImage('assets/Images/ProfilePicture.png');
    }

    return CircleAvatar(
      key: ValueKey(
        'avatar_${localAvatarPath ?? avatarUrl ?? 'default'}_${auth.avatarVersion}',
      ),
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.white.withOpacity(0.2),
      backgroundImage: backgroundImage,
    );
  }
}
