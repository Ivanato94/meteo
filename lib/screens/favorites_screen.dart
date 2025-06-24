import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../models/weather_model.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final isWideScreen = mediaQuery.size.width > 768;
    
    return Scaffold(
      appBar: _buildAppBar(isLandscape),
      body: Consumer<WeatherProvider>(
        builder: (context, provider, _) {
          if (provider.favoriteCities.isEmpty) {
            return _buildEmptyState(context, isLandscape, isWideScreen);
          }
          return _buildFavoritesList(context, provider, isLandscape, isWideScreen);
        },
      ),
    );
  }

  AppBar _buildAppBar(bool isLandscape) {
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.favorite, color: Colors.red, size: isLandscape ? 20 : 24),
          const SizedBox(width: 8),
          Text('Città Preferite', style: TextStyle(fontSize: isLandscape ? 18 : 20)),
        ],
      ),
      actions: [
        Consumer<WeatherProvider>(
          builder: (context, provider, _) {
            return provider.favoriteCities.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.delete_sweep, size: isLandscape ? 20 : 24),
                    onPressed: () => _showClearAllDialog(context, provider),
                  )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext ctx, bool isLandscape, bool isWideScreen) {
    final sizes = _getEmptyStateSizes(isLandscape, isWideScreen);
    
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isLandscape ? 20 : (isWideScreen ? 40 : 20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: sizes['icon'], color: Colors.grey.withValues(alpha: 0.5)),
            SizedBox(height: isLandscape ? 16 : (isWideScreen ? 24 : 16)),
            Text('Nessuna città preferita', style: TextStyle(fontSize: sizes['title'], fontWeight: FontWeight.bold, color: Colors.grey[600])),
            SizedBox(height: isLandscape ? 8 : (isWideScreen ? 16 : 12)),
            Text('Cerca una città e tocca il cuore\nper aggiungerla ai preferiti', textAlign: TextAlign.center, style: TextStyle(fontSize: sizes['subtitle'], color: Colors.grey[500])),
            SizedBox(height: isLandscape ? 20 : (isWideScreen ? 32 : 24)),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(ctx).pop(),
              icon: Icon(Icons.search, size: isLandscape ? 18 : 20),
              label: Text('Cerca Città', style: TextStyle(fontSize: isLandscape ? 14 : 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF81D4FA),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isLandscape ? 16 : (isWideScreen ? 24 : 20),
                  vertical: isLandscape ? 8 : (isWideScreen ? 16 : 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(BuildContext ctx, WeatherProvider provider, bool isLandscape, bool isWideScreen) {
    return FutureBuilder<List<WeatherData>>(
      future: provider.getFavoriteWeatherData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildErrorState(isLandscape, isWideScreen);
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(isLandscape ? 8 : (isWideScreen ? 16 : 12)),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return _buildWeatherCard(ctx, snapshot.data![index], provider, isLandscape, isWideScreen);
          },
        );
      },
    );
  }

  Widget _buildErrorState(bool isLandscape, bool isWideScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: isLandscape ? 40 : (isWideScreen ? 64 : 48), color: Colors.red.withValues(alpha: 0.7)),
          SizedBox(height: isLandscape ? 8 : (isWideScreen ? 16 : 12)),
          Text('Errore nel caricamento', style: TextStyle(fontSize: isLandscape ? 14 : (isWideScreen ? 18 : 16), color: Colors.red.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(BuildContext ctx, WeatherData weather, WeatherProvider provider, bool isLandscape, bool isWideScreen) {
    final sizes = _getCardSizes(isLandscape, isWideScreen);
    
    return Card(
      margin: EdgeInsets.only(bottom: sizes['margin']!),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(ctx).pop();
          provider.fetchWeather(weather.cityName);
        },
        child: Container(
          padding: EdgeInsets.all(sizes['padding']!),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _getGradient(weather.icon),
          ),
          child: isLandscape 
            ? _buildLandscapeLayout(weather, provider, ctx, sizes)
            : _buildPortraitLayout(weather, provider, ctx, sizes),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(WeatherData weather, WeatherProvider provider, BuildContext ctx, Map<String, double> sizes) {
    return Row(
      children: [
        weather.getApiWeatherIcon(size: sizes['icon']!),
        SizedBox(width: sizes['icon']! > 60 ? 20 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(weather.cityName, style: TextStyle(fontSize: sizes['cityName'], fontWeight: FontWeight.bold, color: Colors.white)),
              Text(weather.country, style: TextStyle(fontSize: sizes['country'], color: Colors.white70)),
              SizedBox(height: sizes['icon']! > 60 ? 8 : 6),
              Row(
                children: [
                  Text('${weather.temperature.round()}°C', style: TextStyle(fontSize: sizes['temperature'], fontWeight: FontWeight.w300, color: Colors.white)),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_capitalizeString(weather.description), style: TextStyle(fontSize: sizes['description'], color: Colors.white)),
                      Text('${weather.tempMin.round()}° / ${weather.tempMax.round()}°', style: TextStyle(fontSize: sizes['minMax'], color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildDeleteButton(ctx, weather.cityName, provider, sizes['icon']! > 60),
      ],
    );
  }

  Widget _buildLandscapeLayout(WeatherData weather, WeatherProvider provider, BuildContext ctx, Map<String, double> sizes) {
    return Row(
      children: [
        weather.getApiWeatherIcon(size: sizes['icon']!),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(weather.cityName, style: TextStyle(fontSize: sizes['cityName'], fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(weather.country, style: TextStyle(fontSize: sizes['country'], color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${weather.temperature.round()}°C', style: TextStyle(fontSize: sizes['temperature'], fontWeight: FontWeight.w300, color: Colors.white)),
              Text(_capitalizeString(weather.description), style: TextStyle(fontSize: sizes['description'], color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
              Text('${weather.tempMin.round()}° / ${weather.tempMax.round()}°', style: TextStyle(fontSize: sizes['minMax'], color: Colors.white70)),
            ],
          ),
        ),
        _buildDeleteButton(ctx, weather.cityName, provider, false),
      ],
    );
  }

  Widget _buildDeleteButton(BuildContext ctx, String cityName, WeatherProvider provider, bool isLarge) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
        child: Icon(Icons.delete, color: Colors.white, size: isLarge ? 20 : 16),
      ),
      onPressed: () => _removeFromFavorites(ctx, cityName, provider),
    );
  }

  void _removeFromFavorites(BuildContext ctx, String cityName, WeatherProvider provider) {
    provider.toggleFavorite(cityName);
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('$cityName rimossa dai preferiti'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Annulla',
          textColor: Colors.white,
          onPressed: () => provider.toggleFavorite(cityName),
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext ctx, WeatherProvider provider) {
    showDialog(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 8), Text('Conferma')]),
        content: const Text('Vuoi rimuovere TUTTE le città dai preferiti?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annulla')),
          TextButton(
            onPressed: () {
              provider.clearFavorites();
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Tutti i preferiti sono stati cancellati!'), backgroundColor: Colors.red, duration: Duration(seconds: 2)),
              );
            },
            child: const Text('Cancella Tutti', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  
  Map<String, double> _getEmptyStateSizes(bool isLandscape, bool isWideScreen) {
    return {
      'icon': isLandscape ? (isWideScreen ? 80 : 60) : (isWideScreen ? 120 : 80),
      'title': isLandscape ? (isWideScreen ? 20 : 18) : (isWideScreen ? 24 : 20),
      'subtitle': isLandscape ? (isWideScreen ? 14 : 12) : (isWideScreen ? 16 : 14),
    };
  }

  Map<String, double> _getCardSizes(bool isLandscape, bool isWideScreen) {
    return {
      'margin': isLandscape ? 8.0 : (isWideScreen ? 16.0 : 12.0),
      'padding': isLandscape ? 12.0 : (isWideScreen ? 20.0 : 16.0),
      'icon': isLandscape ? 50.0 : (isWideScreen ? 70.0 : 60.0),
      'cityName': isLandscape ? 16.0 : (isWideScreen ? 22.0 : 18.0),
      'country': isLandscape ? 10.0 : (isWideScreen ? 14.0 : 12.0),
      'temperature': isLandscape ? 24.0 : (isWideScreen ? 32.0 : 28.0),
      'description': isLandscape ? 11.0 : (isWideScreen ? 14.0 : 12.0),
      'minMax': isLandscape ? 9.0 : (isWideScreen ? 12.0 : 10.0),
    };
  }

  LinearGradient _getGradient(String icon) {
    switch (icon.substring(0, 2)) {
      case '01': return const LinearGradient(colors: [Color(0xFFFFE082), Color(0xFFFF8A65), Color(0xFFFF7043)]);
      case '02': return const LinearGradient(colors: [Color(0xFF64B5F6), Color(0xFF42A5F5), Color(0xFF2196F3)]);
      case '03': case '04': return const LinearGradient(colors: [Color(0xFF78909C), Color(0xFF607D8B), Color(0xFF546E7A)]);
      case '09': case '10': return const LinearGradient(colors: [Color(0xFF5C6BC0), Color(0xFF3F51B5), Color(0xFF303F9F)]);
      case '11': return const LinearGradient(colors: [Color(0xFF424242), Color(0xFF212121), Color(0xFF000000)]);
      case '13': return const LinearGradient(colors: [Color(0xFFE1F5FE), Color(0xFFB3E5FC), Color(0xFF81D4FA)]);
      case '50': return const LinearGradient(colors: [Color(0xFFCFD8DC), Color(0xFFB0BEC5), Color(0xFF90A4AE)]);
      default: return const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF4CAF50), Color(0xFF388E3C)]);
    }
  }

  String _capitalizeString(String text) => text.split(' ')
      .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word)
      .join(' ');
}