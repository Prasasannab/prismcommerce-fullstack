import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../bloc/auth_bloc.dart';
import '../screens/login_screen.dart';

/// Modal bottom sheet guard that verifies user session before critical actions
/// (such as checkout or profile management). Prompts login/registration if unauthenticated.
class AuthGuardSheet extends StatelessWidget {
  const AuthGuardSheet({super.key});

  /// Static helper to check auth status and present login sheet if unauthenticated.
  /// Returns `true` if the user is (or becomes) authenticated, `false` if dismissed without login.
  static Future<bool> show(BuildContext context) async {
    final authBloc = context.read<AuthBloc>();
    if (authBloc.state is AuthAuthenticated) {
      return true;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const AuthGuardSheet(),
      ),
    );

    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: colors.cardBorder, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top draggable pill handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Embedded Login Screen inside bottom sheet
          const Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              child: LoginScreen(isModal: true),
            ),
          ),
        ],
      ),
    );
  }
}
