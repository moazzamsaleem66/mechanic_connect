import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.mechanicDetails,
  });

  static const String routeName = '/map-screen';

  final MechanicMapDetails? mechanicDetails;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _defaultLocation = LatLng(33.6844, 73.0479);

  GoogleMapController? _controller;
  StreamSubscription<Position>? _positionSubscription;
  LatLng _currentLocation = _defaultLocation;
  String _currentLocationText = '';
  bool _isLoading = true;
  bool _permissionGranted = false;
  int _resolveToken = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_initLiveLocation());
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initLiveLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _permissionGranted = false;
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
            _isLoading = false;
            _permissionGranted = false;
            _currentLocationText = '';
          });
        }
        return;
      }

      final initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      if (!mounted) return;
      final initialLatLng = LatLng(
        initialPosition.latitude,
        initialPosition.longitude,
      );

      setState(() {
        _currentLocation = initialLatLng;
        _currentLocationText = _formatLocationText(initialLatLng);
        _isLoading = false;
        _permissionGranted = true;
      });
      unawaited(
        _resolveLocationName(
          latitude: initialLatLng.latitude,
          longitude: initialLatLng.longitude,
        ),
      );

      await _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: widget.mechanicDetails?.location ?? initialLatLng,
            zoom: 16,
          ),
        ),
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 8,
        ),
      ).listen((position) {
        if (!mounted) return;
        final next = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentLocation = next;
          _currentLocationText = _formatLocationText(next);
        });
        unawaited(
          _resolveLocationName(
            latitude: next.latitude,
            longitude: next.longitude,
          ),
        );
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _permissionGranted = false;
          _currentLocationText = '';
        });
      }
    }
  }

  String _formatLocationText(LatLng position) {
    return '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
  }

  Future<void> _resolveLocationName({
    required double latitude,
    required double longitude,
  }) async {
    final token = ++_resolveToken;
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (!mounted || token != _resolveToken || placemarks.isEmpty) return;
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
      setState(() => _currentLocationText = label);
    } catch (_) {}
  }

  Future<void> _callMechanic() async {
    final phone = widget.mechanicDetails?.phone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  Future<void> _recenter() async {
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentLocation, zoom: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationText = _currentLocationText.isEmpty
        ? context.l10n.homeCurrentLocationFallback
        : _currentLocationText;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Text(
          context.l10n.homeMapScreenTitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLocation,
                  zoom: 15.5,
                ),
                onMapCreated: (controller) => _controller = controller,
                myLocationEnabled: _permissionGranted,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                markers: {
                  Marker(
                    markerId: const MarkerId('live-location'),
                    position: _currentLocation,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue,
                    ),
                    infoWindow: InfoWindow(
                      title: context.l10n.homeMapLiveMarkerTitle,
                    ),
                  ),
                  if (widget.mechanicDetails != null)
                    Marker(
                      markerId: const MarkerId('mechanic-focused'),
                      position: widget.mechanicDetails!.location,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange,
                      ),
                      infoWindow: InfoWindow(
                        title: widget.mechanicDetails!.name,
                      ),
                    ),
                },
                circles: {
                  Circle(
                    circleId: const CircleId('live-location-accuracy'),
                    center: _currentLocation,
                    radius: 28,
                    fillColor: const Color(0x663E7DFF),
                    strokeColor: const Color(0xAA3E7DFF),
                    strokeWidth: 1,
                  ),
                },
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 74,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1800112E),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.my_location_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          locationText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.68),
                    alignment: Alignment.center,
                    child: Text(
                      context.l10n.homeMapLoading,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              if (!_isLoading && !_permissionGranted)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.84),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_off_rounded,
                          size: 42,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.homeMapPermissionNeeded,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _initLiveLocation,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(context.l10n.homeMapRetry),
                        ),
                      ],
                    ),
                  ),
                ),
              if (widget.mechanicDetails != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2200112E),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.mechanicDetails!.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.mechanicDetails!.specialty,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5F6674),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '⭐ ${widget.mechanicDetails!.rating.toStringAsFixed(1)} • Avg ${widget.mechanicDetails!.avgPrice}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5F6674),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: _callMechanic,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.call_rounded),
                            label: Text(
                              widget.mechanicDetails!.phone,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _recenter,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.my_location_rounded, color: Colors.white),
      ),
    );
  }
}

class MechanicMapDetails {
  const MechanicMapDetails({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.avgPrice,
    required this.phone,
    required this.location,
  });

  final String name;
  final String specialty;
  final double rating;
  final String avgPrice;
  final String phone;
  final LatLng location;
}
