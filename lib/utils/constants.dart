import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Supabase Configuration
const String supabaseUrl = 'https://wxryjxixsybmfrytcjur.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind4cnlqeGl4c3libWZyeXRjanVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMxNDk1MjQsImV4cCI6MjA5ODcyNTUyNH0.yG2mqLWqPVJwl8p1Qi_TrTt3FxnqC2z7N3_8x52kiHY';

// Application Theme Colors
class AppColors {
  static const Color primary = Color(0xFFE53935); // Merah (#E53935)
  static const Color onPrimary = Color(0xFFFFFFFF); // Putih (#FFFFFF)
  static const Color background = Color(0xFFF5F5F5); // Abu-abu Muda (#F5F5F5)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF212121); // Hitam (#212121)
  static const Color textMuted = Color(0xFF757575);
  static const Color border = Color(0xFFE0E0E0);
  
  static const Color green = Color(0xFF4CAF50);
  static const Color orange = Color(0xFFFF9800);
}

// Utility formatting
String formatIDR(dynamic amount) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  if (amount == null) return formatter.format(0);
  if (amount is String) {
    return formatter.format(double.tryParse(amount) ?? 0);
  }
  return formatter.format(amount);
}
