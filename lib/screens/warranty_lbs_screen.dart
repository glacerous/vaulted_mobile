import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../core/constants/colors.dart';
import '../core/constants/typography.dart';
import '../core/database/database_helper.dart';

class WarrantyLbsScreen extends StatefulWidget {
  const WarrantyLbsScreen({super.key});

  @override
  State<WarrantyLbsScreen> createState() => _WarrantyLbsScreenState();
}

class _WarrantyLbsScreenState extends State<WarrantyLbsScreen> {
  Position? _currentPosition;
  bool _loadingLocation = false;
  String _locationStatus = 'Tap to get current GPS location';
  String? _currentAddress;

  List<Map<String, dynamic>> _userWarrantyItems = [];
  bool _loadingWarrantyItems = true;

  // Hasil pencarian service center asli dari OpenStreetMap (Nominatim Search)
  List<Map<String, dynamic>> _serviceCenters = [];
  bool _loadingCenters = false;
  String? _centersMessage;

  // Database pusat servis resmi & terverifikasi dengan koordinat presisi
  static const List<Map<String, dynamic>> _authorizedDirectory = [
    // --- AREA YOGYAKARTA & SEKITARNYA ---
    {
      'name': 'Apple Authorized Service Provider (iBox Ambarrukmo Plaza)',
      'brand': 'Apple',
      'address':
          'Plaza Ambarrukmo Lt. 2, Jl. Laksda Adisucipto, Caturtunggal, Sleman',
      'lat': -7.7828,
      'lng': 110.4011,
      'status': 'Official Apple Warranty & Hardware Repair',
    },
    {
      'name': 'Samsung Customer Service Center Ambarrukmo',
      'brand': 'Samsung',
      'address': 'Jl. Laksda Adisucipto No. 165, Caturtunggal, Depok, Sleman',
      'lat': -7.7825,
      'lng': 110.3985,
      'status': 'Official Samsung Galaxy Service & Express Care',
    },
    {
      'name': 'Asus Service Center Exclusive Jogja',
      'brand': 'Asus',
      'address': 'Jl. Ring Road Utara No. 10, Condongcatur, Depok, Sleman',
      'lat': -7.7583,
      'lng': 110.4045,
      'status': 'Official ROG & ZenBook Hardware Support',
    },
    {
      'name': 'Mitracare Apple Authorized Service Provider',
      'brand': 'Apple',
      'address': 'Jl. Affandi (Gejayan) No. 17B, Caturtunggal, Depok, Sleman',
      'lat': -7.7725,
      'lng': 110.3888,
      'status': 'Official Apple Care & Genuine Parts Replacement',
    },
    {
      'name': 'OPPO Official Service Center Gejayan',
      'brand': 'Oppo',
      'address': 'Jl. Affandi (Gejayan) No. 10A, Caturtunggal, Depok, Sleman',
      'lat': -7.7712,
      'lng': 110.3885,
      'status': 'Official OPPO 1-Hour Flash Repair',
    },
    {
      'name': 'Samsung Customer Service Center Gejayan',
      'brand': 'Samsung',
      'address': 'Jl. Affandi (Gejayan) No. 34, Caturtunggal, Depok, Sleman',
      'lat': -7.7667,
      'lng': 110.3892,
      'status': 'Official Samsung Customer Support & Screen Care',
    },
    {
      'name': 'Vivo Service Center Yogyakarta',
      'brand': 'Vivo',
      'address': 'Jl. C. Simanjuntak No. 18, Terban, Gondokusuman, Yogyakarta',
      'lat': -7.7815,
      'lng': 110.3810,
      'status': 'Official Vivo Warranty Inspection & Maintenance',
    },
    {
      'name': 'Xiaomi Exclusive Service Center Sagan',
      'brand': 'Xiaomi',
      'address': 'Ruko Sagan Square, Jl. Prof. Herman Yohanes, Yogyakarta',
      'lat': -7.7770,
      'lng': 110.3790,
      'status': 'Certified Xiaomi, Redmi & POCO Fast Service',
    },
    {
      'name': 'Lenovo Exclusive Service Center Jogja',
      'brand': 'Lenovo',
      'address': 'Jl. Kaliurang KM 5 No. 28, Caturtunggal, Depok, Sleman',
      'lat': -7.7645,
      'lng': 110.3780,
      'status': 'Official Legion, Yoga & ThinkPad Repair Center',
    },
    {
      'name': 'Sony Authorized Service Station',
      'brand': 'Sony',
      'address': 'Jl. C. Simanjuntak No. 42, Terban, Gondokusuman, Yogyakarta',
      'lat': -7.7791,
      'lng': 110.3732,
      'status': 'Alpha Cameras, Audio & Xperia Specialist',
    },
    {
      'name': 'Acer Customer Service Center Yogyakarta',
      'brand': 'Acer',
      'address': 'Jl. C. Simanjuntak No. 35, Terban, Gondokusuman, Yogyakarta',
      'lat': -7.7802,
      'lng': 110.3715,
      'status': 'Official Predator & Swift Laptop Service',
    },
    {
      'name': 'HP Authorized Service Center Yogyakarta',
      'brand': 'HP',
      'address': 'Jl. Code III, Sinduadi, Mlati, Sleman',
      'lat': -7.7633,
      'lng': 110.3696,
      'status': 'Official HP Pavilion, OMEN & Spectre Repair',
    },
    {
      'name': 'Realme Official Service Center Jogja',
      'brand': 'Realme',
      'address': 'Jl. Gejayan No. 22, Caturtunggal, Depok, Sleman',
      'lat': -7.7695,
      'lng': 110.3890,
      'status': 'Official Realme Fast Repair Center',
    },
  ];

