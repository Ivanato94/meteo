import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/weather_provider.dart';
import '../screens/favorites_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;
    final isDesktop = screenWidth > 768;
    
    
    final drawerWidth = isWideScreen ? 320.0 : (isDesktop ? 280.0 : 250.0);
    
    
    final headerFontSize = isWideScreen ? 32.0 : (isDesktop ? 28.0 : 26.0);
    final listTileFontSize = isWideScreen ? 18.0 : (isDesktop ? 16.0 : 15.0);
    final iconSize = isWideScreen ? 26.0 : (isDesktop ? 24.0 : 22.0);
    
    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF81D4FA), Color(0xFF29B6F6)])
              ),
              child: Text(
                'Meteo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: headerFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            
            Consumer<WeatherProvider>(
              builder: (context, provider, _) {
                final count = provider.favoriteCities.length;
                return ListTile(
                  leading: Icon(Icons.favorite, size: iconSize),
                  title: Text('Città Preferite', style: TextStyle(fontSize: listTileFontSize)),
                  subtitle: Text('$count preferit${count == 1 ? 'a' : 'e'}'),
                  onTap: () {
                    Navigator.pop(context); 
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoritesScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            
            
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return ListTile(
                  leading: Icon(
                    themeProvider.isDark ? Icons.light_mode : Icons.dark_mode,
                    size: iconSize,
                  ),
                  title: Text('Cambia Tema', style: TextStyle(fontSize: listTileFontSize)),
                  onTap: () {
                    themeProvider.toggleTheme();
                    Navigator.pop(context);
                  },
                );
              },
            ),
            
            const Divider(),
            
            
            ListTile(
              leading: Icon(Icons.info, size: iconSize),
              title: Text('Info', style: TextStyle(fontSize: listTileFontSize)),
              onTap: () {
                Navigator.pop(context);
                _showSimpleInfoDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSimpleInfoDialog(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 1200;
    final isDesktop = screenSize.width > 768;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wb_sunny, color: Colors.orange),
            SizedBox(width: 8),
            Text('Meteo App'),
          ],
        ),
        content: SizedBox(
          width: isWideScreen ? 400 : (isDesktop ? 350 : 300),
          child: Text(
            'App Meteo moderna e responsive\n\n'
            '✨ Funzionalità:\n'
            '• Ricerca meteo mondiale\n'
            '• Previsioni 5 giorni\n'
            '• Città preferite\n'
            '• Tema chiaro/scuro\n'
            '• Design responsive\n'
            '• Navigazione multi-screen\n\n'
            '📍 Dati da OpenWeatherMap\n'
            '🚀 Sviluppata con Flutter\n\n'
            'v1.0.0',
            style: TextStyle(
              fontSize: isWideScreen ? 16 : (isDesktop ? 15 : 14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }
}