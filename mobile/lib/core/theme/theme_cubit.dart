import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../storage/storage_service.dart';

/// Cubit managing dynamic theme mode switching and local persistence.
class ThemeCubit extends Cubit<ThemeMode> {
  final StorageService storageService;

  ThemeCubit({required this.storageService})
      : super(storageService.getThemeMode());

  /// Toggles between [ThemeMode.dark] and [ThemeMode.light].
  void toggleTheme() {
    final nextMode =
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(nextMode);
  }

  /// Sets and persists a specific [ThemeMode].
  void setThemeMode(ThemeMode mode) {
    storageService.saveThemeMode(mode);
    emit(mode);
  }
}
