import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_locale.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../auth/data/auth_session_store.dart';
import '../../auth/presentation/login_screen.dart';
import '../../shared/widgets/blue_loader_overlay.dart';
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
  _ServiceType? _requestsServiceFilter;
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
    _Mechanic(
      key: 'awan',
      rating: 4.8,
      distanceKm: 1.2,
      specialty: 'Engine Specialist',
      avgPrice: '22 KD',
      phone: '+96590001111',
      latOffset: 0.0012,
      lngOffset: -0.0011,
    ),
    _Mechanic(
      key: 'arfan',
      rating: 4.7,
      distanceKm: 2.0,
      specialty: 'Tyre & Puncture',
      avgPrice: '15 KD',
      phone: '+96590002222',
      latOffset: -0.0014,
      lngOffset: 0.0010,
    ),
    _Mechanic(
      key: 'ehsan',
      rating: 4.9,
      distanceKm: 2.5,
      specialty: 'Battery Support',
      avgPrice: '18 KD',
      phone: '+96590003333',
      latOffset: 0.0018,
      lngOffset: 0.0016,
    ),
    _Mechanic(
      key: 'pakistan',
      rating: 4.6,
      distanceKm: 3.1,
      specialty: 'Towing Expert',
      avgPrice: '35 KD',
      phone: '+96590004444',
      latOffset: -0.0019,
      lngOffset: -0.0007,
    ),
    _Mechanic(
      key: 'awami',
      rating: 4.8,
      distanceKm: 3.7,
      specialty: 'Accident Recovery',
      avgPrice: '30 KD',
      phone: '+96590005555',
      latOffset: 0.0023,
      lngOffset: -0.0015,
    ),
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

  Future<void> _openContactUsSheet() async {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    var isSending = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  16,
                  18,
                  16 + MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.homeMenuContactUs,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        labelText: context.l10n.contactSubjectLabel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: messageController,
                      minLines: 4,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: context.l10n.contactMessageLabel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSending
                            ? null
                            : () async {
                                final subject = subjectController.text.trim();
                                final message = messageController.text.trim();
                                if (subject.isEmpty || message.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.l10n.contactValidation,
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) return;

                                setSheetState(() => isSending = true);
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('contact_messages')
                                      .add({
                                    'uid': user.uid,
                                    'email': user.email ?? '',
                                    'subject': subject,
                                    'message': message,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                                  if (!sheetContext.mounted) return;
                                  if (!mounted) return;
                                  Navigator.of(sheetContext).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.l10n.contactSentSuccess,
                                      ),
                                    ),
                                  );
                                } catch (_) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text(context.l10n.authGenericError),
                                    ),
                                  );
                                } finally {
                                  if (sheetContext.mounted) {
                                    setSheetState(() => isSending = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isSending
                              ? context.l10n.homeMapLoading
                              : context.l10n.contactSendButton,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    subjectController.dispose();
    messageController.dispose();
  }

  Future<void> _openHomeMenu() async {
    var isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final authUser = FirebaseAuth.instance.currentUser;
    final menuName = (authUser?.displayName ?? '').trim().isEmpty
        ? context.l10n.homeBrandTitle
        : authUser!.displayName!.trim();
    final menuPhotoUrl = authUser?.photoURL;
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
                                    child: menuPhotoUrl == null
                                        ? const Icon(
                                            Icons.person_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          )
                                        : ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(13),
                                            child: Image.network(
                                              menuPhotoUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                Icons.person_rounded,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          menuName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            height: 1.0,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          context.l10n.homeBrandTitle,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFDCE9FF),
                                          ),
                                        ),
                                      ],
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
        await _openContactUsSheet();
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

  void _openMechanicOnMap(_Mechanic mechanic) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapScreen(
          mechanicDetails: MechanicMapDetails(
            name: _mechanicName(mechanic),
            specialty: mechanic.specialty,
            rating: mechanic.rating,
            avgPrice: mechanic.avgPrice,
            phone: mechanic.phone,
            location: LatLng(
              _mapCenter.latitude + mechanic.latOffset,
              _mapCenter.longitude + mechanic.lngOffset,
            ),
          ),
        ),
      ),
    );
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
              onRequestSos: () => setState(() {
                _requestsServiceFilter = null;
                _selectedTab = 1;
              }),
              onServiceTap: (_ServiceType type) => setState(() {
                _requestsServiceFilter = type;
                _selectedTab = 1;
              }),
              onSortTap: _showSortOptions,
              mapCenter: _mapCenter,
              currentLocationText: displayLocationText,
              isLocationLoading: _isLocationLoading,
              locationPermissionGranted: _locationPermissionGranted,
              mechanicNameBuilder: _mechanicName,
              mechanicSubtitleBuilder: _mechanicSubtitle,
              onMechanicTap: _openMechanicOnMap,
              mechanics: _sortedMechanics,
            ),
            _RequestsTab(
              onMenuTap: _openHomeMenu,
              currentLocation: _mapCenter,
              locationPermissionGranted: _locationPermissionGranted,
              selectedService: _requestsServiceFilter,
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
    required this.onServiceTap,
    required this.onSortTap,
    required this.onMechanicTap,
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
  final ValueChanged<_ServiceType> onServiceTap;
  final VoidCallback onSortTap;
  final ValueChanged<_Mechanic> onMechanicTap;
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
        type: _ServiceType.mechanic,
        label: context.l10n.homeServiceMechanic,
        icon: Icons.handyman_outlined,
        iconColor: const Color(0xFF163062),
        bgColor: const Color(0xFFEAF0FF),
      ),
      _ServiceItem(
        type: _ServiceType.puncture,
        label: context.l10n.homeServicePuncture,
        icon: Icons.tire_repair_outlined,
        iconColor: const Color(0xFFA8561B),
        bgColor: const Color(0xFFFBEFDF),
      ),
      _ServiceItem(
        type: _ServiceType.battery,
        label: context.l10n.homeServiceBattery,
        icon: Icons.battery_charging_full_rounded,
        iconColor: const Color(0xFF6D560A),
        bgColor: const Color(0xFFFBF8E2),
      ),
      _ServiceItem(
        type: _ServiceType.towing,
        label: context.l10n.homeServiceTowing,
        icon: Icons.local_shipping_outlined,
        iconColor: const Color(0xFF163062),
        bgColor: const Color(0xFFEAF0FF),
      ),
      _ServiceItem(
        type: _ServiceType.fuel,
        label: context.l10n.homeServiceFuel,
        icon: Icons.local_gas_station_outlined,
        iconColor: const Color(0xFF1F7A43),
        bgColor: const Color(0xFFEAF7EE),
      ),
      _ServiceItem(
        type: _ServiceType.accident,
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
              fontSize: 22,
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
            itemBuilder: (context, index) => _ServiceCard(
              item: services[index],
              onTap: () => onServiceTap(services[index].type),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.homeNearbyMechanicsTitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
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
                onTap: () => onMechanicTap(mechanic),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RequestsTab extends StatefulWidget {
  const _RequestsTab({
    required this.onMenuTap,
    required this.currentLocation,
    required this.locationPermissionGranted,
    required this.selectedService,
  });

  final VoidCallback onMenuTap;
  final LatLng currentLocation;
  final bool locationPermissionGranted;
  final _ServiceType? selectedService;

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  _RequestMechanic? _activeMechanic;
  _RequestStage _requestStage = _RequestStage.none;
  String? _activeRequestDocId;
  Timer? _acceptanceTimer;

  final List<_RequestMechanic> _nearbyMechanics = const [
    _RequestMechanic(
      id: 'm1',
      name: 'Ahmad Khan',
      vehicle: 'Blue Suzuki GS150',
      plate: 'ABC-123',
      rating: 4.9,
      phone: '+96590000111',
      etaMins: 12,
      services: {_ServiceType.mechanic, _ServiceType.battery},
      latOffset: 0.0012,
      lngOffset: -0.0011,
    ),
    _RequestMechanic(
      id: 'm2',
      name: 'Arslan Malik',
      vehicle: 'Toyota Hilux',
      plate: 'KWT-220',
      rating: 4.8,
      phone: '+96590000222',
      etaMins: 15,
      services: {_ServiceType.puncture, _ServiceType.fuel},
      latOffset: -0.0016,
      lngOffset: 0.0018,
    ),
    _RequestMechanic(
      id: 'm3',
      name: 'Naveed Ali',
      vehicle: 'Mitsubishi L200',
      plate: 'KWT-771',
      rating: 4.7,
      phone: '+96590000333',
      etaMins: 18,
      services: {_ServiceType.towing, _ServiceType.accident},
      latOffset: 0.0021,
      lngOffset: 0.0013,
    ),
  ];

  bool get _hasRequest => _requestStage != _RequestStage.none;
  bool get _isAccepted => _requestStage == _RequestStage.accepted;

  Iterable<_RequestMechanic> get _filteredMechanics {
    final selectedService = widget.selectedService;
    if (selectedService == null) return _nearbyMechanics;
    return _nearbyMechanics.where(
      (mechanic) => mechanic.services.contains(selectedService),
    );
  }

  String _serviceFilterLabel(_ServiceType serviceType) {
    switch (serviceType) {
      case _ServiceType.mechanic:
        return context.l10n.homeServiceMechanic;
      case _ServiceType.puncture:
        return context.l10n.homeServicePuncture;
      case _ServiceType.battery:
        return context.l10n.homeServiceBattery;
      case _ServiceType.towing:
        return context.l10n.homeServiceTowing;
      case _ServiceType.fuel:
        return context.l10n.homeServiceFuel;
      case _ServiceType.accident:
        return context.l10n.homeServiceAccident;
    }
  }

  LatLng _markerPosition(_RequestMechanic mechanic) {
    return LatLng(
      widget.currentLocation.latitude + mechanic.latOffset,
      widget.currentLocation.longitude + mechanic.lngOffset,
    );
  }

  @override
  void dispose() {
    _acceptanceTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _RequestsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedService != widget.selectedService &&
        _activeMechanic != null &&
        widget.selectedService != null &&
        !_activeMechanic!.services.contains(widget.selectedService)) {
      _acceptanceTimer?.cancel();
      _activeMechanic = null;
      _requestStage = _RequestStage.none;
      _activeRequestDocId = null;
    }
  }

  Future<void> _updateActiveRequestStatus({
    required String status,
    bool cancelledWithPenalty = false,
  }) async {
    final id = _activeRequestDocId;
    if (id == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('service_requests')
          .doc(id)
          .set(
        {
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
          if (status == 'accepted') 'acceptedAt': FieldValue.serverTimestamp(),
          if (status == 'cancelled')
            'cancelledAt': FieldValue.serverTimestamp(),
          if (cancelledWithPenalty) 'cancelPenalty': 500,
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  Future<void> _saveRequestSubmission({
    required _RequestMechanic mechanic,
    required _RequestSubmissionData formData,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final docRef =
          await FirebaseFirestore.instance.collection('service_requests').add({
        'uid': user.uid,
        'userEmail': user.email ?? '',
        'serviceType': widget.selectedService?.name ?? 'general',
        'mechanicId': mechanic.id,
        'mechanicName': mechanic.name,
        'mechanicPhone': mechanic.phone,
        'vehicleName': formData.vehicleName,
        'issueType': formData.issueType.name,
        'notes': formData.notes,
        'locationName': formData.locationName,
        'status': 'requested',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _activeRequestDocId = docRef.id;
    } catch (_) {
      _activeRequestDocId = null;
    }
  }

  void _requestMechanic(_RequestMechanic mechanic) {
    _acceptanceTimer?.cancel();
    setState(() {
      _activeMechanic = mechanic;
      _requestStage = _RequestStage.requested;
    });

    _acceptanceTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted) return;
      if (_requestStage == _RequestStage.requested &&
          _activeMechanic?.id == mechanic.id) {
        setState(() => _requestStage = _RequestStage.accepted);
        unawaited(_updateActiveRequestStatus(status: 'accepted'));
      }
    });
  }

  _RequestIssueType _initialIssueType() {
    switch (widget.selectedService) {
      case _ServiceType.mechanic:
        return _RequestIssueType.engine;
      case _ServiceType.puncture:
        return _RequestIssueType.flatTire;
      case _ServiceType.battery:
        return _RequestIssueType.deadBattery;
      case _ServiceType.towing:
      case _ServiceType.fuel:
      case _ServiceType.accident:
      case null:
        return _RequestIssueType.other;
    }
  }

  Future<void> _openRequestDetails(_RequestMechanic mechanic) async {
    final submission = await Navigator.of(context).push<_RequestSubmissionData>(
      MaterialPageRoute(
        builder: (_) => _RequestDetailScreen(
          currentLocation: widget.currentLocation,
          initialIssueType: _initialIssueType(),
        ),
      ),
    );

    if (!mounted || submission == null) return;
    await _saveRequestSubmission(mechanic: mechanic, formData: submission);
    if (!mounted) return;
    _requestMechanic(mechanic);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.requestDetailsSubmitted)),
    );
  }

  Future<void> _cancelRequest() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.l10n.homeRequestsCancelRequest),
          content: Text(context.l10n.homeRequestsCancelWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.homeRequestsKeepRequest),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.homeRequestsConfirmCancel),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true || !mounted) return;
    _acceptanceTimer?.cancel();
    unawaited(
      _updateActiveRequestStatus(
        status: 'cancelled',
        cancelledWithPenalty: true,
      ),
    );
    setState(() {
      _activeMechanic = null;
      _requestStage = _RequestStage.none;
      _activeRequestDocId = null;
    });
  }

  Future<void> _callMechanic(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.homeRequestsCallFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeMechanic;
    final liveStatusText = switch (_requestStage) {
      _RequestStage.none => context.l10n.homeRequestsTapMarkerHint,
      _RequestStage.requested => context.l10n.homeRequestsPendingStatus,
      _RequestStage.accepted => context.l10n.homeRequestsArrivingIn(
          active?.etaMins ?? 12,
        ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: widget.onMenuTap,
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
              Text(
                context.l10n.homeBrandTitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.selectedService == null
                      ? context.l10n.homeRequestsTitle
                      : _serviceFilterLabel(widget.selectedService!),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GoogleMap(
                    key: ValueKey<String>(
                      'requests-map-${widget.currentLocation.latitude.toStringAsFixed(5)}-${widget.currentLocation.longitude.toStringAsFixed(5)}-${active?.id ?? 'na'}',
                    ),
                    initialCameraPosition: CameraPosition(
                      target: widget.currentLocation,
                      zoom: 14.3,
                    ),
                    myLocationEnabled: widget.locationPermissionGranted,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    markers: {
                      Marker(
                        markerId: const MarkerId('request-user'),
                        position: widget.currentLocation,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue,
                        ),
                      ),
                      ..._filteredMechanics.map((mechanic) {
                        final selected = active?.id == mechanic.id;
                        return Marker(
                          markerId: MarkerId('mechanic-${mechanic.id}'),
                          position: _markerPosition(mechanic),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            selected
                                ? BitmapDescriptor.hueOrange
                                : BitmapDescriptor.hueYellow,
                          ),
                          onTap: () => _openRequestDetails(mechanic),
                        );
                      }),
                    },
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1600112E),
                            blurRadius: 14,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _TrackerDot(
                            label: context.l10n.homeRequestsStatusSent,
                            active: _hasRequest,
                          ),
                          _TrackerLine(active: _hasRequest),
                          _TrackerDot(
                            label: context.l10n.homeRequestsStatusAccepted,
                            active: _isAccepted,
                          ),
                          _TrackerLine(active: _isAccepted),
                          _TrackerDot(
                            label: context.l10n.homeRequestsStatusOnWay,
                            active: _isAccepted,
                          ),
                          const _TrackerLine(active: false),
                          _TrackerDot(
                            label: context.l10n.homeRequestsStatusArrived,
                            active: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 96,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A00112E),
                            blurRadius: 12,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.homeRequestsLiveUpdate,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD5E3FD),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            liveStatusText,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (active != null)
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x2200112E),
                              blurRadius: 24,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF0FF),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: AppColors.primary,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        active.name,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 23,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF131721),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _isAccepted
                                            ? '${active.vehicle} • ${active.plate}'
                                            : context
                                                .l10n.homeRequestsPendingStatus,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF606775),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF6DC),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Color(0xFFE3A600),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        active.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF383C45),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4F4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFFDEDE),
                                ),
                              ),
                              child: Text(
                                _isAccepted
                                    ? context.l10n.homeRequestsMechanicWarning
                                    : context.l10n.homeRequestsCancelWarning,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFAA1B1B),
                                  height: 1.25,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_isAccepted)
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: () => _callMechanic(active.phone),
                                  icon: const Icon(
                                    Icons.call_rounded,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    context.l10n.homeRequestsCallMechanic,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: _cancelRequest,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFFAA1B1B),
                                    ),
                                    foregroundColor: const Color(0xFFAA1B1B),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: Text(
                                    context.l10n.homeRequestsCancelRequest,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
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
          ),
        ],
      ),
    );
  }
}

