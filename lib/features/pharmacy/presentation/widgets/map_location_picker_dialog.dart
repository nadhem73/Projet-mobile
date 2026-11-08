import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:medilink/core/theme/colors.dart';
import 'package:nb_utils/nb_utils.dart';

/// Projection Web Mercator standard (EPSG:3857) pour OpenStreetMap Slippy Tiles.
class OsmTileMath {
  static double lonToTileX(double lon, int zoom) {
    return (lon + 180.0) / 360.0 * (1 << zoom);
  }

  static double latToTileY(double lat, int zoom) {
    final latRad = lat * math.pi / 180.0;
    return (1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * (1 << zoom);
  }

  static double tileXToLon(double x, int zoom) {
    return x / (1 << zoom) * 360.0 - 180.0;
  }

  static double tileYToLat(double y, int zoom) {
    final n = math.pi - 2.0 * math.pi * y / (1 << zoom);
    return 180.0 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  }
}

/// Résultat de la sélection sur la carte
class LocationPickerResult {
  const LocationPickerResult({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final double latitude;
  final double longitude;
  final String? address;
}

/// Dialogue / Écran complet interactif de sélection d'emplacement sur la carte OpenStreetMap.
class MapLocationPickerDialog extends StatefulWidget {
  const MapLocationPickerDialog({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    this.initialAddress,
  });

  final double initialLatitude;
  final double initialLongitude;
  final String? initialAddress;

  static Future<LocationPickerResult?> show(
    BuildContext context, {
    required double initialLatitude,
    required double initialLongitude,
    String? initialAddress,
  }) {
    return Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MapLocationPickerDialog(
          initialLatitude: initialLatitude,
          initialLongitude: initialLongitude,
          initialAddress: initialAddress,
        ),
      ),
    );
  }

  @override
  State<MapLocationPickerDialog> createState() => _MapLocationPickerDialogState();
}

class _MapLocationPickerDialogState extends State<MapLocationPickerDialog> {
  late double _latitude;
  late double _longitude;
  int _zoom = 15;

  late double _centerTileX;
  late double _centerTileY;

  String? _address;
  bool _isLocating = false;
  bool _isGeocoding = false;

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;
  Timer? _reverseGeocodeDebounce;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    _address = widget.initialAddress;

    _updateTileCoordinates();
    _fetchAddressForCoordinates(_latitude, _longitude);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _reverseGeocodeDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _updateTileCoordinates() {
    _centerTileX = OsmTileMath.lonToTileX(_longitude, _zoom);
    _centerTileY = OsmTileMath.latToTileY(_latitude, _zoom);
  }

  void _updateCenterFromTileCoords() {
    _longitude = OsmTileMath.tileXToLon(_centerTileX, _zoom);
    _latitude = OsmTileMath.tileYToLat(_centerTileY, _zoom);
    // Borner les valeurs
    _latitude = _latitude.clamp(-85.0, 85.0);
    _longitude = _longitude.clamp(-180.0, 180.0);

    _debounceReverseGeocode();
  }

