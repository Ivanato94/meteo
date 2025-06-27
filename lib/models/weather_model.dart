import 'package:flutter/material.dart';
import 'dart:math' as math;

class WeatherData {
  final String cityName, country, description, icon;
  final double temperature, tempMin, tempMax, windSpeed, feelsLike, lat, lon;
  final int humidity, pressure, visibility, clouds, timezoneOffset;
  final DateTime timestamp, sunrise, sunset;

  WeatherData({
    required this.cityName, required this.country, required this.temperature,
    required this.tempMin, required this.tempMax, required this.description,
    required this.icon, required this.humidity, required this.windSpeed,
    required this.pressure, required this.feelsLike, required this.timestamp,
    required this.sunrise, required this.sunset, required this.lat,
    required this.lon, required this.visibility, required this.clouds,
    this.timezoneOffset = 0,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final timezoneOffset = json['timezone'] ?? 0;
    return WeatherData(
      cityName: json['name'], country: json['sys']['country'],
      temperature: json['main']['temp'].toDouble(), tempMin: json['main']['temp_min'].toDouble(),
      tempMax: json['main']['temp_max'].toDouble(), description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'], humidity: json['main']['humidity'],
      windSpeed: json['wind']['speed'].toDouble(), pressure: json['main']['pressure'],
      feelsLike: json['main']['feels_like'].toDouble(), timestamp: DateTime.now(),
      
      sunrise: DateTime.fromMillisecondsSinceEpoch((json['sys']['sunrise'] + timezoneOffset) * 1000, isUtc: true),
      sunset: DateTime.fromMillisecondsSinceEpoch((json['sys']['sunset'] + timezoneOffset) * 1000, isUtc: true),
      lat: json['coord']['lat'].toDouble(), lon: json['coord']['lon'].toDouble(),
      visibility: json['visibility'] ?? 10000, clouds: json['clouds']['all'] ?? 0,
      timezoneOffset: timezoneOffset,
    );
  }

  bool get isDayTime {
    final utcNow = DateTime.now().toUtc();
    final cityTime = utcNow.add(Duration(seconds: timezoneOffset));
    
    
    return cityTime.isAfter(sunrise) && cityTime.isBefore(sunset);
  }

  String get daylightInfo {
    final utcNow = DateTime.now().toUtc();
    final cityTime = utcNow.add(Duration(seconds: timezoneOffset));
    
    
    if (cityTime.isBefore(sunrise)) {
      return 'Alba tra ${_formatDuration(sunrise.difference(cityTime))}';
    } else if (cityTime.isAfter(sunset)) {
      final tomorrowSunrise = sunrise.add(const Duration(days: 1));
      return 'Alba tra ${_formatDuration(tomorrowSunrise.difference(cityTime))}';
    } else {
      return 'Tramonto tra ${_formatDuration(sunset.difference(cityTime))}';
    }
  }

  
  String get oraAttuale {
    final utcNow = DateTime.now().toUtc();
    final cityTime = utcNow.add(Duration(seconds: timezoneOffset));
    return '${cityTime.hour.toString().padLeft(2, '0')}:${cityTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) => duration.inHours > 0 
    ? '${duration.inHours}h ${duration.inMinutes % 60}min' 
    : '${duration.inMinutes}min';

  Widget getApiWeatherIcon({double size = 120, bool? forceDay}) => TweenAnimationBuilder<double>(
    duration: const Duration(milliseconds: 800), tween: Tween(begin: 0.0, end: 1.0),
    builder: (context, value, child) => Transform.scale(
      scale: 0.8 + (0.2 * value),
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.2),
          gradient: RadialGradient(colors: [weatherThemeColor.withValues(alpha: 0.2), weatherThemeColor.withValues(alpha: 0.05)]),
          boxShadow: [BoxShadow(color: weatherThemeColor.withValues(alpha: 0.3), blurRadius: size * 0.15, offset: Offset(0, size * 0.05))],
        ),
        child: CustomPaint(size: Size(size, size), painter: WeatherIconPainter(icon, size: size, isDayTime: forceDay ?? isDayTime)),
      ),
    ),
  );

  Color get weatherThemeColor {
    switch (icon.substring(0, 2)) {
      case '01': return const Color(0xFFFF8C42);
      case '02': return const Color(0xFF29B6F6);
      case '03': case '04': return const Color(0xFF607D8B);
      case '09': case '10': return const Color(0xFF1976D2);
      case '11': return const Color(0xFF283593);
      case '13': return const Color(0xFF81D4FA);
      case '50': return const Color(0xFFB0BEC5);
      default: return const Color(0xFF66BB6A);
    }
  }

  Widget get apiWeatherIcon => getApiWeatherIcon();
}

