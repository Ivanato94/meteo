import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/search_overlay.dart';
import '../widgets/app_drawer.dart';
import '../widgets/weather_world_icon.dart';
import '../models/weather_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showSearch = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: Consumer<WeatherProvider>(
          builder: (context, weatherProvider, child) {
            return weatherProvider.currentWeather != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back), 
                    onPressed: () => weatherProvider.clearCurrentWeather()
                  )
                : const SizedBox.shrink();
          },
        ),
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          Consumer<WeatherProvider>(
            builder: (context, provider, _) {
              if (provider.error != null && provider.currentWeather == null) return _buildWelcomeView();
              return provider.currentWeather != null 
                ? _buildWeatherView(provider.currentWeather!, provider.currentForecast)
                : _buildWelcomeView();
            },
          ),
          if (_showSearch) SearchOverlay(
            onClose: () => setState(() => _showSearch = false),
            onSearch: (city) => _handleSearch(city),
          ),
        ],
      ),
      floatingActionButton: _buildConditionalFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _handleSearch(String city) async {
    setState(() => _showSearch = false);
    
    if (!mounted) return;
    
    final weatherProvider = context.read<WeatherProvider>();
    await weatherProvider.fetchWeather(city);
    
    if (!mounted) return;
    
    if (weatherProvider.error != null) {
      _showErrorToast(weatherProvider.error!);
    }
  }

  void _showErrorToast(String errorMessage) {
    String cleanMessage = errorMessage.replaceFirst('Exception: ', '');
    
    IconData errorIcon;
    Color backgroundColor;
    
    if (cleanMessage.contains('non trovata') || cleanMessage.contains('non disponibili')) {
      errorIcon = Icons.location_off;
      backgroundColor = Colors.orange.shade600;
    } else if (cleanMessage.contains('connessione') || cleanMessage.contains('internet')) {
      errorIcon = Icons.wifi_off;
      backgroundColor = Colors.red.shade600;
    } else if (cleanMessage.contains('temporaneamente')) {
      errorIcon = Icons.cloud_off;
      backgroundColor = Colors.blue.shade600;
    } else {
      errorIcon = Icons.warning_amber;
      backgroundColor = Colors.red.shade600;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(errorIcon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(cleanMessage, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              child: Container(padding: const EdgeInsets.all(4), child: const Icon(Icons.close, color: Colors.white70, size: 18)),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
      ),
    );
  }

  Widget _buildConditionalFloatingButton() {
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final isLandscape = mediaQuery.size.width > mediaQuery.size.height;
    
    if (isKeyboardOpen || _showSearch || isLandscape) return const SizedBox.shrink();
    
    return FloatingActionButton.extended(
      onPressed: () => setState(() => _showSearch = true),
      backgroundColor: const Color(0xFF81D4FA), foregroundColor: Colors.white, elevation: 6,
      icon: const Icon(Icons.search, size: 20),
      label: const Text('Cerca città', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildWelcomeView() {
    final isDark = context.watch<ThemeProvider>().isDark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final isWide = constraints.maxWidth > 768;
        return isLandscape ? _buildLandscapeWelcomeView(isDark, constraints, isWide) : _buildPortraitWelcomeView(isDark, constraints, isWide);
      },
    );
  }

  Widget _buildLandscapeWelcomeView(bool isDark, BoxConstraints constraints, bool isWide) {
    final maxHeight = constraints.maxHeight;
    final iconSize = (maxHeight * 0.6).clamp(120, 200).toDouble();
    final titleFontSize = (maxHeight * 0.08).clamp(16, 28).toDouble();
    final subtitleFontSize = (maxHeight * 0.05).clamp(12, 18).toDouble();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(children: [
        Expanded(child: Center(child: WeatherElementsIcon(isDark: isDark, size: iconSize))),
        Expanded(child: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Che tempo fa?', style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color.fromARGB(255, 16, 24, 28)), textAlign: TextAlign.center),
              SizedBox(height: (maxHeight * 0.02).clamp(8, 16)),
              Flexible(child: Text('Scopri le condizioni meteo ovunque tu sia', style: TextStyle(fontSize: subtitleFontSize, color: isDark ? Colors.grey[400] : const Color(0xFF757575)), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
              SizedBox(height: (maxHeight * 0.04).clamp(12, 24)),
              SizedBox(width: 200, height: (maxHeight * 0.12).clamp(35, 45),
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showSearch = true),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF81D4FA), foregroundColor: Colors.white, elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                  icon: Icon(Icons.search, size: (maxHeight * 0.05).clamp(16, 20)),
                  label: Text('Cerca città', style: TextStyle(fontSize: (maxHeight * 0.04).clamp(12, 16), fontWeight: FontWeight.w500)),
                )),
            ],
          ),
        )),
      ]),
    );
  }

  Widget _buildPortraitWelcomeView(bool isDark, BoxConstraints constraints, bool isWide) {
    final iconSize = isWide ? 300.0 : 200.0;
    final titleFontSize = isWide ? 36.0 : 28.0;
    final subtitleFontSize = isWide ? 18.0 : 15.0;
    final topSpacing = isWide ? 60.0 : 40.0;
    final bottomSpacing = isWide ? 80.0 : 60.0;
    final betweenSpacing = isWide ? 20.0 : 12.0;

    return SingleChildScrollView(child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: constraints.maxHeight),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: topSpacing),
        child: Column(
          mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(child: WeatherElementsIcon(isDark: isDark, size: iconSize)),
            SizedBox(height: betweenSpacing),
            Text('Che tempo fa?', style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color.fromARGB(255, 16, 24, 28)), textAlign: TextAlign.center),
            SizedBox(height: betweenSpacing * 0.6),
            Text('Scopri le condizioni meteo ovunque tu sia', style: TextStyle(fontSize: subtitleFontSize, color: isDark ? Colors.grey[400] : const Color(0xFF757575)), textAlign: TextAlign.center),
            SizedBox(height: bottomSpacing),
          ]
        ),
      ),
    ));
  }

  Widget _buildWeatherView(WeatherData weather, ForecastData? forecast) {
    final isWide = MediaQuery.of(context).size.width > 768;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 24 : 16),
      child: Column(children: [
        _buildWeatherCard(weather, isWide),
        SizedBox(height: isWide ? 24 : 16),
        _buildInfoGrid(weather, isWide),
        SizedBox(height: isWide ? 24 : 16),
        if (forecast != null) _buildForecastList(forecast, isWide),
        const SizedBox(height: 120),
      ]),
    );
  }

  Widget _buildWeatherCard(WeatherData weather, bool isWide) {
    return Container(
      padding: EdgeInsets.all(isWide ? 28 : 20),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: _getGradient(weather.icon), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(children: [
        Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(weather.cityName, style: TextStyle(fontSize: isWide ? 32 : 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('${weather.country} • ${weather.daylightInfo}', style: TextStyle(fontSize: isWide ? 14 : 12, color: Colors.white70)),
            ],
          )),
          _buildControls(weather, isWide),
        ]),
        SizedBox(height: isWide ? 24 : 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${weather.temperature.round()}', style: TextStyle(fontSize: isWide ? 68 : 56, fontWeight: FontWeight.w100, color: Colors.white, height: 0.8)),
              Text('°C', style: TextStyle(fontSize: isWide ? 22 : 18, fontWeight: FontWeight.w300, color: Colors.white)),
            ]),
            const SizedBox(height: 4),
            Text(_capitalize(weather.description), style: TextStyle(fontSize: isWide ? 18 : 14, fontWeight: FontWeight.w500, color: Colors.white)),
            Text('Percepita ${weather.feelsLike.round()}° • ${weather.tempMin.round()}°/${weather.tempMax.round()}°', style: TextStyle(fontSize: isWide ? 13 : 11, color: Colors.white70)),
          ]),
          weather.getApiWeatherIcon(size: isWide ? 110 : 80),
        ]),
      ]),
    );
  }

  Widget _buildControls(WeatherData weather, bool isWide) {
    return Consumer<WeatherProvider>(builder: (context, provider, _) {
      final isFav = provider.isFavorite(weather.cityName);
      return Row(mainAxisSize: MainAxisSize.min, children: [
        _controlButton(isWide ? 10.0 : 8.0, provider.isLoading ? null : () => provider.fetchWeather(weather.cityName),
          provider.isLoading ? SizedBox(width: isWide ? 20 : 18, height: isWide ? 20 : 18, child: const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : Icon(Icons.refresh, color: Colors.white, size: isWide ? 20 : 18)),
        const SizedBox(width: 8),
        _controlButton(isWide ? 10.0 : 8.0, () => provider.toggleFavorite(weather.cityName), Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.white, size: isWide ? 20 : 18)),
      ]);
    });
  }

  Widget _controlButton(double padding, VoidCallback? onTap, Widget child) {
    return GestureDetector(onTap: onTap, child: Container(padding: EdgeInsets.all(padding), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: child));
  }

  Widget _buildInfoGrid(WeatherData weather, bool isWide) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      {'icon': Icons.wb_sunny, 'title': 'Alba', 'value': '${weather.sunrise.hour.toString().padLeft(2, '0')}:${weather.sunrise.minute.toString().padLeft(2, '0')}', 'color': Colors.orange},
      {'icon': Icons.nights_stay, 'title': 'Tramonto', 'value': '${weather.sunset.hour.toString().padLeft(2, '0')}:${weather.sunset.minute.toString().padLeft(2, '0')}', 'color': Colors.deepOrange},
      {'icon': Icons.water_drop, 'title': 'Umidità', 'value': '${weather.humidity}%', 'color': Colors.cyan},
      {'icon': Icons.air, 'title': 'Vento', 'value': '${weather.windSpeed.round()}km/h', 'color': Colors.blue},
      {'icon': Icons.visibility, 'title': 'Visibilità', 'value': '${(weather.visibility / 1000).toStringAsFixed(1)}km', 'color': Colors.green},
      {'icon': Icons.compress, 'title': 'Pressione', 'value': '${weather.pressure}hPa', 'color': Colors.purple},
    ];

    return Container(
      padding: EdgeInsets.all(isWide ? 20 : 14),
      decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Column(children: [
        Row(children: items.take(3).map((item) => Expanded(child: _infoCard(item, isWide, isDark))).toList()),
        SizedBox(height: isWide ? 12 : 8),
        Row(children: items.skip(3).map((item) => Expanded(child: _infoCard(item, isWide, isDark))).toList()),
      ]),
    );
  }

  Widget _infoCard(Map<String, dynamic> item, bool isWide, bool isDark) {
    return Container(
      height: isWide ? 80 : 60, padding: EdgeInsets.all(isWide ? 8 : 6), margin: EdgeInsets.symmetric(horizontal: isWide ? 3 : 1),
      decoration: BoxDecoration(color: isDark ? Colors.grey.shade700 : Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.grey.shade600 : Colors.grey.shade300, width: 0.5)),
      child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Icon(item['icon'], color: item['color'], size: isWide ? 20 : 14),
        Text(item['title'], style: TextStyle(fontSize: isWide ? 10 : 8, color: isDark ? Colors.grey[300] : Colors.grey[600], fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(item['value'], style: TextStyle(fontSize: isWide ? 12 : 9, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildForecastList(ForecastData forecast, bool isWide) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(isWide ? 20 : 16),
      decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.calendar_today, color: Colors.blue, size: isWide ? 22 : 18),
          const SizedBox(width: 8),
          Text('Previsioni 5 giorni', style: TextStyle(fontSize: isWide ? 18 : 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ]),
        SizedBox(height: isWide ? 16 : 12),
        ...forecast.forecasts.map((day) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.symmetric(vertical: isWide ? 12 : 8, horizontal: isWide ? 14 : 10),
          decoration: BoxDecoration(color: isDark ? Colors.grey.shade700 : Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            SizedBox(width: isWide ? 55 : 45, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(day.dayName, style: TextStyle(fontSize: isWide ? 14 : 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              Text(day.formattedDate, style: TextStyle(fontSize: isWide ? 11 : 9, color: isDark ? Colors.grey[300] : Colors.grey)),
            ])),
            Container(width: isWide ? 36 : 32, height: isWide ? 36 : 32, margin: const EdgeInsets.symmetric(horizontal: 8), child: _getIcon(day.icon, isWide ? 32 : 28)),
            Expanded(child: Text(_capitalize(day.description), style: TextStyle(fontSize: isWide ? 13 : 11, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text('${day.tempMax.round()}°/${day.tempMin.round()}°', style: TextStyle(fontSize: isWide ? 14 : 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          ]),
        )),
      ]),
    );
  }

  Widget _getIcon(String iconCode, double size) {
    final temp = WeatherData(
      cityName: '', country: '', temperature: 0, tempMin: 0, tempMax: 0, description: '', icon: iconCode, humidity: 0, windSpeed: 0, pressure: 0, feelsLike: 0, timestamp: DateTime.now(), sunrise: DateTime.now(), sunset: DateTime.now(), lat: 0, lon: 0, visibility: 0, clouds: 0, timezoneOffset: 0,
    );
    return temp.getApiWeatherIcon(size: size, forceDay: true);
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

  String _capitalize(String text) => text.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word).join(' ');
}