import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  
  WeatherData? _currentWeather;
  ForecastData? _currentForecast;
  List<String> _favoriteCities = [];
  bool _isLoading = false;
  String? _error;

  WeatherData? get currentWeather => _currentWeather;
  ForecastData? get currentForecast => _currentForecast;
  List<String> get favoriteCities => _favoriteCities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  WeatherProvider() {
    _loadFavorites();
  }

  
  bool isFavorite(String cityName) {
    return _favoriteCities.contains(cityName.toLowerCase());
  }

  
  Future<void> toggleFavorite(String cityName) async {
    final lowerCityName = cityName.toLowerCase();
    if (_favoriteCities.contains(lowerCityName)) {
      _favoriteCities.remove(lowerCityName);
    } else {
      _favoriteCities.add(lowerCityName);
    }
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> fetchWeather(String city) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      
      final completeData = await _weatherService.fetchCompleteWeather(city);
      _currentWeather = completeData['current'];
      _currentForecast = completeData['forecast'];
      _error = null;
    } catch (e) {
      _error = e.toString();
      _currentWeather = null;
      _currentForecast = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favoriteCities = prefs.getStringList('favorite_cities') ?? [];
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_cities', _favoriteCities);
  }

  
  Future<List<WeatherData>> getFavoriteWeatherData() async {
    List<WeatherData> favoriteWeatherList = [];
    for (String cityName in _favoriteCities) {
      try {
        final weather = await _weatherService.fetchWeather(cityName);
        favoriteWeatherList.add(weather);
      } catch (e) {
        
        continue;
      }
    }
    return favoriteWeatherList;
  }

  Future<void> clearFavorites() async {
    _favoriteCities.clear();
    await _saveFavorites();
    notifyListeners();
  }

  
  void clearCurrentWeather() {
    _currentWeather = null;
    _currentForecast = null;
    _error = null;
    notifyListeners();
  }
}