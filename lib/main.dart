import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/weather_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Meteo',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: Scaffold(
              resizeToAvoidBottomInset: true,
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
                    final isLandscape = constraints.maxWidth > constraints.maxHeight;
                    final isKeyboardOpen = keyboardHeight > 0;
                    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
                    
                    
                    return isKeyboardOpen
                        ? SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: SizedBox(
                              height: isLandscape && isAndroid 
                                  ? math.max(constraints.maxHeight - keyboardHeight, 400)
                                  : constraints.maxHeight - keyboardHeight,
                              child: const HomeScreen(),
                            ),
                          )
                        : const HomeScreen();
                  },
                ),
              ),
            ),
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              scrollbars: kIsWeb || defaultTargetPlatform == TargetPlatform.windows || 
                          defaultTargetPlatform == TargetPlatform.linux || 
                          defaultTargetPlatform == TargetPlatform.macOS,
              overscroll: false,
              physics: defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS
                  ? const BouncingScrollPhysics()
                  : const ClampingScrollPhysics(),
            ),
          );
        },
      ),
    );
  }
}