class ForecastData {
  final List<DailyForecast> forecasts;
  ForecastData({required this.forecasts});

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> list = json['list'];
    final Map<String, List<Map<String, dynamic>>> groupedByDate = {};

    for (var item in list) {
      final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      groupedByDate.putIfAbsent(dateKey, () => []).add(item);
    }

    final forecasts = groupedByDate.entries.take(5).map((entry) => DailyForecast.fromJsonList(entry.value)).toList();
    return ForecastData(forecasts: forecasts);
  }
}

class DailyForecast {
  final DateTime date;
  final double tempMin, tempMax, windSpeed;
  final String description, icon;
  final int humidity, chanceOfRain;

  DailyForecast({
    required this.date, required this.tempMin, required this.tempMax,
    required this.description, required this.icon, required this.humidity,
    required this.windSpeed, required this.chanceOfRain,
  });

  factory DailyForecast.fromJsonList(List<Map<String, dynamic>> dayData) {
    final firstItem = dayData.first;
    String bestIcon = firstItem['weather'][0]['icon'];
    
    for (var item in dayData) {
      final iconCode = item['weather'][0]['icon'];
      if (iconCode.endsWith('d')) {
        bestIcon = iconCode;
        break;
      }
    }
    
    if (bestIcon.endsWith('n')) bestIcon = '${bestIcon.substring(0, 2)}d';
    
    return DailyForecast(
      date: DateTime.fromMillisecondsSinceEpoch(firstItem['dt'] * 1000),
      tempMin: dayData.map((item) => item['main']['temp_min'].toDouble()).reduce((a, b) => a < b ? a : b),
      tempMax: dayData.map((item) => item['main']['temp_max'].toDouble()).reduce((a, b) => a > b ? a : b),
      description: dayData.first['weather'][0]['description'], icon: bestIcon,
      humidity: (dayData.map((item) => item['main']['humidity']).reduce((a, b) => a + b) / dayData.length).round(),
      windSpeed: dayData.map((item) => item['wind']['speed'].toDouble()).reduce((a, b) => a + b) / dayData.length,
      chanceOfRain: dayData.where((item) => item.containsKey('rain')).length * 100 ~/ dayData.length,
    );
  }

  String get dayName => const ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'][date.weekday - 1];
  String get formattedDate => '${date.day}/${date.month}';
}

class WeatherIconPainter extends CustomPainter {
  final String iconCode;
  final double size;
  final bool isDayTime;

  WeatherIconPainter(this.iconCode, {this.size = 120, required this.isDayTime});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final size = canvasSize.width;
    final isNight = !isDayTime;
    