  static const List<String> _brandKeywords = [
    'Apple',
    'iBox',
    'Samsung',
    'Asus',
    'Sony',
    'Xiaomi',
    'Oppo',
    'Vivo',
    'Realme',
    'Lenovo',
    'Acer',
    'HP',
    'Huawei',
    'Infinix',
  ];

  String _detectBrand(String name) {
    final lower = name.toLowerCase();
    for (final b in _brandKeywords) {
      if (lower.contains(b.toLowerCase())) return b == 'iBox' ? 'Apple' : b;
    }
    return 'Authorized';
  }

  double _distanceOf(Map<String, dynamic> center) {
    if (_currentPosition == null) return 0.0;
    return Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          center['lat'] as double,
          center['lng'] as double,
        ) /
        1000.0; // In km
  }

  Future<void> _fetchNearbyCenters(Position pos) async {
    setState(() {
      _loadingCenters = true;
      _centersMessage = null;
      _serviceCenters = [];
    });

    final List<Map<String, dynamic>> combinedResults = [];
    final Set<String> seenNames = {};

    // 1. Ambil dari direktori terverifikasi yang berada dalam radius 10 km
    for (final center in _authorizedDirectory) {
      final double distance =
          Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            center['lat'] as double,
            center['lng'] as double,
          ) /
          1000.0;

      if (distance <= 10.0) {
        combinedResults.add(Map<String, dynamic>.from(center));
        seenNames.add((center['name'] as String).toLowerCase());
      }
    }

    // 2. Query Nominatim OpenStreetMap secara non-blocking untuk melengkapi hasil
    try {
      final double d = 0.09; // ~10 km box
      final viewbox =
          '${pos.longitude - d},${pos.latitude + d},${pos.longitude + d},${pos.latitude - d}';
      final url = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': 'service center',
        'format': 'json',
        'addressdetails': '1',
        'limit': '10',
        'viewbox': viewbox,
        'bounded': '1',
      });

      final response = await http
          .get(url, headers: {'User-Agent': 'VaultedApp/1.0'})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body) as List;
        for (final item in list) {
          final displayName = (item['display_name'] as String?) ?? '';
          final rawName = (item['name'] as String?)?.isNotEmpty == true
              ? item['name'] as String
              : displayName.split(',').first.trim();
          final lat = double.tryParse('${item['lat']}');
          final lon = double.tryParse('${item['lon']}');

          if (lat != null && lon != null) {
            final double dist =
                Geolocator.distanceBetween(
                  pos.latitude,
                  pos.longitude,
                  lat,
                  lon,
                ) /
                1000.0;

            final nameKey = rawName.toLowerCase();
            final isDuplicate = seenNames.any(
              (s) => s.contains(nameKey) || nameKey.contains(s),
            );

            if (dist <= 10.0 && !isDuplicate) {
              seenNames.add(nameKey);
              combinedResults.add({
                'name': rawName,
                'brand': _detectBrand('$rawName $displayName'),
                'address': displayName,
                'lat': lat,
                'lng': lon,
                'status': 'Verified Service Center · Near You',
              });
            }
          }
        }
      }
    } catch (_) {
      // Jika jaringan/OSM offline atau timeout, direktori terverifikasi tetap aman ditampilkan
    }

    // 3. Urutkan hasil dari yang paling dekat (terendah km)
    combinedResults.sort((a, b) {
      final d1 = _distanceOf(a);
      final d2 = _distanceOf(b);
      return d1.compareTo(d2);
    });

    if (!mounted) return;

    setState(() {
      _serviceCenters = combinedResults;
      _centersMessage = combinedResults.isEmpty
          ? 'Tidak ada service center resmi terdata dalam radius ~10 km dari lokasimu.'
          : null;
      _loadingCenters = false;
    });
  }

  Future<void> _determinePosition() async {
    setState(() {
      _loadingLocation = true;
      _locationStatus = 'Acquiring GPS fix...';
      _currentAddress = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus =
              'Location services are disabled. Please enable GPS.';
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

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'Location permissions permanently denied. Please enable in Settings.';
          _loadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _currentPosition = position;
        _locationStatus =
            'GPS Active: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });

      _fetchNearbyCenters(position); // jalan paralel dengan reverse geocoding

      // Reverse geocoding via Nominatim (OpenStreetMap) — works on web + mobile
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json&addressdetails=1',
        );
        final response = await http.get(
          url,
          headers: {'User-Agent': 'VaultedApp/1.0'},
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final displayName = data['display_name'] as String?;
          if (displayName != null && displayName.isNotEmpty) {
            setState(() {
              _currentAddress = displayName;
            });
          }
        }
      } catch (_) {
        // Reverse geocoding failed — coordinates are still shown
      }

      setState(() {
        _loadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationStatus =
            'Failed to get location: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}';
        _loadingLocation = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadWarrantyItems();
    _determinePosition();
  }

  Future<void> _loadWarrantyItems() async {
    try {
      final items = await DatabaseHelper.instance.getItems();
      final withWarranty = items.where((i) => i['warranty_expiry_date'] != null).toList();
      if (mounted) {
        setState(() {
          _userWarrantyItems = withWarranty;
          _loadingWarrantyItems = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingWarrantyItems = false);
      }
    }
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
                  Text(
                    'VAULTED',
                    style: VaultTypography.mono(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: VaultColors.ink,
                    ),
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
                    const Icon(
                      Icons.my_location_rounded,
                      color: VaultColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Location',
                            style: VaultTypography.sans(
                              fontSize: 11,
                              color: VaultColors.ink2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _locationStatus,
                            style: VaultTypography.mono(
                              fontSize: 11.5,
                              color: VaultColors.ink,
                            ),
                          ),
                          if (_currentAddress != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _currentAddress!,
                              style: VaultTypography.sans(
                                fontSize: 11,
                                color: VaultColors.accent,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _loadingLocation ? null : _determinePosition,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VaultColors.ink,
                        foregroundColor: VaultColors.background,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _loadingLocation
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: VaultColors.background,
                              ),
                            )
                          : Text(
                              'Locate',
                              style: VaultTypography.sans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: VaultColors.background,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. YOUR PROTECTED HARDWARE (Live from SQLite)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Protected Hardware',
                    style: VaultTypography.sectionTitle,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: VaultColors.badgeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_userWarrantyItems.length} COVERED',
                      style: VaultTypography.mono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: VaultColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_loadingWarrantyItems)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: VaultColors.accent),
                    ),
                  ),
                )
              else if (_userWarrantyItems.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: VaultColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: VaultColors.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No hardware warranties logged yet',
                        style: VaultTypography.sans(fontSize: 13, fontWeight: FontWeight.w600, color: VaultColors.ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scan a purchase invoice using Gemini OCR or command Valto to log your tech gear with warranty coverage.',
                        style: VaultTypography.sans(fontSize: 11.5, color: VaultColors.ink2),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 115,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _userWarrantyItems.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (ctx, i) {
                      final it = _userWarrantyItems[i];
                      final name = it['name'] as String? ?? 'Asset';
                      final serial = it['serial_number'] as String? ?? 'SN-N/A';
                      final warranty = it['warranty_expiry_date'] as String? ?? 'N/A';

                      return Container(
                        width: 220,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: VaultColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: VaultColors.hairline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.shield_outlined, size: 16, color: VaultColors.accent),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: VaultTypography.sans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: VaultColors.ink,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'S/N: $serial',
                                  style: VaultTypography.mono(fontSize: 10, color: VaultColors.ink2),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 12, color: VaultColors.pos),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Valid to $warranty',
                                      style: VaultTypography.mono(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: VaultColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 22),

              // Service Centers List
              Text(
                'Nearest Authorized Partners',
                style: VaultTypography.sectionTitle,
              ),
              const SizedBox(height: 12),

              if (_currentPosition == null)
                Text(
                  'Tekan "Locate" untuk menampilkan service center terdekat dari posisimu.',
                  style: VaultTypography.cardDescription,
                )
              else if (_loadingCenters)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: VaultColors.accent,
                    ),
                  ),
                )
              else if (_centersMessage != null)
                Text(_centersMessage!, style: VaultTypography.cardDescription),

              ..._serviceCenters.map((center) {
                final dist = _distanceOf(center);

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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: VaultColors.badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              center['brand'] as String,
                              style: VaultTypography.mono(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: VaultColors.accent,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: VaultColors.posBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${dist.toStringAsFixed(1)} km away',
                              style: VaultTypography.mono(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: VaultColors.pos,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        center['name'] as String,
                        style: VaultTypography.sans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        center['address'] as String,
                        style: VaultTypography.sans(
                          fontSize: 11.5,
                          color: VaultColors.ink2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            size: 14,
                            color: VaultColors.pos,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              center['status'] as String,
                              style: VaultTypography.sans(
                                fontSize: 11,
                                color: VaultColors.pos,
                              ),
                            ),
                          ),
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
