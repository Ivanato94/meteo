import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

class WeatherElementsIcon extends StatefulWidget {
  final bool isDark;
  final double size;

  const WeatherElementsIcon({
    super.key,
    required this.isDark,
    this.size = 220,
  });

  @override
  State<WeatherElementsIcon> createState() => _WeatherElementsIconState();
}

class _WeatherElementsIconState extends State<WeatherElementsIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _questionController;

  @override
  void initState() {
    super.initState();
    _questionController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        
        final screenWidth = constraints.maxWidth > 0 ? constraints.maxWidth : MediaQuery.of(context).size.width;
        final screenHeight = constraints.maxHeight > 0 ? constraints.maxHeight : MediaQuery.of(context).size.height;
        final isLandscape = screenWidth > screenHeight;
        final isWideScreen = screenWidth > 768;
        final isTablet = screenWidth > 600 && screenWidth <= 768;
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        
        
        double adaptiveSize;
        if (isWideScreen) {
          
          adaptiveSize = isLandscape ? math.min(300, screenHeight * 0.6) : math.min(350, screenWidth * 0.4);
        } else if (isTablet) {
          
          adaptiveSize = isLandscape ? screenHeight * 0.7 : screenWidth * 0.6;
        } else {
          
          adaptiveSize = isLandscape ? screenHeight * 0.8 : math.min(widget.size, screenWidth * 0.8);
        }
        
        
        if (keyboardHeight > 0 && !isLandscape && !isWideScreen) {
          adaptiveSize = adaptiveSize * 0.7;
        }
        
        
        adaptiveSize = math.max(adaptiveSize, 150);

        return SizedBox(
          width: adaptiveSize,
          height: adaptiveSize,
          child: Stack(
            children: [
              
              _buildResponsiveLotties(adaptiveSize, isWideScreen, isTablet),
              
              
              _buildResponsiveQuestionMark(adaptiveSize, isWideScreen, isTablet),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResponsiveQuestionMark(double size, bool isWideScreen, bool isTablet) {
    return AnimatedBuilder(
      animation: _questionController,
      builder: (context, child) {
        final scale = 0.8 + (math.sin(_questionController.value * 2 * math.pi) * 0.2);
        
        double fontSize;
        if (isWideScreen) {
          fontSize = size * 0.16;
        } else if (isTablet) {
          fontSize = size * 0.18;
        } else {
          fontSize = size * 0.20;
        }
        
        return Center(
          child: Transform.scale(
            scale: scale,
            child: Text(
              '?',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF29B6F6),
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2 * scale),
                    offset: Offset(0, 3 * scale),
                    blurRadius: 8 * scale,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveLotties(double size, bool isWideScreen, bool isTablet) {
    
    double lottieSize;
    double distanceFromCenter;
    
    if (isWideScreen) {
      lottieSize = size * 0.28; 
      distanceFromCenter = size * 0.34;
    } else if (isTablet) {
      lottieSize = size * 0.30;
      distanceFromCenter = size * 0.32;
    } else {
      lottieSize = size * 0.32;
      distanceFromCenter = size * 0.30;
    }
    
    final centerX = size / 2;
    final centerY = size / 2;
    
    
    final maxDistance = (size - lottieSize) / 2 - 10; 
    final safeDistance = math.min(distanceFromCenter, maxDistance);
    
    
    final optimizedForDevice = isWideScreen ? true : false; 
    
    return Stack(
      children: [
        
        Positioned(
          top: centerY - safeDistance - lottieSize/2,
          left: centerX - lottieSize/2,
          child: _buildLottieContainer(
            'assets/animations/sun.json', 
            lottieSize, 
            optimizedForDevice
          ),
        ),
        
        
        Positioned(
          top: centerY - lottieSize/2,
          left: centerX + safeDistance - lottieSize/2,
          child: _buildLottieContainer(
            'assets/animations/rain.json', 
            lottieSize, 
            optimizedForDevice
          ),
        ),
        
        
        Positioned(
          top: centerY + safeDistance - lottieSize/2,
          left: centerX - lottieSize/2,
          child: _buildLottieContainer(
            'assets/animations/snow.json', 
            lottieSize, 
            optimizedForDevice
          ),
        ),
        
        
        Positioned(
          top: centerY - lottieSize/2,
          left: centerX - safeDistance - lottieSize/2,
          child: _buildLottieContainer(
            'assets/animations/cloud.json', 
            lottieSize, 
            optimizedForDevice
          ),
        ),
      ],
    );
  }

  Widget _buildLottieContainer(String assetPath, double size, bool optimizedForDevice) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        assetPath,
        fit: BoxFit.contain,
        repeat: true,
        animate: true,
        
        options: LottieOptions(
          enableMergePaths: false,
        ),
        errorBuilder: (context, error, stackTrace) {
          
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFF81D4FA).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(size * 0.2),
            ),
            child: Icon(
              _getIconForAsset(assetPath),
              size: size * 0.4,
              color: const Color(0xFF29B6F6),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForAsset(String assetPath) {
    if (assetPath.contains('sun')) return Icons.wb_sunny;
    if (assetPath.contains('rain')) return Icons.grain;
    if (assetPath.contains('snow')) return Icons.ac_unit;
    if (assetPath.contains('cloud')) return Icons.cloud;
    return Icons.wb_cloudy;
  }
}