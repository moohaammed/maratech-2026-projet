import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_colors.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;

  const MapPickerScreen({
    super.key,
    this.initialLocation = const LatLng(33.8869, 9.5375), // Default to Tunisia center
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late MapController _mapController;
  LatLng _currentCenter = const LatLng(33.8869, 9.5375);
  String _address = "Déplacez la carte pour choisir";
  bool _isReverseGeocoding = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentCenter = widget.initialLocation;
  }

  Future<void> _fetchAddress(LatLng position) async {
    setState(() => _isReverseGeocoding = true);
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'MaraTECH-Running-App-Contact-seif.engeering@gmail.com', // Unique and descriptive User-Agent
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _address = data['display_name'] ?? "Adresse inconnue";
        });
      } else if (response.statusCode == 403) {
        setState(() => _address = "Accès Nominatim Bloqué");
      } else {
        setState(() => _address = "Erreur de géocodage (${response.statusCode})");
      }
    } catch (e) {
      setState(() => _address = "Erreur réseau");
    } finally {
      setState(() => _isReverseGeocoding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Sélectionner le lieu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation,
              initialZoom: 13,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _currentCenter = position.center!;
                    _address = "Chargement...";
                  });
                }
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _fetchAddress(_currentCenter);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.maratech.app',
              ),
            ],
          ),
          
          // Center Pointer (The "Marker")
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35), // Offset to point the tip of the icon
              child: Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 45,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
            ),
          ),

          // Address Display & Confirm Button
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A24),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.map_outlined, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Lieu sélectionné', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              _address,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isReverseGeocoding ? null : () {
                        Navigator.pop(context, {
                          'address': _address,
                          'latitude': _currentCenter.latitude,
                          'longitude': _currentCenter.longitude,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isReverseGeocoding 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Confirmer ce lieu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
