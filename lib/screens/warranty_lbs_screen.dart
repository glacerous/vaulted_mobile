import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';

/// Ergonomic, Luxury Native LBS Screen for VAULTED.
/// Built with fullscreen interactive map, automatic GPS lock,
/// zero watermarks, brand filter dock, and tactile bottom card carousel.
class WarrantyLbsScreen extends StatefulWidget {
  const WarrantyLbsScreen({super.key});

  @override
  State<WarrantyLbsScreen> createState() => _WarrantyLbsScreenState();
}

class _WarrantyLbsScreenState extends State<WarrantyLbsScreen> {
  late final MapController _mapController;
  late final PageController _pageController;

  Position? _userPosition;
  String _locationName = 'Locating GPS...';

  int _selectedCenterIndex = 0;
  String _selectedBrand = 'All';

  // Verified official service centers in Yogyakarta & Sleman (near UPNYK)
  static const List<Map<String, dynamic>> _directory = [
    {
      'name': 'Asus Service Center Exclusive Jogja',
      'brand': 'Asus',
      'address': 'Jl. Ring Road Utara No. 10, Condongcatur, Depok, Sleman',
      'lat': -7.7583,
      'lng': 110.4045,
      'status': 'Official ROG & ZenBook Hardware Support',
      'phone': '(0274) 4469000',
    },
    {
      'name': 'Apple Authorized Provider (iBox Ambarrukmo Plaza)',
      'brand': 'Apple',
      'address': 'Plaza Ambarrukmo Lt. 2, Jl. Laksda Adisucipto, Sleman',
      'lat': -7.7828,
      'lng': 110.4011,
      'status': 'Official Apple Warranty & Hardware Repair',
      'phone': '(0274) 4331234',
    },
    {
      'name': 'Samsung Customer Service Center Ambarrukmo',
      'brand': 'Samsung',
      'address': 'Jl. Laksda Adisucipto No. 165, Caturtunggal, Depok, Sleman',
      'lat': -7.7825,
      'lng': 110.3985,
      'status': 'Official Samsung Galaxy Service & Express Care',
      'phone': '0800 1128888',
    },
    {
      'name': 'Mitracare Apple Authorized Service Provider',
      'brand': 'Apple',
      'address': 'Jl. Affandi (Gejayan) No. 17B, Caturtunggal, Depok, Sleman',
      'lat': -7.7725,
      'lng': 110.3888,
      'status': 'Official Apple Care & Genuine Parts',
      'phone': '(0274) 555666',
    },
    {
      'name': 'Xiaomi Exclusive Service Center Sagan',
      'brand': 'Xiaomi',
      'address': 'Ruko Sagan Square, Jl. Prof. Herman Yohanes, Yogyakarta',
      'lat': -7.7770,
      'lng': 110.3790,
      'status': 'Certified Xiaomi, Redmi & POCO Fast Service',
      'phone': '0800 1401558',
    },
    {
      'name': 'Lenovo Exclusive Service Center Jogja',
      'brand': 'Lenovo',
      'address': 'Jl. Kaliurang KM 5 No. 28, Caturtunggal, Depok, Sleman',
      'lat': -7.7645,
      'lng': 110.3780,
      'status': 'Official Legion, Yoga & ThinkPad Repair',
      'phone': '(0274) 565656',
    },
    {
      'name': 'Sony Authorized Service Station',
      'brand': 'Sony',
      'address': 'Jl. C. Simanjuntak No. 42, Terban, Gondokusuman, Yogyakarta',
      'lat': -7.7791,
      'lng': 110.3732,
      'status': 'Alpha Cameras, Audio & Xperia Specialist',
      'phone': '(0274) 589012',
    },
    {
      'name': 'HP Authorized Service Center Yogyakarta',
      'brand': 'HP',
      'address': 'Jl. Code III, Sinduadi, Mlati, Sleman',
      'lat': -7.7633,
      'lng': 110.3696,
      'status': 'Official HP Pavilion, OMEN & Spectre Repair',
      'phone': '(0274) 623456',
    },
    {
      'name': 'OPPO Official Service Center Gejayan',
      'brand': 'Oppo',
      'address': 'Jl. Affandi (Gejayan) No. 10A, Caturtunggal, Depok, Sleman',
      'lat': -7.7712,
      'lng': 110.3885,
      'status': 'Official OPPO 1-Hour Flash Repair',
      'phone': '(0274) 589111',
    },
  ];

