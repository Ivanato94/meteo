import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class SearchOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final Function(String) onSearch;

  const SearchOverlay({super.key, required this.onClose, required this.onSearch});

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  static const String _apiKey = '9c1b7852a1b4cb90f526862768ca24e9';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleSearch(String cityName) {
    if (cityName.trim().isNotEmpty) widget.onSearch(cityName.trim());
  }

  void _handleSuggestionTap(String cityName, String country, String? state) {
    String fullCityName;
    if (state != null && state.isNotEmpty) {
      fullCityName = '$cityName,$state,$country';
    } else {
      fullCityName = '$cityName,$country';
    }
    widget.onSearch(fullCityName);
  }

  Future<void> _searchCities(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = 'http://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$_apiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _suggestions = data.map((city) => {
            'name': city['name'], 
            'country': city['country'], 
            'state': city['state'] ?? ''
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () => _searchCities(value));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return LayoutBuilder(builder: (context, constraints) {
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      final isLandscape = constraints.maxWidth > constraints.maxHeight;

      return Material(
        color: Colors.black54,
        child: GestureDetector(
          onTap: widget.onClose,
          child: GestureDetector(
            onTap: () {},
            child: Center(child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(isLandscape ? 10 : 20, isLandscape ? 10 : 20, isLandscape ? 10 : 20, (isLandscape ? 10 : 20) + keyboardHeight),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isLandscape ? 500 : 400, minHeight: 0),
                child: Container(
                  decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))]),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: EdgeInsets.all(isLandscape ? 12 : 16),
                      decoration: const BoxDecoration(color: Color(0xFF81D4FA), borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
                      child: Row(children: [
                        Icon(Icons.search, color: Colors.white, size: isLandscape ? 20 : 24),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Cerca Città', style: TextStyle(fontSize: isLandscape ? 16 : 18, fontWeight: FontWeight.bold, color: Colors.white))),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                            child: Icon(Icons.close, color: Colors.white, size: isLandscape ? 18 : 20),
                          ),
                        ),
                      ]),
                    ),
                    Padding(
                      padding: EdgeInsets.all(isLandscape ? 12 : 16),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        TextField(
                          controller: _searchController, focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: 'Nome della città...',
                            prefixIcon: _isLoading ? Container(padding: const EdgeInsets.all(12), child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) : const Icon(Icons.location_city),
                            suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () {_searchController.clear(); setState(() => _suggestions = []);}) : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF81D4FA), width: 2)),
                            contentPadding: EdgeInsets.symmetric(vertical: isLandscape ? 10 : 16, horizontal: 12),
                          ),
                          onChanged: _onSearchChanged, onSubmitted: _handleSearch,
                        ),
                        SizedBox(height: isLandscape ? 8 : 16),
                        if (_suggestions.isNotEmpty) ...[
                          Container(
                            constraints: BoxConstraints(maxHeight: isLandscape ? 120 : 200),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                            child: ListView.separated(
                              shrinkWrap: true, physics: const ClampingScrollPhysics(), itemCount: _suggestions.length,
                              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                              itemBuilder: (context, index) {
                                final city = _suggestions[index];
                                final cityName = city['name'];
                                final country = city['country'];
                                final state = city['state'];
                                return ListTile(
                                  dense: isLandscape,
                                  leading: Icon(Icons.location_on, color: const Color(0xFF81D4FA), size: isLandscape ? 18 : 20),
                                  title: Text(cityName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: isLandscape ? 13 : 14)),
                                  subtitle: Text(state.isNotEmpty ? '$state, $country' : country, style: TextStyle(fontSize: isLandscape ? 11 : 12, color: Colors.grey.shade600)),
                                  onTap: () => _handleSuggestionTap(cityName, country, state),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: isLandscape ? 8 : 16),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _searchController.text.trim().isEmpty ? null : () => _handleSearch(_searchController.text),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF81D4FA), foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: isLandscape ? 12 : 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), disabledBackgroundColor: Colors.grey.shade300),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.search, size: isLandscape ? 18 : 20),
                              const SizedBox(width: 8),
                              Text('Cerca', style: TextStyle(fontSize: isLandscape ? 14 : 16, fontWeight: FontWeight.w600, color: _searchController.text.trim().isEmpty ? Colors.grey.shade600 : Colors.white)),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ),
            )),
          ),
        ),
      );
    });
  }
}