// app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Brand (QuickBooks Style) ───────────────────
  static const primary      = Color(0xFF2CA01C); // QB Green
  static const primaryDark  = Color(0xFF108000);
  static const primaryLight = Color(0xFFE8F5E9);

  // ─── Surfaces (Light) ───────────────────────────
  static const bgLight         = Color(0xFFF4F5F8); // Standard QB background
  static const surfaceLight    = Color(0xFFFFFFFF);
  static const surface2Light   = Color(0xFFFAFAFA);
  static const offsetLight     = Color(0xFFECEEF1); // Sidebar bg
  static const dividerLight    = Color(0xFFD4D7DC);
  static const borderLight     = Color(0xFFD4D7DC);

  // ─── Surfaces (Dark) ────────────────────────────
  static const bgDark          = Color(0xFF121212);
  static const surfaceDark     = Color(0xFF1E1E1E);
  static const surface2Dark    = Color(0xFF2A2A2A);
  static const offsetDark      = Color(0xFF181818);
  static const dividerDark     = Color(0xFF333333);
  static const borderDark      = Color(0xFF333333);
  static const sidebarBg       = Color(0xFF2E3344); // QuickBooks Dark Navy
  static const sidebarActive   = Color(0xFF3E4459);

  // ─── Text (Light) ───────────────────────────────
  static const textLight       = Color(0xFF393A3D);
  static const textMutedLight  = Color(0xFF6B6C72);
  static const textFaintLight  = Color(0xFFA0A2A7);

  // ─── Text (Dark) ────────────────────────────────
  static const textDark        = Color(0xFFE0E0E0);
  static const textMutedDark   = Color(0xFF9E9E9E);
  static const textFaintDark   = Color(0xFF757575);

  // ─── Semantic ───────────────────────────────────
  static const success         = Color(0xFF2CA01C);
  static const successDark     = Color(0xFF4CAF50);
  static const error           = Color(0xFFD32F2F);
  static const errorDark       = Color(0xFFEF5350);
  static const warning         = Color(0xFFF57C00);
  static const warningDark     = Color(0xFFFF9800);
  static const info            = Color(0xFF0288D1);
  static const infoDark        = Color(0xFF29B6F6);
}