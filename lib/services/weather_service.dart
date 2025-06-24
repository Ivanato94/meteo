import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const String _apiKey = '9c1b7852a1b4cb90f526862768ca24e9';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<WeatherData> fetchWeather(String city) async {
    final url = '$_baseUrl/weather?q=$city&appid=$_apiKey&units=metric&lang=it';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Città "$city" non trovata. Controlla l\'ortografia');
      } else if (response.statusCode == 401) {
        throw Exception('Errore di autenticazione API');
      } else if (response.statusCode >= 500) {
        throw Exception('Servizio temporaneamente non disponibile');
      } else {
        throw Exception('Errore nel caricamento dei dati meteo (${response.statusCode})');
      }
    } on SocketException {
      throw Exception('Nessuna connessione internet. Controlla la tua connessione');
    } on FormatException {
      throw Exception('Errore nella risposta del server');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow; 
      }
      throw Exception('Errore di connessione: controlla la tua rete');
    }
  }

  Future<ForecastData> fetchForecast(String city) async {
    final url = '$_baseUrl/forecast?q=$city&appid=$_apiKey&units=metric&lang=it';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ForecastData.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Previsioni non disponibili per "$city"');
      } else if (response.statusCode == 401) {
        throw Exception('Errore di autenticazione per le previsioni');
      } else if (response.statusCode >= 500) {
        throw Exception('Servizio previsioni temporaneamente non disponibile');
      } else {
        throw Exception('Errore nel caricamento delle previsioni (${response.statusCode})');
      }
    } on SocketException {
      throw Exception('Nessuna connessione per le previsioni');
    } on FormatException {
      throw Exception('Errore nella risposta delle previsioni');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Errore di connessione previsioni');
    }
  }

  
  Future<Map<String, dynamic>> fetchCompleteWeather(String city) async {
    try {
      final currentWeather = await fetchWeather(city);
      final forecast = await fetchForecast(city);
      
      return {
        'current': currentWeather,
        'forecast': forecast,
      };
    } catch (e) {
      
      rethrow;
    }
  }
}