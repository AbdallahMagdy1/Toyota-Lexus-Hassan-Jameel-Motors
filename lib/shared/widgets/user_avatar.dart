import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injector.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/profile/bloc/avatar_cubit.dart';
import '../../features/settings/bloc/locale_cubit.dart';

/// The signed-in user's photo wherever it appears outside the profile screen
/// (side menu header, home app bar). Falls back to the first letter of the
/// name — the same roundel it replaces — so nothing shifts while the photo
/// loads, or when the account simply has no photo.
final class UserAvatar extends StatefulWidget {
  const UserAvatar({
    super.key,
    required this.size,
    required this.background,
    required this.foreground,
    this.border,
  });

  final double size;
  final Color background;

  /// Colour of the fallback initial / person glyph.
  final Color foreground;
  final Color? border;

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch once per account. AvatarCubit ignores repeat calls, so this stays
    // cheap even though every avatar on screen asks.
    final guid = context.read<AuthBloc>().state.user?.guid;
    sl<AvatarCubit>().ensure(guid);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final name = context.select((AuthBloc b) => b.state.user?.displayName(lang)) ?? '';
    final initial =
        name.trim().isEmpty ? null : name.trim().characters.first.toUpperCase();

    return BlocBuilder<AvatarCubit, Uint8List?>(
      bloc: sl<AvatarCubit>(),
      builder: (context, photo) {
        return Container(
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: widget.background,
            shape: BoxShape.circle,
            border: widget.border == null
                ? null
                : Border.all(color: widget.border!),
          ),
          child: photo == null
              ? (initial == null
                  ? Icon(Icons.person_rounded,
                      size: widget.size * 0.5, color: widget.foreground)
                  : Text(
                      initial,
                      style: TextStyle(
                        fontSize: widget.size * 0.4,
                        fontWeight: FontWeight.w800,
                        color: widget.foreground,
                      ),
                    ))
              : Image.memory(
                  photo,
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  // A corrupt blob must not take the whole header down.
                  errorBuilder: (_, _, _) => Icon(Icons.person_rounded,
                      size: widget.size * 0.5, color: widget.foreground),
                ),
        );
      },
    );
  }
}
