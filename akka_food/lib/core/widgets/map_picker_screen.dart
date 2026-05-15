import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';

/// A full-screen map picker using OpenStreetMap (free, no API key needed).
///
/// Centered on Bamako, Mali by default. The user can tap anywhere on the map
/// or drag the marker to select a location. Returns a `Map<String, double>`
/// with 'lat' and 'lng' keys.
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  /// Initial latitude (defaults to Bamako center).
  final double? initialLat;

  /// Initial longitude (defaults to Bamako center).
  final double? initialLng;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _selectedPosition;
  late final MapController _mapController;

  // Default: Bamako, Mali
  static const _defaultLat = 12.6392;
  static const _defaultLng = -8.0029;

  @override
  void initState() {
    super.initState();
    _selectedPosition = LatLng(
      widget.initialLat ?? _defaultLat,
      widget.initialLng ?? _defaultLng,
    );
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir un emplacement'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop({
                'lat': _selectedPosition.latitude,
                'lng': _selectedPosition.longitude,
              });
            },
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Confirmer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: 14.0,
              onTap: (tapPosition, latLng) {
                setState(() {
                  _selectedPosition = latLng;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.akkafood.akka_food',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPosition,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Coordinates display at bottom
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedPosition.latitude.toStringAsFixed(5)}, '
                        '${_selectedPosition.longitude.toStringAsFixed(5)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    // Center on Bamako button
                    IconButton(
                      icon: const Icon(Icons.my_location),
                      tooltip: 'Centrer sur Bamako',
                      onPressed: () {
                        const bamako = LatLng(_defaultLat, _defaultLng);
                        _mapController.move(bamako, 14.0);
                        setState(() => _selectedPosition = bamako);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Instruction text at top
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: Card(
              color: AppColors.primaryBlue.withValues(alpha: 0.9),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'Appuyez sur la carte pour placer le marqueur',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
