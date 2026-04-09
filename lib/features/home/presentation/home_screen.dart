import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../l10n/app_locale.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../auth/data/auth_session_store.dart';
import '../../auth/presentation/login_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const LatLng _defaultLocation = LatLng(29.3759, 47.9774);

  int _selectedTab = 0;
  bool _isLoggingOut = false;
  _SortOption _sortOption = _SortOption.distance;
  LatLng _mapCenter = _defaultLocation;
  String _currentLocationText = '';
  bool _isLocationLoading = true;
  bool _locationPermissionGranted = false;
  StreamSubscription<Position>? _previewPositionSubscription;
  LatLng? _lastResolvedGeoPoint;
  DateTime? _lastResolvedAt;
  int _resolveRequestToken = 0;

  final List<_Mechanic> _mechanics = const [
    _Mechanic(key: 'awan', rating: 4.8, distanceKm: 1.2),
    _Mechanic(key: 'arfan', rating: 4.7, distanceKm: 2.0),
    _Mechanic(key: 'ehsan', rating: 4.9, distanceKm: 2.5),
    _Mechanic(key: 'pakistan', rating: 4.6, distanceKm: 3.1),
    _Mechanic(key: 'awami', rating: 4.8, distanceKm: 3.7),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_startHomeLocationTracking());
  }

  @override
  void dispose() {
    _previewPositionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startHomeLocationTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLocationLoading = false;
            _locationPermissionGranted = false;
            _currentLocationText = '';
          });
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLocationLoading = false;
            _locationPermissionGranted = false;
            _currentLocationText = '';
          });
        }
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        if (mounted) {
          setState(() {
            _isLocationLoading = false;
            _locationPermissionGranted = true;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _mapCenter = LatLng(position!.latitude, position.longitude);
          _currentLocationText = _formatLocationText(
            position.latitude,
            position.longitude,
          );
          _isLocationLoading = false;
          _locationPermissionGranted = true;
        });
        unawaited(
          _resolveLocationName(
            latitude: position.latitude,
            longitude: position.longitude,
            force: true,
          ),
        );
      }

      _previewPositionSubscription?.cancel();
      _previewPositionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 8,
        ),
      ).listen((nextPosition) {
        if (!mounted) return;
        final nextLatLng =
            LatLng(nextPosition.latitude, nextPosition.longitude);
        setState(() {
          _mapCenter = nextLatLng;
          if (_currentLocationText.trim().isEmpty) {
            _currentLocationText = _formatLocationText(
              nextPosition.latitude,
              nextPosition.longitude,
            );
          }
          _isLocationLoading = false;
          _locationPermissionGranted = true;
        });
        unawaited(
          _resolveLocationName(
            latitude: nextPosition.latitude,
            longitude: nextPosition.longitude,
          ),
        );
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
          _locationPermissionGranted = false;
          _currentLocationText = '';
        });
      }
    }
  }

  String _formatLocationText(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }

  Future<void> _resolveLocationName({
    required double latitude,
    required double longitude,
    bool force = false,
  }) async {
    final now = DateTime.now();

    if (!force &&
        _lastResolvedGeoPoint != null &&
        _lastResolvedAt != null &&
        now.difference(_lastResolvedAt!) < const Duration(seconds: 35)) {
      final distanceMeters = Geolocator.distanceBetween(
        latitude,
        longitude,
        _lastResolvedGeoPoint!.latitude,
        _lastResolvedGeoPoint!.longitude,
      );
      if (distanceMeters < 85) return;
    }

    final token = ++_resolveRequestToken;
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (!mounted || token != _resolveRequestToken) return;

      final placeLabel = _buildPlaceLabel(placemarks);
      setState(() {
        _currentLocationText = placeLabel.isEmpty
            ? _formatLocationText(latitude, longitude)
            : placeLabel;
        _lastResolvedGeoPoint = LatLng(latitude, longitude);
        _lastResolvedAt = now;
      });
    } catch (_) {
      if (!mounted || token != _resolveRequestToken) return;
      setState(() {
        _currentLocationText = _formatLocationText(latitude, longitude);
        _lastResolvedGeoPoint = LatLng(latitude, longitude);
        _lastResolvedAt = now;
      });
    }
  }

  String _buildPlaceLabel(List<Placemark> placemarks) {
    if (placemarks.isEmpty) return '';
    final place = placemarks.first;

    final parts = <String>[
      if ((place.subLocality ?? '').trim().isNotEmpty)
        (place.subLocality ?? '').trim(),
      if ((place.locality ?? '').trim().isNotEmpty)
        (place.locality ?? '').trim(),
      if ((place.administrativeArea ?? '').trim().isNotEmpty)
        (place.administrativeArea ?? '').trim(),
      if ((place.country ?? '').trim().isNotEmpty) (place.country ?? '').trim(),
    ];

    final unique = <String>[];
    for (final part in parts) {
      if (!unique.contains(part)) unique.add(part);
    }
    if (unique.isEmpty) return '';
    return unique.take(2).join(', ');
  }

  Future<void> _onLogout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      await AuthSessionStore.clear();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.homeLogoutFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  Future<void> _openHomeMenu() async {
    var isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final displayLocationText = _currentLocationText.isEmpty
        ? context.l10n.homeCurrentLocationFallback
        : _currentLocationText;
    final action = await showGeneralDialog<_HomeMenuAction>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'home-menu',
      barrierColor: Colors.black.withValues(alpha: 0.24),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
      transitionBuilder: (
        dialogContext,
        animation,
        secondaryAnimation,
        child,
      ) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: Material(
              color: Colors.white,
              child: SafeArea(
                child: StatefulBuilder(
                  builder: (menuContext, setMenuState) {
                    final activeLanguageLabel = isUrdu
                        ? context.l10n.switchToUrdu
                        : context.l10n.switchToEnglish;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                          padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF0A3A86), Color(0xFF002E6E)],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x2A00132E),
                                blurRadius: 22,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.22),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.grid_view_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      context.l10n.homeBrandTitle,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1.0,
                                        letterSpacing: -0.7,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(),
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.16),
                                    ),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFF9FC3FF),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    displayLocationText,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFDCE9FF),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Text(
                            context.l10n.homeServicesTitle,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _MenuLanguageToggleTile(
                          icon: Icons.language_rounded,
                          label:
                              '${context.l10n.homeMenuLanguage}: $activeLanguageLabel',
                          value: isUrdu,
                          onChanged: (value) async {
                            setMenuState(() => isUrdu = value);
                            await AppLocale.setLocale(
                              value ? const Locale('ur') : const Locale('en'),
                            );
                          },
                        ),
                        _MenuActionTile(
                          icon: Icons.person_outline_rounded,
                          label: context.l10n.homeMenuProfile,
                          onTap: () => Navigator.of(dialogContext)
                              .pop(_HomeMenuAction.profile),
                        ),
                        _MenuActionTile(
                          icon: Icons.support_agent_rounded,
                          label: context.l10n.homeMenuContactUs,
                          onTap: () => Navigator.of(dialogContext)
                              .pop(_HomeMenuAction.contactUs),
                        ),
                        _MenuActionTile(
                          icon: Icons.settings_outlined,
                          label: context.l10n.homeMenuSetting,
                          onTap: () => Navigator.of(dialogContext)
                              .pop(_HomeMenuAction.setting),
                        ),
                        _MenuActionTile(
                          icon: Icons.logout_rounded,
                          label: context.l10n.homeMenuLogout,
                          destructive: true,
                          onTap: () => Navigator.of(dialogContext)
                              .pop(_HomeMenuAction.logout),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                          child: Container(
                            width: double.infinity,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD7DDE8),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _HomeMenuAction.profile:
        setState(() => _selectedTab = 3);
      case _HomeMenuAction.contactUs:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.homeContactUsSoon)),
        );
      case _HomeMenuAction.setting:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.homeSettingsSoon)),
        );
      case _HomeMenuAction.logout:
        await _onLogout();
    }
  }

  void _showSortOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.homeSortLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                _SortTile(
                  label: context.l10n.homeSortByDistance,
                  selected: _sortOption == _SortOption.distance,
                  onTap: () {
                    setState(() => _sortOption = _SortOption.distance);
                    Navigator.of(sheetContext).pop();
                  },
                ),
                _SortTile(
                  label: context.l10n.homeSortByRating,
                  selected: _sortOption == _SortOption.rating,
                  onTap: () {
                    setState(() => _sortOption = _SortOption.rating);
                    Navigator.of(sheetContext).pop();
                  },
                ),
                _SortTile(
                  label: context.l10n.homeSortByName,
                  selected: _sortOption == _SortOption.name,
                  onTap: () {
                    setState(() => _sortOption = _SortOption.name);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_Mechanic> get _sortedMechanics {
    final copy = [..._mechanics];
    switch (_sortOption) {
      case _SortOption.distance:
        copy.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      case _SortOption.rating:
        copy.sort((a, b) => b.rating.compareTo(a.rating));
      case _SortOption.name:
        copy.sort((a, b) => _mechanicName(a).compareTo(_mechanicName(b)));
    }
    return copy;
  }

  String _mechanicName(_Mechanic mechanic) {
    switch (mechanic.key) {
      case 'awan':
        return context.l10n.homeMechanicAwan;
      case 'arfan':
        return context.l10n.homeMechanicArfan;
      case 'ehsan':
        return context.l10n.homeMechanicEhsan;
      case 'pakistan':
        return context.l10n.homeMechanicPakistan;
      default:
        return context.l10n.homeMechanicAwami;
    }
  }

  String _mechanicSubtitle(_Mechanic mechanic) {
    return '${mechanic.rating.toStringAsFixed(1)}  •  ${mechanic.distanceKm.toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    final displayLocationText = _currentLocationText.isEmpty
        ? context.l10n.homeCurrentLocationFallback
        : _currentLocationText;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: [
            _HomeTab(
              onMenuTap: _openHomeMenu,
              onExpandMap: () =>
                  Navigator.of(context).pushNamed(MapScreen.routeName),
              onRequestSos: () => setState(() => _selectedTab = 1),
              onSortTap: _showSortOptions,
              mapCenter: _mapCenter,
              currentLocationText: displayLocationText,
              isLocationLoading: _isLocationLoading,
              locationPermissionGranted: _locationPermissionGranted,
              mechanicNameBuilder: _mechanicName,
              mechanicSubtitleBuilder: _mechanicSubtitle,
              mechanics: _sortedMechanics,
            ),
            _RequestsTab(
              onRequestSos: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.homeSosRequestOpened)),
                );
              },
            ),
            const _HistoryTab(),
            _ProfileTab(
              isLoggingOut: _isLoggingOut,
              onLogout: _onLogout,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _selectedTab,
        onChanged: (index) => setState(() => _selectedTab = index),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.onMenuTap,
    required this.onExpandMap,
    required this.onRequestSos,
    required this.onSortTap,
    required this.mapCenter,
    required this.currentLocationText,
    required this.isLocationLoading,
    required this.locationPermissionGranted,
    required this.mechanicNameBuilder,
    required this.mechanicSubtitleBuilder,
    required this.mechanics,
  });

  final VoidCallback onMenuTap;
  final VoidCallback onExpandMap;
  final VoidCallback onRequestSos;
  final VoidCallback onSortTap;
  final LatLng mapCenter;
  final String currentLocationText;
  final bool isLocationLoading;
  final bool locationPermissionGranted;
  final String Function(_Mechanic) mechanicNameBuilder;
  final String Function(_Mechanic) mechanicSubtitleBuilder;
  final List<_Mechanic> mechanics;

  @override
  Widget build(BuildContext context) {
    final services = [
      _ServiceItem(
        label: context.l10n.homeServiceMechanic,
        icon: Icons.handyman_outlined,
        iconColor: const Color(0xFF163062),
        bgColor: const Color(0xFFEAF0FF),
      ),
      _ServiceItem(
        label: context.l10n.homeServicePuncture,
        icon: Icons.tire_repair_outlined,
        iconColor: const Color(0xFFA8561B),
        bgColor: const Color(0xFFFBEFDF),
      ),
      _ServiceItem(
        label: context.l10n.homeServiceBattery,
        icon: Icons.battery_charging_full_rounded,
        iconColor: const Color(0xFF6D560A),
        bgColor: const Color(0xFFFBF8E2),
      ),
      _ServiceItem(
        label: context.l10n.homeServiceTowing,
        icon: Icons.local_shipping_outlined,
        iconColor: const Color(0xFF163062),
        bgColor: const Color(0xFFEAF0FF),
      ),
      _ServiceItem(
        label: context.l10n.homeServiceFuel,
        icon: Icons.local_gas_station_outlined,
        iconColor: const Color(0xFF1F7A43),
        bgColor: const Color(0xFFEAF7EE),
      ),
      _ServiceItem(
        label: context.l10n.homeServiceAccident,
        icon: Icons.car_crash_outlined,
        iconColor: Colors.white,
        bgColor: AppColors.primary,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 128),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onMenuTap,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.menu_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.homeCurrentLocationLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9AA0AA),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentLocationText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        height: 1.1,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.homeBrandTitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDCE3EE)),
            ),
            child: Column(
              children: [
                Container(
                  height: 190,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        GoogleMap(
                          key: ValueKey<String>(
                            'home-preview-${mapCenter.latitude.toStringAsFixed(5)}-${mapCenter.longitude.toStringAsFixed(5)}',
                          ),
                          initialCameraPosition: CameraPosition(
                            target: mapCenter,
                            zoom: 14.5,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('home-preview-location'),
                              position: mapCenter,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueBlue,
                              ),
                            ),
                          },
                          circles: {
                            Circle(
                              circleId: const CircleId('home-preview-accuracy'),
                              center: mapCenter,
                              radius: 28,
                              fillColor: const Color(0x663E7DFF),
                              strokeColor: const Color(0xAA3E7DFF),
                              strokeWidth: 1,
                            ),
                          },
                          myLocationEnabled: locationPermissionGranted,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          compassEnabled: false,
                          mapToolbarEnabled: false,
                          tiltGesturesEnabled: false,
                          rotateGesturesEnabled: false,
                          zoomGesturesEnabled: false,
                          scrollGesturesEnabled: false,
                        ),
                        if (isLocationLoading)
                          Positioned.fill(
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.62),
                              alignment: Alignment.center,
                              child: Text(
                                context.l10n.homeMapLoading,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -34),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFF5F2EA),
                          child: Icon(
                            Icons.shield_outlined,
                            color: AppColors.primary.withValues(alpha: 0.88),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.homePatrolsTitle,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4F5460),
                                ),
                              ),
                              Text(
                                context.l10n.homePatrolsSubtitle,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F2430),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: onExpandMap,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: Text(
                              context.l10n.homeExpandMap,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x21000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.homeEmergencyTitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.homeEmergencySubtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFDCE5F5),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: onRequestSos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA8571C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.sos_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          context.l10n.homeRequestSos,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            context.l10n.homeServicesTitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              height: 1.0,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.32,
            ),
            itemBuilder: (context, index) =>
                _ServiceCard(item: services[index]),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.homeNearbyMechanicsTitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    height: 1.0,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              InkWell(
                onTap: onSortTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.filter_list_rounded,
                        size: 18,
                        color: Color(0xFF6B7180),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.homeSortLabel,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7180),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...mechanics.map(
            (mechanic) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MechanicCard(
                name: mechanicNameBuilder(mechanic),
                subtitle: mechanicSubtitleBuilder(mechanic),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.onRequestSos});

  final VoidCallback onRequestSos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.homeRequestsTitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.homeRequestsSubtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6A707B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Text(
                  context.l10n.homeRequestEmergencyNow,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 62,
                  child: ElevatedButton.icon(
                    onPressed: onRequestSos,
                    icon: const Icon(Icons.sos_rounded, color: Colors.white),
                    label: Text(
                      context.l10n.homeRequestSos,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.homeHistoryTitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.homeHistorySubtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6A707B),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.isLoggingOut,
    required this.onLogout,
  });

  final bool isLoggingOut;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.homeProfileTitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.homeProfileSubtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6A707B),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLoggingOut ? null : onLogout,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                isLoggingOut
                    ? context.l10n.homeLoggingOut
                    : context.l10n.homeLogoutButton,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MechanicCard extends StatelessWidget {
  const _MechanicCard({
    required this.name,
    required this.subtitle,
  });

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFEAF0FF),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2330),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF69707C),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.item});

  final _ServiceItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: item.bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.iconColor, size: 30),
          ),
          const SizedBox(height: 12),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20252C),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  const _SortTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? AppColors.primary : const Color(0xFF404654),
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : const SizedBox.shrink(),
    );
  }
}

