import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/constants.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              Color(0xFFB71C1C), // Darker red shade for depth
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.onPrimary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 3,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              // Brand Title
              const Text(
                "KrispiinAja",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onPrimary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              // Tagline
              Text(
                "Kasir Cepat, Bisnis Hebat",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: AppColors.onPrimary.withOpacity(0.9),
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),
              // Loader
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.onPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