class _RequestDetailScreen extends StatefulWidget {
  const _RequestDetailScreen({
    required this.currentLocation,
    required this.initialIssueType,
  });

  final LatLng currentLocation;
  final _RequestIssueType initialIssueType;

  @override
  State<_RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<_RequestDetailScreen> {
  late _RequestIssueType _selectedIssueType;
  final TextEditingController _notesController = TextEditingController();
  int _selectedVehicleIndex = 0;
  late String _locationLabel;

  @override
  void initState() {
    super.initState();
    _selectedIssueType = widget.initialIssueType;
    _locationLabel =
        '${widget.currentLocation.latitude.toStringAsFixed(5)}, ${widget.currentLocation.longitude.toStringAsFixed(5)}';
    unawaited(_resolveLocationName());
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _resolveLocationName() async {
    try {
      final placemarks = await placemarkFromCoordinates(
        widget.currentLocation.latitude,
        widget.currentLocation.longitude,
      );
      if (!mounted || placemarks.isEmpty) return;
      final place = placemarks.first;
      final parts = <String>[
        if ((place.subLocality ?? '').trim().isNotEmpty)
          (place.subLocality ?? '').trim(),
        if ((place.locality ?? '').trim().isNotEmpty)
          (place.locality ?? '').trim(),
        if ((place.country ?? '').trim().isNotEmpty)
          (place.country ?? '').trim(),
      ];
      final label = parts.join(', ');
      if (label.isEmpty) return;
      setState(() => _locationLabel = label);
    } catch (_) {}
  }

  List<_RequestVehicleOption> _vehicles(BuildContext context) {
    return [
      _RequestVehicleOption(
        name: context.l10n.requestDetailsVehicleOneName,
        detail: context.l10n.requestDetailsVehicleOneMeta,
        isPrimary: true,
      ),
      _RequestVehicleOption(
        name: context.l10n.requestDetailsVehicleTwoName,
        detail: context.l10n.requestDetailsVehicleTwoMeta,
        isPrimary: false,
      ),
    ];
  }

  List<_RequestIssueOption> _issues(BuildContext context) {
    return [
      _RequestIssueOption(
        type: _RequestIssueType.engine,
        label: context.l10n.requestDetailsIssueEngine,
        icon: Icons.precision_manufacturing_outlined,
      ),
      _RequestIssueOption(
        type: _RequestIssueType.flatTire,
        label: context.l10n.requestDetailsIssueFlatTire,
        icon: Icons.tire_repair_outlined,
      ),
      _RequestIssueOption(
        type: _RequestIssueType.deadBattery,
        label: context.l10n.requestDetailsIssueDeadBattery,
        icon: Icons.battery_alert_outlined,
      ),
      _RequestIssueOption(
        type: _RequestIssueType.other,
        label: context.l10n.requestDetailsIssueOther,
        icon: Icons.more_horiz_rounded,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = _vehicles(context);
    final issues = _issues(context);
    final selectedVehicle = vehicles[_selectedVehicleIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Text(
          context.l10n.requestDetailsAppTitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFEAF0FF),
              child: Icon(
                Icons.person_rounded,
                size: 18,
                color: AppColors.primary.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE6EBF2)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE6543A),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.requestDetailsUrgentPriority,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE6543A),
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.requestDetailsTitleLineOne,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F1C33),
                height: 0.95,
                letterSpacing: -0.9,
              ),
            ),
            Text(
              context.l10n.requestDetailsTitleLineTwo,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Color(0xFFC96A20),
                height: 0.95,
                letterSpacing: -0.9,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.requestDetailsSubtitle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF606775),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.requestDetailsSelectVehicle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF595F6C),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            ...vehicles.asMap().entries.map((entry) {
              final index = entry.key;
              final vehicle = entry.value;
              final selected = _selectedVehicleIndex == index;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => setState(() => _selectedVehicleIndex = index),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : const Color(0xFFE4E9F0),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.name,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF101828),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                vehicle.detail,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF667085),
                                ),
                              ),
                              if (vehicle.isPrimary) ...[
                                const SizedBox(height: 8),
                                Text(
                                  context.l10n.requestDetailsPrimaryVehicle,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF98A2B3),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: selected
                              ? AppColors.primary
                              : const Color(0xFFD0D5DD),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(
              context.l10n.requestDetailsIssueSection,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF595F6C),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: issues.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.24,
              ),
              itemBuilder: (context, index) {
                final issue = issues[index];
                final selected = issue.type == _selectedIssueType;
                return InkWell(
                  onTap: () => setState(() => _selectedIssueType = issue.type),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : const Color(0xFFE5EAF2),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          issue.icon,
                          size: 26,
                          color: selected
                              ? AppColors.primary
                              : const Color(0xFF334155),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          issue.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D2939),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  context.l10n.requestDetailsAdditionalNotes,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF595F6C),
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                Text(
                  context.l10n.requestDetailsOptional,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB3BAC6),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 4,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
              decoration: InputDecoration(
                hintText: context.l10n.requestDetailsNotesHint,
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFA1A8B3),
                ),
                filled: true,
                fillColor: const Color(0xFFF2F5F9),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE4E9F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF1FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.requestDetailsDetectedLocation,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF98A2B3),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _locationLabel,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(
                  _RequestSubmissionData(
                    vehicleName: selectedVehicle.name,
                    issueType: _selectedIssueType,
                    notes: _notesController.text.trim(),
                    locationName: _locationLabel,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFBF651E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.emergency_share_rounded),
                label: Text(
                  context.l10n.requestDetailsSubmit,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestVehicleOption {
  const _RequestVehicleOption({
    required this.name,
    required this.detail,
    required this.isPrimary,
  });

  final String name;
  final String detail;
  final bool isPrimary;
}

class _RequestIssueOption {
  const _RequestIssueOption({
    required this.type,
    required this.label,
    required this.icon,
  });

  final _RequestIssueType type;
  final String label;
  final IconData icon;
}

class _RequestSubmissionData {
  const _RequestSubmissionData({
    required this.vehicleName,
    required this.issueType,
    required this.notes,
    required this.locationName,
  });

  final String vehicleName;
  final _RequestIssueType issueType;
  final String notes;
  final String locationName;
}

class _TrackerDot extends StatelessWidget {
  const _TrackerDot({
    required this.label,
    required this.active,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? const Color(0xFF8B6200) : const Color(0xFFE3E6EB),
            ),
            child: Icon(
              active ? Icons.check_rounded : Icons.flag_outlined,
              color: active ? Colors.white : const Color(0xFFB2B7C1),
              size: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: active ? AppColors.primary : const Color(0xFFB2B7C1),
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackerLine extends StatelessWidget {
  const _TrackerLine({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: active ? const Color(0xFF8B6200) : const Color(0xFFE0E4EA),
      ),
    );
  }
}

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text(context.l10n.homeHistorySubtitle));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n.homeHistoryTitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE3E8F1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _statusFilter = value);
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text(context.l10n.historyFilterAll),
                      ),
                      DropdownMenuItem(
                        value: 'requested',
                        child: Text(context.l10n.historyFilterRequested),
                      ),
                      DropdownMenuItem(
                        value: 'accepted',
                        child: Text(context.l10n.historyFilterAccepted),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text(context.l10n.historyFilterCancelled),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('service_requests')
                  .where('uid', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final docs = [...(snapshot.data?.docs ?? [])];
                docs.sort((a, b) {
                  final aTs = (a.data()['createdAt'] as Timestamp?);
                  final bTs = (b.data()['createdAt'] as Timestamp?);
                  if (aTs == null && bTs == null) return 0;
                  if (aTs == null) return 1;
                  if (bTs == null) return -1;
                  return bTs.compareTo(aTs);
                });

                final filtered = docs.where((doc) {
                  if (_statusFilter == 'all') return true;
                  return (doc.data()['status'] ?? '') == _statusFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      context.l10n.historyNoRecords,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6A707B),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final data = filtered[index].data();
                    final createdAt = data['createdAt'] as Timestamp?;
                    final dateLabel = createdAt == null
                        ? '-'
                        : DateFormat('dd MMM yyyy • hh:mm a').format(
                            createdAt.toDate(),
                          );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE4E9F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data['mechanicName'] ?? '-'} • ${data['status'] ?? '-'}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${data['issueType'] ?? '-'} • ${data['locationName'] ?? '-'}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5B6270),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            dateLabel,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9AA1AE),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({
    required this.isLoggingOut,
    required this.onLogout,
  });

  final bool isLoggingOut;
  final VoidCallback onLogout;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final List<Map<String, String>> _vehicles = [];
  String _profilePhotoUrl = '';
  String _email = '';
  bool _saving = false;
  bool _uploadingPhoto = false;
  String _lastHydratedSignature = '';
  bool _hydratedOnce = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _safeTrim(String? value) => (value ?? '').trim();

  List<Map<String, String>> _extractVehiclesFromData(
      Map<String, dynamic> data) {
    final result = <Map<String, String>>[];
    final cars = (data['cars'] as List?)?.whereType<Map>().toList() ?? [];

    if (cars.isNotEmpty) {
      for (final rawCar in cars) {
        result.add({
          'type': (rawCar['type'] ?? '').toString(),
          'model': (rawCar['model'] ?? '').toString(),
          'number': (rawCar['number'] ?? '').toString(),
          'color': (rawCar['color'] ?? '').toString(),
          'year': (rawCar['year'] ?? '').toString(),
          'manufacturer': (rawCar['manufacturer'] ?? '').toString(),
        });
      }
    } else {
      final vehicle = (data['vehicle'] as Map?) ?? {};
      final parsedVehicle = {
        'type': (vehicle['type'] ?? '').toString(),
        'model': (vehicle['model'] ?? '').toString(),
        'number': (vehicle['number'] ?? '').toString(),
        'color': (vehicle['color'] ?? '').toString(),
        'year': (vehicle['year'] ?? '').toString(),
        'manufacturer': (vehicle['manufacturer'] ?? '').toString(),
      };
      final hasVehicleData = parsedVehicle.values.any(
        (value) => value.trim().isNotEmpty,
      );
      if (hasVehicleData) {
        result.add(parsedVehicle);
      }
    }

    return result.where((vehicle) {
      return _safeTrim(vehicle['model']).isNotEmpty ||
          _safeTrim(vehicle['number']).isNotEmpty ||
          _safeTrim(vehicle['color']).isNotEmpty ||
          _safeTrim(vehicle['year']).isNotEmpty ||
          _safeTrim(vehicle['manufacturer']).isNotEmpty ||
          _safeTrim(vehicle['type']).isNotEmpty;
    }).toList();
  }

  List<Map<String, String>> _normalizedVehicles(
      List<Map<String, String>> source) {
    return source
        .map(
          (v) => {
            'type': _safeTrim(v['type']),
            'model': _safeTrim(v['model']),
            'number': _safeTrim(v['number']),
            'color': _safeTrim(v['color']),
            'year': _safeTrim(v['year']),
            'manufacturer': _safeTrim(v['manufacturer']),
          },
        )
        .where((v) => v.values.any((value) => value.isNotEmpty))
        .toList();
  }

  String _signatureFromState({
    required String fullName,
    required String age,
    required String phone,
    required String profilePhotoUrl,
    required String email,
    required List<Map<String, String>> vehicles,
  }) {
    return jsonEncode({
      'fullName': _safeTrim(fullName),
      'age': _safeTrim(age),
      'phone': _safeTrim(phone),
      'profilePhotoUrl': _safeTrim(profilePhotoUrl),
      'email': _safeTrim(email),
      'vehicles': _normalizedVehicles(vehicles),
    });
  }

  String _localSignature() {
    return _signatureFromState(
      fullName: _nameController.text,
      age: _ageController.text,
      phone: _phoneController.text,
      profilePhotoUrl: _profilePhotoUrl,
      email: _email,
      vehicles: _vehicles,
    );
  }

  String _remoteSignature({
    required Map<String, dynamic> data,
    required User user,
  }) {
    return _signatureFromState(
      fullName: (data['fullName'] ?? user.displayName ?? '').toString(),
      age: (data['age'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      profilePhotoUrl:
          (data['profilePhotoUrl'] ?? user.photoURL ?? '').toString(),
      email: (data['email'] ?? user.email ?? '').toString(),
      vehicles: _extractVehiclesFromData(data),
    );
  }

  void _applyHydrationFromDoc({
    required Map<String, dynamic> data,
    required User user,
    required String remoteSignature,
  }) {
    _nameController.text =
        (data['fullName'] ?? user.displayName ?? '').toString();
    _ageController.text = (data['age'] ?? '').toString();
    _phoneController.text = (data['phone'] ?? '').toString();
    _profilePhotoUrl =
        (data['profilePhotoUrl'] ?? user.photoURL ?? '').toString();
    _email = (data['email'] ?? user.email ?? '').toString();

    _vehicles.clear();
    _vehicles.addAll(_extractVehiclesFromData(data));
    _lastHydratedSignature = remoteSignature;
    _hydratedOnce = true;
  }

  void _syncFromDocSafely({
    required Map<String, dynamic> data,
    required User user,
  }) {
    final remoteSignature = _remoteSignature(data: data, user: user);
    final localSignature = _localSignature();
    final hasLocalUnsavedChanges =
        _hydratedOnce && _lastHydratedSignature != localSignature;

    if (hasLocalUnsavedChanges) return;
    if (_hydratedOnce && remoteSignature == _lastHydratedSignature) return;
    _applyHydrationFromDoc(
      data: data,
      user: user,
      remoteSignature: remoteSignature,
    );
  }

  void _showToast(String message) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFF0C2E73),
      textColor: Colors.white,
      fontSize: 14,
    );
  }

  List<String> _storageBucketCandidates() {
    final raw = _safeTrim(Firebase.app().options.storageBucket);
    if (raw.isEmpty) return const [];

    String normalizeToGs(String value) {
      if (value.startsWith('gs://')) return value;
      return 'gs://$value';
    }

    final candidates = <String>{normalizeToGs(raw)};
    final withoutGs = raw.startsWith('gs://') ? raw.substring(5) : raw;
    if (withoutGs.endsWith('.firebasestorage.app')) {
      candidates.add(
        normalizeToGs(
          withoutGs.replaceFirst('.firebasestorage.app', '.appspot.com'),
        ),
      );
    }
    if (withoutGs.endsWith('.appspot.com')) {
      candidates.add(
        normalizeToGs(
          withoutGs.replaceFirst('.appspot.com', '.firebasestorage.app'),
        ),
      );
    }
    return candidates.toList();
  }

  int _profileScore() {
    var score = 72;
    if (_safeTrim(_nameController.text).isNotEmpty) score += 8;
    if (_safeTrim(_ageController.text).isNotEmpty) score += 5;
    if (_safeTrim(_phoneController.text).isNotEmpty) score += 5;
    if (_safeTrim(_profilePhotoUrl).isNotEmpty) score += 5;

    for (final vehicle in _vehicles) {
      final hasModel = _safeTrim(vehicle['model']).isNotEmpty;
      final hasNumber = _safeTrim(vehicle['number']).isNotEmpty;
      if (hasModel && hasNumber) {
        score += 3;
      }
    }

    return score.clamp(70, 98);
  }

  String _memberSinceYear(User user, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      return createdAt.toDate().year.toString();
    }
    final year = user.metadata.creationTime?.year.toString();
    if (year == null || year.isEmpty) {
      return DateTime.now().year.toString();
    }
    return year;
  }

  Future<void> _openContactEditSheet() async {
    final nameController = TextEditingController(text: _nameController.text);
    final ageController = TextEditingController(text: _ageController.text);
    final phoneController = TextEditingController(text: _phoneController.text);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              14 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.profileContactEditTitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: context.l10n.createAccountFullName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.l10n.profileAgeLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: context.l10n.profilePhoneLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(context.l10n.profileContactSaveButton),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    final updatedName = nameController.text.trim();
    final updatedAge = ageController.text.trim();
    final updatedPhone = phoneController.text.trim();

    if (saved == true && mounted) {
      setState(() {
        _nameController.text = updatedName;
        _ageController.text = updatedAge;
        _phoneController.text = updatedPhone;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _uploadingPhoto) return;

    setState(() => _uploadingPhoto = true);

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (picked == null) {
        setState(() => _uploadingPhoto = false);
        return;
      }

      final bucketCandidates = _storageBucketCandidates();
      if (bucketCandidates.isEmpty) {
        throw FirebaseException(
          plugin: 'firebase_storage',
          code: 'bucket-not-configured',
          message: 'Firebase Storage bucket is missing in app config.',
        );
      }

      final file = File(picked.path);
      final objectPath =
          'profile_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      String? imageUrl;
      FirebaseException? lastError;

      for (final bucket in bucketCandidates) {
        try {
          final storage = FirebaseStorage.instanceFor(bucket: bucket);
          final ref = storage.ref().child(objectPath);
          await ref.putFile(file);
          imageUrl = await ref.getDownloadURL();
          break;
        } on FirebaseException catch (e) {
          lastError = e;
          final retriableBucketMismatch =
              e.code == 'object-not-found' || e.code == 'bucket-not-found';
          if (!retriableBucketMismatch) {
            rethrow;
          }
        }
      }

      if (imageUrl == null) {
        throw lastError ??
            FirebaseException(
              plugin: 'firebase_storage',
              code: 'upload-failed',
              message: 'Image upload failed.',
            );
      }
      final uploadedImageUrl = imageUrl;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'profilePhotoUrl': uploadedImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user.updatePhotoURL(uploadedImageUrl);

      if (!mounted) return;
      setState(() => _profilePhotoUrl = uploadedImageUrl);
      _showToast(context.l10n.profileImageUploadSuccess);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showToast(
        '${context.l10n.profileImageUploadError} (${e.message ?? e.code})',
      );
    } catch (_) {
      if (!mounted) return;
      _showToast(context.l10n.profileImageUploadError);
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  Future<void> _openVehicleSheet({int? editIndex}) async {
    final isEdit = editIndex != null;
    final initial = isEdit
        ? _vehicles[editIndex]
        : {
            'type': 'car',
            'model': '',
            'number': '',
            'color': '',
            'year': '',
            'manufacturer': '',
          };

    var selectedType =
        _safeTrim(initial['type']).isEmpty ? 'car' : _safeTrim(initial['type']);

    final modelController = TextEditingController(text: initial['model']);
    final numberController = TextEditingController(text: initial['number']);
    final colorController = TextEditingController(text: initial['color']);
    final yearController = TextEditingController(text: initial['year']);
    final manufacturerController =
        TextEditingController(text: initial['manufacturer']);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  14 + MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit
                            ? context.l10n.profileVehicleEditTitle
                            : context.l10n.profileVehicleAddTitle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        items: [
                          DropdownMenuItem(
                            value: 'car',
                            child:
                                Text(context.l10n.createAccountVehicleTypeCar),
                          ),
                          DropdownMenuItem(
                            value: 'bike',
                            child:
                                Text(context.l10n.createAccountVehicleTypeBike),
                          ),
                          DropdownMenuItem(
                            value: 'van',
                            child:
                                Text(context.l10n.createAccountVehicleTypeVan),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => selectedType = value);
                        },
                        decoration: InputDecoration(
                          labelText: context.l10n.createAccountVehicleType,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: modelController,
                        decoration: InputDecoration(
                          labelText: context.l10n.createAccountVehicleModel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: numberController,
                        decoration: InputDecoration(
                          labelText: context.l10n.createAccountVehicleNumber,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: colorController,
                        decoration: InputDecoration(
                          labelText: context.l10n.createAccountVehicleColor,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: yearController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: context.l10n.createAccountVehicleYear,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: manufacturerController,
                        decoration: InputDecoration(
                          labelText:
                              context.l10n.createAccountVehicleManufacturer,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (modelController.text.trim().isEmpty ||
                                numberController.text.trim().isEmpty) {
                              _showToast(context.l10n.profileVehicleValidation);
                              return;
                            }

                            final updated = {
                              'type': selectedType.trim(),
                              'model': modelController.text.trim(),
                              'number': numberController.text.trim(),
                              'color': colorController.text.trim(),
                              'year': yearController.text.trim(),
                              'manufacturer':
                                  manufacturerController.text.trim(),
                            };

                            if (isEdit) {
                              _vehicles[editIndex] = updated;
                            } else {
                              _vehicles.add(updated);
                            }
                            Navigator.of(sheetContext).pop(true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(context.l10n.profileVehicleSaveButton),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _saving) return;

    setState(() => _saving = true);

    try {
      final normalizedCars = _vehicles.where((car) {
        return _safeTrim(car['model']).isNotEmpty ||
            _safeTrim(car['number']).isNotEmpty;
      }).toList();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profilePhotoUrl': _profilePhotoUrl.trim(),
        'cars': normalizedCars,
        if (normalizedCars.isNotEmpty) 'vehicle': normalizedCars.first,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      _lastHydratedSignature = _localSignature();
      _hydratedOnce = true;
      _showToast(context.l10n.profileSaveSuccess);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showToast('${context.l10n.profileSaveError} (${e.message ?? e.code})');
    } catch (_) {
      if (!mounted) return;
      _showToast(context.l10n.profileSaveError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _contactTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final trimmedValue = value.trim();
    final isMissing = trimmedValue.isEmpty;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F5FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF8D96A5), size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Color(0xFF8D96A5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isMissing ? context.l10n.profileNaValue : trimmedValue,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              if (isMissing) ...[
                const SizedBox(height: 2),
                Text(
                  context.l10n.profilePleaseUpdate,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD06C1D),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _vehicleDetailItem({
    required String label,
    required String value,
  }) {
    final displayValue =
        value.trim().isEmpty ? context.l10n.profileNaValue : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8D96A5),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text(context.l10n.homeProfileSubtitle));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final isFetchingProfile =
            snapshot.connectionState == ConnectionState.waiting &&
                !_hydratedOnce;
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        _syncFromDocSafely(data: data, user: user);

        final score = _profileScore();
        final displayName = _safeTrim(_nameController.text).isEmpty
            ? context.l10n.homeProfileTitle
            : _safeTrim(_nameController.text);
        final memberSince = _memberSinceYear(user, data);
        final profileImageUrl = _safeTrim(_profilePhotoUrl);
        final emailValue = _safeTrim(_email);
        final phoneValue = _safeTrim(_phoneController.text);
        final ageValue = _safeTrim(_ageController.text);
        final hasUnsavedChanges =
            _hydratedOnce && _localSignature() != _lastHydratedSignature;
        final showLoader = isFetchingProfile || _saving || _uploadingPhoto;

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).maybePop();
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.homeProfileTitle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        context.l10n.requestDetailsAppTitle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFFEAF0FF),
                        backgroundImage: profileImageUrl.isEmpty
                            ? null
                            : NetworkImage(profileImageUrl),
                        child: profileImageUrl.isEmpty
                            ? const Icon(
                                Icons.person_rounded,
                                color: AppColors.primary,
                                size: 16,
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE4E9F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x11000D2C),
                          blurRadius: 14,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: const Color(0xFFEAF0FF),
                            image: profileImageUrl.isEmpty
                                ? null
                                : DecorationImage(
                                    image: NetworkImage(profileImageUrl),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          child: profileImageUrl.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primary,
                                  size: 40,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                context.l10n.profileMemberType,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _TagChip(text: context.l10n.profileVerified),
                                  _TagChip(
                                    text: context.l10n
                                        .profileSinceYear(memberSince),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0A3A86), Color(0xFF002E6E)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          context.l10n.profileSafetyScoreTitle,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDDE8FF),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$score',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 50,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 4,
                          width: double.infinity,
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        context.l10n.profileContactSection,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _saving ? null : _openContactEditSheet,
                        child: Text(context.l10n.profileEditButton),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE4E9F0)),
                    ),
                    child: Column(
                      children: [
                        _contactTile(
                          icon: Icons.email_outlined,
                          label: context.l10n.profileEmailLabel,
                          value: emailValue,
                        ),
                        const SizedBox(height: 10),
                        _contactTile(
                          icon: Icons.phone_outlined,
                          label: context.l10n.profilePhoneLabel,
                          value: phoneValue,
                        ),
                        const SizedBox(height: 10),
                        _contactTile(
                          icon: Icons.cake_outlined,
                          label: context.l10n.profileAgeLabel,
                          value: ageValue,
                        ),
                        if (_uploadingPhoto) ...[
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.profileImageUploading,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        context.l10n.profileFleetSection,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _saving ? null : () => _openVehicleSheet(),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(context.l10n.profileAddVehicleShort),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._vehicles.asMap().entries.map((entry) {
                    final index = entry.key;
                    final vehicle = entry.value;

                    final model = _safeTrim(vehicle['model']);
                    final number = _safeTrim(vehicle['number']);
                    final color = _safeTrim(vehicle['color']);
                    final year = _safeTrim(vehicle['year']);
                    final manufacturer = _safeTrim(vehicle['manufacturer']);
                    final type = _safeTrim(vehicle['type']);

                    final vehicleTitle = model.isNotEmpty
                        ? model
                        : (manufacturer.isNotEmpty
                            ? manufacturer
                            : (number.isNotEmpty
                                ? number
                                : context.l10n.profileVehicleUntitled));

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE4E9F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  vehicleTitle,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _saving
                                    ? null
                                    : () => _openVehicleSheet(editIndex: index),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: Color(0xFF8D96A5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          _vehicleDetailItem(
                            label: context.l10n.profileVehicleLabelModel,
                            value: model,
                          ),
                          _vehicleDetailItem(
                            label: context.l10n.profileVehicleLabelManufacturer,
                            value: manufacturer,
                          ),
                          _vehicleDetailItem(
                            label: context.l10n.profileVehicleLabelColor,
                            value: color,
                          ),
                          _vehicleDetailItem(
                            label: context.l10n.profileVehicleLabelNumber,
                            value: number,
                          ),
                          _vehicleDetailItem(
                            label: context.l10n.profileVehicleLabelType,
                            value: type,
                          ),
                          _vehicleDetailItem(
                            label: context.l10n.profileVehicleLabelYear,
                            value: year,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF7F6400),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.l10n.profileVehicleInsured,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF7F6400),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  if (_vehicles.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE4E9F0)),
                      ),
                      child: Text(
                        context.l10n.profileNoVehicles,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6A707B),
                        ),
                      ),
                    ),
                  if (hasUnsavedChanges) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _saving
                              ? context.l10n.commonSaving
                              : context.l10n.profileSaveButton,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showLoader) const BlueLoaderOverlay(),
          ],
        );
      },
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}

class _MechanicCard extends StatelessWidget {
  const _MechanicCard({
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2330),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
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
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.item,
    required this.onTap,
  });

  final _ServiceItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
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
    required this.type,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  final _ServiceType type;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
}

class _RequestMechanic {
  const _RequestMechanic({
    required this.id,
    required this.name,
    required this.vehicle,
    required this.plate,
    required this.rating,
    required this.phone,
    required this.etaMins,
    required this.services,
    required this.latOffset,
    required this.lngOffset,
  });

  final String id;
  final String name;
  final String vehicle;
  final String plate;
  final double rating;
  final String phone;
  final int etaMins;
  final Set<_ServiceType> services;
  final double latOffset;
  final double lngOffset;
}

class _Mechanic {
  const _Mechanic({
    required this.key,
    required this.rating,
    required this.distanceKm,
    required this.specialty,
    required this.avgPrice,
    required this.phone,
    required this.latOffset,
    required this.lngOffset,
  });

  final String key;
  final double rating;
  final double distanceKm;
  final String specialty;
  final String avgPrice;
  final String phone;
  final double latOffset;
  final double lngOffset;
}

enum _SortOption { distance, rating, name }

enum _RequestStage { none, requested, accepted }

enum _HomeMenuAction { profile, contactUs, logout }

enum _ServiceType { mechanic, puncture, battery, towing, fuel, accident }

enum _RequestIssueType { engine, flatTire, deadBattery, other }