class _MenuLanguageToggleTile extends StatelessWidget {
  const _MenuLanguageToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3E8F1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1000112E),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuActionTile extends StatelessWidget {
  const _MenuActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFD14336) : AppColors.primary;
    final iconBg =
        destructive ? const Color(0xFFFFEDEE) : const Color(0xFFEAF0FF);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3E8F1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1000112E),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: destructive
                      ? const Color(0xFFFCEBED)
                      : const Color(0xFFEAF0FF),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5E9F1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000F2F),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _BottomItem(
                label: context.l10n.homeTabHome,
                icon: Icons.home_rounded,
                selected: currentIndex == 0,
                onTap: () => onChanged(0),
              ),
              _BottomItem(
                label: context.l10n.homeTabRequests,
                icon: Icons.wifi_tethering_error_rounded,
                selected: currentIndex == 1,
                onTap: () => onChanged(1),
              ),
              _BottomItem(
                label: context.l10n.homeTabHistory,
                icon: Icons.history_rounded,
                selected: currentIndex == 2,
                onTap: () => onChanged(2),
              ),
              _BottomItem(
                label: context.l10n.homeTabProfile,
                icon: Icons.person_outline_rounded,
                selected: currentIndex == 3,
                onTap: () => onChanged(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : const Color(0xFFA2A8B4),
              size: selected ? 24 : 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.primary : const Color(0xFFA2A8B4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceItem {
  const _ServiceItem({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
}

class _Mechanic {
  const _Mechanic({
    required this.key,
    required this.rating,
    required this.distanceKm,
  });

  final String key;
  final double rating;
  final double distanceKm;
}

enum _SortOption { distance, rating, name }

enum _HomeMenuAction { profile, contactUs, setting, logout }