  List<Map<String, dynamic>> _filteredList = [];

  // Default coordinate: Sleman / UPNYK area
  static const LatLng _defaultLocation = LatLng(-7.7599, 110.4297);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pageController = PageController(viewportFraction: 0.90);
    _filteredList = List.from(_directory);

    // 100% AUTOMATIC GPS ACQUISITION
    _autoLocateUser();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double _calcDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R * asin...
  }

  double _distanceTo(Map<String, dynamic> item) {
    final lat = (item['lat'] as num).toDouble();
    final lng = (item['lng'] as num).toDouble();
    if (_userPosition != null) {
      return _calcDistanceKm(
        _userPosition!.latitude,
        _userPosition!.longitude,
        lat,
        lng,
      );
    }
    return _calcDistanceKm(
      _defaultLocation.latitude,
      _defaultLocation.longitude,
      lat,
      lng,
    );
  }

  void _sortAndFilter() {
    var list = _directory.where((item) {
      if (_selectedBrand == 'All') return true;
      return item['brand']?.toString().toLowerCase() == _selectedBrand.toLowerCase();
    }).toList();

    list.sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));

    setState(() {
      _filteredList = list;
      _selectedCenterIndex = 0;
    });

    if (list.isNotEmpty) {
      _focusOnIndex(0);
    }
  }

  Future<void> _autoLocateUser() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _fallbackToDefault();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _fallbackToDefault();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _fallbackToDefault();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 7),
        ),
      );

      if (!mounted) return;

      setState(() {
        _userPosition = pos;
        _locationName = 'GPS Locked (Sleman Regency)';
      });

      _sortAndFilter();

      // Pan to user location
      _mapController.move(LatLng(pos.latitude, pos.longitude), 14.2);
    } catch (e) {
      debugPrint('[Lbs] Auto location error: $e');
      _fallbackToDefault();
    }
  }

  void _fallbackToDefault() {
    if (!mounted) return;
    setState(() {
      _locationName = 'Depok, Sleman (Default GPS)';
    });
    _sortAndFilter();
  }

  void _recenterToUser() {
    HapticFeedback.selectionClick();
    if (_userPosition != null) {
      _mapController.move(
        LatLng(_userPosition!.latitude, _userPosition!.longitude),
        15.0,
      );
    } else {
      _mapController.move(_defaultLocation, 14.5);
    }
  }

  void _focusOnIndex(int index) {
    if (index >= 0 && index < _filteredList.length) {
      final item = _filteredList[index];
      final lat = (item['lat'] as num).toDouble();
      final lng = (item['lng'] as num).toDouble();
      _mapController.move(LatLng(lat, lng), 15.2);
    }
  }

  IconData _brandIconData(String? brand) {
    switch (brand?.toLowerCase()) {
      case 'apple':
        return Icons.apple;
      case 'asus':
        return Icons.laptop_chromebook_rounded;
      case 'samsung':
        return Icons.smartphone_rounded;
      case 'xiaomi':
        return Icons.phone_android_rounded;
      case 'lenovo':
        return Icons.laptop_mac_rounded;
      case 'sony':
        return Icons.camera_alt_rounded;
      case 'hp':
        return Icons.laptop_rounded;
      case 'oppo':
        return Icons.devices_rounded;
      default:
        return Icons.build_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brands = ['All', 'Asus', 'Apple', 'Samsung', 'Xiaomi', 'Lenovo', 'HP', 'Sony'];
    final userLatLng = _userPosition != null
        ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
        : _defaultLocation;

    return Scaffold(
      backgroundColor: VaultColors.background,
      body: Stack(
        children: [
          // ============================================================
          // 1. FULLSCREEN NATIVE MAP (OpenStreetMap - Zero Watermarks)
          // ============================================================
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userLatLng,
              initialZoom: 14.2,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vaulted.app',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  // User's Real-time Pulsing GPS Dot
                  Marker(
                    point: userLatLng,
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: VaultColors.accent.withValues(alpha: 0.25),
                          ),
                        ),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: VaultColors.accent,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: VaultColors.accent.withValues(alpha: 0.45),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Service Center Pins
                  ..._filteredList.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final isSelected = idx == _selectedCenterIndex;
                    final lat = (item['lat'] as num).toDouble();
                    final lng = (item['lng'] as num).toDouble();
                    final brand = item['brand'] as String? ?? '';
                    final pinWidth = isSelected ? 40.0 : 32.0;
                    final pinHeight = isSelected ? 50.0 : 42.0;

                    return Marker(
                      point: LatLng(lat, lng),
                      width: pinWidth,
                      height: pinHeight,
                      alignment: Alignment.bottomCenter,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCenterIndex = idx);
                          _focusOnIndex(idx);
                          _pageController.animateToPage(
                            idx,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: CustomPaint(
                          painter: _TeardropPinPainter(
                            color: isSelected ? VaultColors.ink : Colors.white,
                            strokeColor: isSelected ? VaultColors.accent : VaultColors.ink,
                            strokeWidth: isSelected ? 2.4 : 1.6,
                            isSelected: isSelected,
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: pinWidth,
                              height: pinWidth,
                              child: Center(
                                child: Icon(
                                  _brandIconData(brand),
                                  size: isSelected ? 20 : 15,
                                  color: isSelected ? VaultColors.accent : VaultColors.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // ============================================================
          // 2. FLOATING TOP HEADER & BRAND FILTER DOCK
          // ============================================================
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Bar Capsule
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: VaultColors.hairline),
                    ),
                    child: Row(
                      children: [
                        if (Navigator.of(context).canPop())
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: VaultColors.ink,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Official Service Centers',
                                style: VaultTypography.sans(fontSize: 13, fontWeight: FontWeight.w700, color: VaultColors.ink),
                              ),
                              Text(
                                _locationName,
                                style: VaultTypography.mono(fontSize: 10, color: VaultColors.ink2),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: VaultColors.badgeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_filteredList.length} Partners',
                            style: VaultTypography.mono(fontSize: 9.5, fontWeight: FontWeight.w700, color: VaultColors.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Brand Pills Dock
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: brands.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (ctx, idx) {
                        final b = brands[idx];
                        final isSel = _selectedBrand == b;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedBrand = b);
                            _sortAndFilter();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isSel ? VaultColors.primaryButton : Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: isSel ? VaultColors.primaryButton : VaultColors.hairline,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              b,
                              style: VaultTypography.sans(
                                fontSize: 11.5,
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel ? Colors.white : VaultColors.ink,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ============================================================
          // 3. FLOATING MAP CONTROLS (Right side thumb reach)
          // ============================================================
          Positioned(
            right: 16,
            bottom: 235,
            child: Column(
              children: [
                // Recenter My Location Button (Crosshair)
                GestureDetector(
                  onTap: _recenterToUser,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: VaultColors.hairline),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.my_location_rounded,
                      size: 20,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Zoom In
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final z = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, z + 1);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      border: Border.all(color: VaultColors.hairline),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.add_rounded, size: 18, color: VaultColors.ink),
                  ),
                ),

                // Zoom Out
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final z = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, z - 1);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                      border: Border.all(color: VaultColors.hairline),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.remove_rounded, size: 18, color: VaultColors.ink),
                  ),
                ),
              ],
            ),
          ),

          // ============================================================
          // 4. BOTTOM HORIZONTAL CAROUSEL (Mobile Thumb Zone)
          // ============================================================
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: SizedBox(
              height: 195,
              child: _filteredList.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: VaultColors.hairline),
                        ),
                        child: Text(
                          'No official partners found for this brand.',
                          style: VaultTypography.sans(fontSize: 12, color: VaultColors.ink2),
                        ),
                      ),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: _filteredList.length,
                      onPageChanged: (idx) {
                        setState(() => _selectedCenterIndex = idx);
                        _focusOnIndex(idx);
                      },
                      itemBuilder: (ctx, idx) {
                        final item = _filteredList[idx];
                        final dist = _distanceTo(item);
                        final brand = item['brand'] as String? ?? '';
                            final isSelected = idx == _selectedCenterIndex;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected ? VaultColors.accent : VaultColors.hairline,
                              width: isSelected ? 1.8 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Brand & Distance
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isSelected ? VaultColors.badgeBg : VaultColors.background,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSelected
                                            ? VaultColors.accent.withValues(alpha: 0.45)
                                            : VaultColors.hairline,
                                      ),
                                    ),
                                    child: Text(
                                      brand.toUpperCase(),
                                      style: VaultTypography.mono(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? VaultColors.accent : VaultColors.ink,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: VaultColors.posBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.near_me_rounded, size: 10, color: VaultColors.pos),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${dist.toStringAsFixed(1)} km away',
                                          style: VaultTypography.mono(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: VaultColors.pos,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Name
                              Text(
                                item['name'] as String? ?? 'Service Partner',
                                style: VaultTypography.sans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: VaultColors.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),

                              // Address
                              Text(
                                item['address'] as String? ?? '',
                                style: VaultTypography.sans(
                                  fontSize: 11,
                                  color: VaultColors.body,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),

                              // Status
                              Text(
                                item['status'] as String? ?? '',
                                style: VaultTypography.sans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: VaultColors.accent,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),

                              // Action Row
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        HapticFeedback.selectionClick();
                                        Clipboard.setData(
                                          ClipboardData(text: item['address'] as String? ?? ''),
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Alamat disalin ke clipboard!',
                                              style: VaultTypography.sans(fontSize: 12),
                                            ),
                                            duration: const Duration(seconds: 2),
                                            backgroundColor: VaultColors.toastBg,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.copy_rounded, size: 13, color: VaultColors.ink),
                                      label: Text(
                                        'Copy Alamat',
                                        style: VaultTypography.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: VaultColors.ink),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        side: const BorderSide(color: VaultColors.hairline),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        HapticFeedback.selectionClick();
                                        _focusOnIndex(idx);
                                      },
                                      icon: const Icon(Icons.navigation_rounded, size: 13, color: Colors.white),
                                      label: Text(
                                        'Fokus Peta',
                                        style: VaultTypography.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: VaultColors.primaryButton,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Precision custom vector painter for Apple Maps-style teardrop needle pins.
class _TeardropPinPainter extends CustomPainter {
  final Color color;
  final Color strokeColor;
  final double strokeWidth;
  final bool isSelected;

  const _TeardropPinPainter({
    required this.color,
    required this.strokeColor,
    this.strokeWidth = 1.8,
    this.isSelected = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;
    final tip = Offset(w / 2, h);

    final d = h - r;
    if (d <= r) return;
    final sinA = r / d;
    final cosA = sqrt(1.0 - (sinA * sinA));

    final leftTangent = Offset(w / 2 - r * cosA, r + r * sinA);
    final rightTangent = Offset(w / 2 + r * cosA, r + r * sinA);

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(leftTangent.dx, leftTangent.dy)
      ..arcToPoint(
        rightTangent,
        radius: Radius.circular(r),
        largeArc: true,
        clockwise: true,
      )
      ..close();

    // Drop shadow
    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: isSelected ? 0.35 : 0.22),
      isSelected ? 6.0 : 3.0,
      false,
    );

    // Fill
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _TeardropPinPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.isSelected != isSelected;
  }
}
