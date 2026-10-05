import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';

class WarrantyLbsScreen extends StatefulWidget {
  const WarrantyLbsScreen({super.key});

  @override
  State<WarrantyLbsScreen> createState() => _WarrantyLbsScreenState();
}

class _WarrantyLbsScreenState extends State<WarrantyLbsScreen> {
  Position? _currentPosition;
  bool _loadingLocation = false;
  String _locationStatus = 'Tap to get current GPS location';

  // Demo authorized service centers in Yogyakarta & Indonesia
  final List<Map<String, dynamic>> _serviceCenters = [
    {
      'name': 'Apple Authorized Service Provider (iBox Ambarrukmo Plaza)',
      'brand': 'Apple',
      'address': 'Plaza Ambarrukmo Lt. 2, Jl. Laksda Adisucipto, Yogyakarta',
      'lat': -7.7828,
      'lng': 110.4011,
      'status': 'Open · Warranty Accepted',
    },
    {
      'name': 'Samsung Customer Service Center Gejayan',
      'brand': 'Samsung',
      'address': 'Jl. Affandi No. 34, Sleman, DI Yogyakarta',
      'lat': -7.7667,
      'lng': 110.3892,
      'status': 'Open · Express Repair',
    },
    {
      'name': 'Asus Service Center Exclusive Jogja',
      'brand': 'Asus',
      'address': 'Jl. Ring Road Utara No. 10, Depok, Sleman',
      'lat': -7.7583,
      'lng': 110.4045,
      'status': 'Open · Official Hardware Support',
    },
    {
      'name': 'Sony Authorized Service Station',
      'brand': 'Sony',
      'address': 'Jl. C. Simanjuntak No. 42, Terban, Yogyakarta',
      'lat': -7.7791,
      'lng': 110.3732,
      'status': 'Open · Audio & Camera Specialist',
    },
  ];

  Future<void> _determinePosition() async {
    setState(() {
      _loadingLocation = true;
      _locationStatus = 'Acquiring GPS fix...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = 'Location services are disabled.';
          _loadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'Location permissions denied.';
            _loadingLocation = false;
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _locationStatus = 'GPS Active: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _loadingLocation = false;
      });
    } catch (e) {
      // Fallback coordinates for Yogyakarta (UPN Veteran area)
      setState(() {
        _currentPosition = Position(
          latitude: -7.7608,
          longitude: 110.4083,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 100,
          altitudeAccuracy: 1,
          heading: 0,
          headingAccuracy: 1,
          speed: 0,
          speedAccuracy: 1,
        );
        _locationStatus = 'Simulated GPS: -7.7608, 110.4083 (Sleman, DIY)';
        _loadingLocation = false;
      });
    }
  }

  double _calculateDistance(double targetLat, double targetLng) {
    if (_currentPosition == null) return 0.0;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      targetLat,
      targetLng,
    ) / 1000.0; // In kilometers
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VaultColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. BRAND HEADER (Matching HomeVaultScreen)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.brightness_low_rounded,
                        color: VaultColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'VAULT',
                        style: VaultTypography.sans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: VaultColors.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '·  LBS CARE',
                        style: VaultTypography.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                          color: VaultColors.ink2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VaultColors.card,
                      border: Border.all(color: VaultColors.hairline, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'A',
                      style: VaultTypography.sans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: VaultColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'LOCATION-BASED SERVICES (LBS)',
                style: VaultTypography.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: VaultColors.accent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Warranty & Service Centers',
                style: VaultTypography.sans(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: VaultColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Locate official authorized repair centers near you to claim warranties for your logged gear.',
                style: VaultTypography.cardDescription,
              ),
              const SizedBox(height: 18),

              // GPS Status Card & Fetch Button
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: VaultColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: VaultColors.hairline),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location_rounded, color: VaultColors.accent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current Location', style: VaultTypography.sans(fontSize: 11, color: VaultColors.ink2)),
                          const SizedBox(height: 2),
                          Text(_locationStatus, style: VaultTypography.mono(fontSize: 11.5, color: VaultColors.ink)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _loadingLocation ? null : _determinePosition,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VaultColors.ink,
                        foregroundColor: VaultColors.background,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _loadingLocation
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: VaultColors.background))
                          : Text('Locate', style: VaultTypography.sans(fontSize: 12, fontWeight: FontWeight.w600, color: VaultColors.background)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Service Centers List
              Text('Nearest Authorized Partners', style: VaultTypography.sectionTitle),
              const SizedBox(height: 12),
              ..._serviceCenters.map((center) {
                final dist = _calculateDistance(center['lat'] as double, center['lng'] as double);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: VaultColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: VaultColors.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: VaultColors.badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              center['brand'] as String,
                              style: VaultTypography.mono(fontSize: 10, fontWeight: FontWeight.w600, color: VaultColors.accent),
                            ),
                          ),
                          if (_currentPosition != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: VaultColors.posBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${dist.toStringAsFixed(1)} km away',
                                style: VaultTypography.mono(fontSize: 10, fontWeight: FontWeight.w600, color: VaultColors.pos),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(center['name'] as String, style: VaultTypography.sans(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(center['address'] as String, style: VaultTypography.sans(fontSize: 11.5, color: VaultColors.ink2)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.verified_outlined, size: 14, color: VaultColors.pos),
                          const SizedBox(width: 6),
                          Text(center['status'] as String, style: VaultTypography.sans(fontSize: 11, color: VaultColors.pos)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