    switch (iconCode.substring(0, 2)) {
      case '01': isNight ? _drawClearNightWithStarsSimple(canvas, size) : _drawSun(canvas, size); break;
      case '02': isNight ? _drawPartlyCloudyNight(canvas, size) : _drawPartlyCloudy(canvas, size); break;
      case '03': case '04': _drawCloudy(canvas, size, isNight); break;
      case '09': case '10': _drawRainy(canvas, size, isNight); break;
      case '11': _drawThunderstorm(canvas, size, isNight); break;
      case '13': _drawSnowy(canvas, size, isNight); break;
      case '50': _drawFoggy(canvas, size, isNight); break;
      default: isNight ? _drawClearNightWithStarsSimple(canvas, size) : _drawSun(canvas, size);
    }
  }

  void _drawSun(Canvas canvas, double size) {
    final center = Offset(size / 2, size / 2);
    final radius = size * 0.15;
    final sunPaint = Paint()..shader = const RadialGradient(colors: [Color(0xFFFFEB3B), Color(0xFFFF9800)]).createShader(Rect.fromCircle(center: center, radius: radius));
    final rayPaint = Paint()..color = const Color(0xFFFFEB3B)..strokeWidth = size * 0.02..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (math.pi / 180);
      canvas.drawLine(
        Offset(center.dx + (radius + size * 0.05) * math.cos(angle), center.dy + (radius + size * 0.05) * math.sin(angle)),
        Offset(center.dx + (radius + size * 0.15) * math.cos(angle), center.dy + (radius + size * 0.15) * math.sin(angle)),
        rayPaint,
      );
    }
    canvas.drawCircle(center, radius, sunPaint);
  }

  void _drawClearNightWithStarsSimple(Canvas canvas, double size) {
    _drawStars(canvas, size);
    
    final center = Offset(size * 0.55, size * 0.45);
    final radius = size * 0.12;
    final moonPaint = Paint()..shader = const RadialGradient(colors: [Color(0xFFF5F5DC), Color(0xFFE6E6FA)]).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius, moonPaint);
    
    final shadowPaint = Paint()..color = const Color(0xFF1A1A2E);
    final shadowCenter = Offset(center.dx + radius * 0.4, center.dy);
    canvas.drawCircle(shadowCenter, radius * 0.8, shadowPaint);
    
    final craterPaint = Paint()..color = const Color(0xFFD3D3D3).withValues(alpha: 0.3);
    canvas.drawCircle(Offset(center.dx - radius * 0.3, center.dy - radius * 0.2), radius * 0.1, craterPaint);
    canvas.drawCircle(Offset(center.dx - radius * 0.1, center.dy + radius * 0.3), radius * 0.08, craterPaint);
  }

  void _drawStars(Canvas canvas, double size) {
    final starPaint = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9)..strokeWidth = size * 0.01..strokeCap = StrokeCap.round;
    final starsData = [
      [size * 0.2, size * 0.15, size * 0.025], [size * 0.8, size * 0.2, size * 0.02],
      [size * 0.15, size * 0.4, size * 0.022], [size * 0.85, size * 0.45, size * 0.018],
      [size * 0.25, size * 0.7, size * 0.02], [size * 0.75, size * 0.75, size * 0.018],
      [size * 0.9, size * 0.6, size * 0.015], [size * 0.1, size * 0.8, size * 0.017],
    ];

    for (var star in starsData) {
      final x = star[0]; final y = star[1]; final starSize = star[2];
      canvas.drawLine(Offset(x - starSize, y), Offset(x + starSize, y), starPaint);
      canvas.drawLine(Offset(x, y - starSize), Offset(x, y + starSize), starPaint);
    }
  }
   
  void _drawPartlyCloudy(Canvas canvas, double size) {
    final sunCenter = Offset(size * 0.65, size * 0.35);
    final sunRadius = size * 0.12;
    final sunPaint = Paint()..shader = const RadialGradient(colors: [Color(0xFFFFEB3B), Color(0xFFFF9800)]).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));
    final rayPaint = Paint()..color = const Color(0xFFFFEB3B)..strokeWidth = size * 0.015..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final angle = (i * 90 - 45) * (math.pi / 180);
      canvas.drawLine(
        Offset(sunCenter.dx + (sunRadius + size * 0.03) * math.cos(angle), sunCenter.dy + (sunRadius + size * 0.03) * math.sin(angle)),
        Offset(sunCenter.dx + (sunRadius + size * 0.08) * math.cos(angle), sunCenter.dy + (sunRadius + size * 0.08) * math.sin(angle)),
        rayPaint,
      );
    }
    canvas.drawCircle(sunCenter, sunRadius, sunPaint);
    _drawCloud(canvas, size, Offset(size * 0.4, size * 0.55), size * 0.35);
  }

  void _drawPartlyCloudyNight(Canvas canvas, double size) {
    _drawStars(canvas, size);
    final moonCenter = Offset(size * 0.65, size * 0.35);
    final moonRadius = size * 0.1;
    final moonPaint = Paint()..shader = const RadialGradient(colors: [Color(0xFFF5F5DC), Color(0xFFE6E6FA)]).createShader(Rect.fromCircle(center: moonCenter, radius: moonRadius));
    canvas.drawCircle(moonCenter, moonRadius, moonPaint);
    _drawCloud(canvas, size, Offset(size * 0.4, size * 0.55), size * 0.35, color1: const Color(0xFF4A5568), color2: const Color(0xFF2D3748));
  }

  void _drawCloudy(Canvas canvas, double size, bool isNight) {
    if (isNight) _drawStars(canvas, size);
    final color1 = isNight ? const Color(0xFF4A5568) : const Color(0xFFFFFFFF);
    final color2 = isNight ? const Color(0xFF2D3748) : const Color(0xFFE0E0E0);
    _drawCloud(canvas, size, Offset(size * 0.5, size * 0.5), size * 0.4, color1: color1, color2: color2);
  }

  void _drawRainy(Canvas canvas, double size, bool isNight) {
    if (isNight) {
      final starPaint = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6)..strokeWidth = size * 0.008..strokeCap = StrokeCap.round;
      final starsData = [[size * 0.85, size * 0.2, size * 0.015], [size * 0.1, size * 0.8, size * 0.012], [size * 0.9, size * 0.7, size * 0.01]];
      for (var star in starsData) {
        final x = star[0]; final y = star[1]; final starSize = star[2];
        canvas.drawLine(Offset(x - starSize, y), Offset(x + starSize, y), starPaint);
        canvas.drawLine(Offset(x, y - starSize), Offset(x, y + starSize), starPaint);
      }
    }
    
    final cloudColor1 = isNight ? const Color(0xFF4A5568) : const Color(0xFF78909C);
    final cloudColor2 = isNight ? const Color(0xFF2D3748) : const Color(0xFF546E7A);
    final rainColor = isNight ? const Color(0xFF63B3ED) : const Color(0xFF42A5F5);
    
    _drawCloud(canvas, size, Offset(size * 0.5, size * 0.4), size * 0.35, color1: cloudColor1, color2: cloudColor2);
    final rainPaint = Paint()..color = rainColor..strokeWidth = size * 0.02..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      final x = size * (0.25 + i * 0.1);
      canvas.drawLine(Offset(x, size * 0.65), Offset(x, size * 0.85), rainPaint);
    }
  }

  void _drawThunderstorm(Canvas canvas, double size, bool isNight) {
    if (isNight) {
      final starPaint = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.3)..strokeWidth = size * 0.006..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(size * 0.85 - size * 0.01, size * 0.15), Offset(size * 0.85 + size * 0.01, size * 0.15), starPaint);
      canvas.drawLine(Offset(size * 0.85, size * 0.15 - size * 0.01), Offset(size * 0.85, size * 0.15 + size * 0.01), starPaint);
    }
    
    final cloudColor1 = isNight ? const Color(0xFF1A202C) : const Color(0xFF424242);
    final cloudColor2 = isNight ? const Color(0xFF000000) : const Color(0xFF212121);
    _drawCloud(canvas, size, Offset(size * 0.5, size * 0.4), size * 0.35, color1: cloudColor1, color2: cloudColor2);
    final lightningPath = Path()
      ..moveTo(size * 0.45, size * 0.6)
      ..lineTo(size * 0.55, size * 0.7)
      ..lineTo(size * 0.5, size * 0.7)
      ..lineTo(size * 0.6, size * 0.85);
    canvas.drawPath(lightningPath, Paint()..color = const Color(0xFFFFEB3B)..strokeWidth = size * 0.025..strokeCap = StrokeCap.round);
  }

  void _drawSnowy(Canvas canvas, double size, bool isNight) {
    if (isNight) _drawStars(canvas, size);
    final cloudColor1 = isNight ? const Color(0xFF4A5568) : const Color(0xFFECEFF1);
    final cloudColor2 = isNight ? const Color(0xFF2D3748) : const Color(0xFFCFD8DC);
    
    _drawCloud(canvas, size, Offset(size * 0.5, size * 0.4), size * 0.35, color1: cloudColor1, color2: cloudColor2);
    final snowPaint = Paint()..color = Colors.white..strokeWidth = size * 0.015..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final x = size * (0.2 + (i % 4) * 0.2);
      final y = size * (0.65 + (i ~/ 4) * 0.15);
      final snowSize = size * 0.03;
      canvas.drawLine(Offset(x - snowSize, y), Offset(x + snowSize, y), snowPaint);
      canvas.drawLine(Offset(x, y - snowSize), Offset(x, y + snowSize), snowPaint);
    }
  }

  void _drawFoggy(Canvas canvas, double size, bool isNight) {
    if (isNight) {
      final starPaint = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.4)..strokeWidth = size * 0.008..strokeCap = StrokeCap.round;
      final starsData = [[size * 0.2, size * 0.2, size * 0.012], [size * 0.8, size * 0.3, size * 0.015], [size * 0.1, size * 0.7, size * 0.01]];
      for (var star in starsData) {
        final x = star[0]; final y = star[1]; final starSize = star[2];
        canvas.drawLine(Offset(x - starSize, y), Offset(x + starSize, y), starPaint);
        canvas.drawLine(Offset(x, y - starSize), Offset(x, y + starSize), starPaint);
      }
    }
    
    final fogColor = isNight ? const Color(0xFF718096) : const Color(0xFFB0BEC5);
    final fogPaint = Paint()..color = fogColor..strokeWidth = size * 0.04..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final y = size * (0.3 + i * 0.1);
      canvas.drawLine(Offset(size * 0.15, y), Offset(size * 0.75, y), fogPaint);
    }
  }

  void _drawCloud(Canvas canvas, double size, Offset center, double cloudSize, {Color color1 = const Color(0xFFFFFFFF), Color color2 = const Color(0xFFE0E0E0)}) {
    final cloudPaint = Paint()..shader = LinearGradient(colors: [color1, color2]).createShader(Rect.fromCenter(center: center, width: cloudSize * 2, height: cloudSize));
    final circles = [
      Offset(center.dx - cloudSize * 0.3, center.dy),
      Offset(center.dx, center.dy - cloudSize * 0.2),
      Offset(center.dx + cloudSize * 0.3, center.dy),
      Offset(center.dx - cloudSize * 0.1, center.dy + cloudSize * 0.1),
      Offset(center.dx + cloudSize * 0.1, center.dy + cloudSize * 0.1)
    ];
    final radii = [cloudSize * 0.25, cloudSize * 0.3, cloudSize * 0.25, cloudSize * 0.2, cloudSize * 0.2];
    for (int i = 0; i < circles.length; i++) {
      canvas.drawCircle(circles[i], radii[i], cloudPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}