  void _debounceReverseGeocode() {
    _reverseGeocodeDebounce?.cancel();
    _reverseGeocodeDebounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        _fetchAddressForCoordinates(_latitude, _longitude);
      }
    });
  }

  Future<void> _fetchAddressForCoordinates(double lat, double lon) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&zoom=18&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'MediLink-Tunisia-App/1.0 (contact: info@medilink.tn)',
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted && data is Map<String, dynamic> && data['display_name'] != null) {
          setState(() {
            _address = data['display_name'] as String;
          });
        }
      }
    } catch (_) {
      // Ignorer les erreurs réseau pour le géocodage inverse
    } finally {
      if (mounted) {
        setState(() => _isGeocoding = false);
      }
    }
  }

  void _zoomIn() {
    if (_zoom < 18) {
      setState(() {
        _zoom++;
        _updateTileCoordinates();
      });
    }
  }

  void _zoomOut() {
    if (_zoom > 7) {
      setState(() {
        _zoom--;
        _updateTileCoordinates();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        toast('Le service de localisation est désactivé');
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          toast('Permission de localisation refusée');
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        toast('Permission de localisation refusée en permanence');
        setState(() => _isLocating = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _zoom = 16;
        _updateTileCoordinates();
      });

      _fetchAddressForCoordinates(_latitude, _longitude);
      toast('Position GPS trouvée !');
    } catch (e) {
      toast('Impossible de récupérer la position GPS');
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&countrycodes=tn',
        );
        final response = await http.get(url, headers: {
          'User-Agent': 'MediLink-Tunisia-App/1.0 (contact: info@medilink.tn)',
        }).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (mounted && data is List) {
            setState(() {
              _searchResults = data.cast<Map<String, dynamic>>();
            });
          }
        }
      } catch (_) {
        // En cas d'erreur réseau
      } finally {
        if (mounted) {
          setState(() => _isSearching = false);
        }
      }
    });
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = double.tryParse(result['lat']?.toString() ?? '');
    final lon = double.tryParse(result['lon']?.toString() ?? '');
    if (lat != null && lon != null) {
      setState(() {
        _latitude = lat;
        _longitude = lon;
        _zoom = 16;
        _updateTileCoordinates();
        _address = result['display_name'] as String?;
        _searchResults = [];
        _searchController.clear();
      });
      hideKeyboard(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? scaffoldDarkColor : white,
      appBar: AppBar(
        title: const Text('Choisir l\'emplacement sur la carte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Ma position GPS',
            icon: _isLocating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: white, strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            onPressed: _isLocating ? null : _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Interactive Map Viewport
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final halfW = w / 2.0;
              final halfH = h / 2.0;

              final totalTiles = 1 << _zoom;
              final minTileX = (_centerTileX - halfW / 256.0).floor() - 1;
              final maxTileX = (_centerTileX + halfW / 256.0).floor() + 1;
              final minTileY = (_centerTileY - halfH / 256.0).floor() - 1;
              final maxTileY = (_centerTileY + halfH / 256.0).floor() + 1;

              final tileWidgets = <Widget>[];

              for (int tx = minTileX; tx <= maxTileX; tx++) {
                final wrappedX = (tx % totalTiles + totalTiles) % totalTiles;
                for (int ty = minTileY; ty <= maxTileY; ty++) {
                  if (ty < 0 || ty >= totalTiles) continue;

                  final left = halfW + (tx - _centerTileX) * 256.0;
                  final top = halfH + (ty - _centerTileY) * 256.0;

                  tileWidgets.add(
                    Positioned(
                      left: left,
                      top: top,
                      width: 256,
                      height: 256,
                      child: CachedNetworkImage(
                        imageUrl: 'https://tile.openstreetmap.org/$_zoom/$wrappedX/$ty.png',
                        httpHeaders: const {
                          'User-Agent': 'MediLink-Tunisia-App/1.0 (contact: info@medilink.tn)',
                        },
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 150),
                        placeholder: (context, url) => Container(
                          color: isDark ? const Color(0xFF222222) : const Color(0xFFE5E5E5),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: isDark ? const Color(0xFF222222) : const Color(0xFFE5E5E5),
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 24, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  );
                }
              }

              return GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _centerTileX -= details.delta.dx / 256.0;
                    _centerTileY -= details.delta.dy / 256.0;
                    _updateCenterFromTileCoords();
                  });
                },
                child: Stack(
                  children: [
                    // Tiles
                    ...tileWidgets,

                    // OSM Attribution overlay
                    Positioned(
                      left: 8,
                      bottom: 140,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '© OpenStreetMap contributors',
                          style: TextStyle(fontSize: 9, color: Colors.black87),
                        ),
                      ),
                    ),

                    // Pin in the exact center of viewport
                    Center(
                      child: Transform.translate(
                        offset: const Offset(0, -22), // Le bout de l'aiguille touche le centre exact
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: mlPrimaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: mlPrimaryColor.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.local_pharmacy, color: Colors.white, size: 22),
                            ),
                            Icon(Icons.arrow_drop_down, color: mlPrimaryColor, size: 24),
                            Container(
                              width: 8,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // 2. Search Bar overlay
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Rechercher une rue, quartier ou ville...',
                      prefixIcon: const Icon(Icons.search, color: mlPrimaryColor),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                      filled: true,
                      fillColor: isDark ? cardBackgroundBlackDark : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: isDark ? cardBackgroundBlackDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        final name = item['display_name'] as String? ?? '';
                        return ListTile(
                          leading: const Icon(Icons.location_on, color: mlPrimaryColor, size: 20),
                          title: Text(
                            name,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSearchResult(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // 3. Zoom Controls (+ and -) and GPS Button
          Positioned(
            right: 16,
            bottom: 145,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  shape: const CircleBorder(),
                  color: isDark ? cardBackgroundBlackDark : Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.add, color: mlPrimaryColor),
                    onPressed: _zoomIn,
                    tooltip: 'Zoom avant',
                  ),
                ),
                8.height,
                Material(
                  elevation: 4,
                  shape: const CircleBorder(),
                  color: isDark ? cardBackgroundBlackDark : Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.remove, color: mlPrimaryColor),
                    onPressed: _zoomOut,
                    tooltip: 'Zoom arrière',
                  ),
                ),
                8.height,
                Material(
                  elevation: 4,
                  shape: const CircleBorder(),
                  color: mlPrimaryColor,
                  child: IconButton(
                    icon: _isLocating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, color: Colors.white),
                    onPressed: _isLocating ? null : _getCurrentLocation,
                    tooltip: 'Ma position GPS',
                  ),
                ),
              ],
            ),
          ),

          // 4. Bottom Information & Confirmation Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? cardBackgroundBlackDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: mlPrimaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.place_rounded, color: mlPrimaryColor, size: 24),
                        ),
                        12.width,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Position sélectionnée',
                                    style: boldTextStyle(size: 14),
                                  ),
                                  if (_isGeocoding) ...[
                                    8.width,
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(strokeWidth: 1.5),
                                    ),
                                  ],
                                ],
                              ),
                              4.height,
                              Text(
                                _address ?? 'Déplacez la carte pour positionner le repère',
                                style: secondaryTextStyle(size: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              4.height,
                              Text(
                                'Latitude: ${_latitude.toStringAsFixed(6)} | Longitude: ${_longitude.toStringAsFixed(6)}',
                                style: primaryTextStyle(size: 11, color: mlPrimaryColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    12.height,
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mlPrimaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text(
                          'Confirmer cette position',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: () {
                          Navigator.pop(
                            context,
                            LocationPickerResult(
                              latitude: _latitude,
                              longitude: _longitude,
                              address: _address,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
