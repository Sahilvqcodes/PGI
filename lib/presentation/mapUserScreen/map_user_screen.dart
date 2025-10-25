// PgiMapScreen.dart
// Required packages in pubspec.yaml:
// google_maps_flutter, geolocator, http, get, translator

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../main.dart';

class PgiMapScreen extends StatefulWidget {
  const PgiMapScreen({super.key});

  @override
  State<PgiMapScreen> createState() => _PgiMapScreenState();
}

class _PgiMapScreenState extends State<PgiMapScreen> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  StreamSubscription<Position>? _positionStream;

  dynamic data = Get.arguments; // Firestore document data
  LatLng? userLatLng;
  LatLng? deptLatLng;

  bool _isNearDept = false;

  final String googleApiKey = ""; // replace with your key

  late String selectedLang;
  late String deptName;

  @override
  void initState() {
    super.initState();
    selectedLang = Get.locale?.languageCode ?? 'en';
    deptName = _getDeptName(data['departmentName']);
    _initEverything();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  String _getDeptName(dynamic nameField) {
    if (nameField is Map) {
      return nameField[selectedLang] ?? nameField['en'] ?? 'Department';
    } else if (nameField is String) {
      return nameField;
    } else {
      return 'Department';
    }
  }

  Future<void> _initEverything() async {
    try {
      // 1) Location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('Location', 'Please enable location services');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('Permission', 'Location permission denied');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        Get.snackbar('Permission', 'Location permission permanently denied');
        return;
      }

      // 2) Parse department location from Firestore string
      String locationStr =
          (data?['location'] as String?) ?? 'Lat:30.7090931, Lon:76.6889095';
      final regex = RegExp(r'Lat:\s*([-\d.]+),\s*Lon:\s*([-\d.]+)');
      final match = regex.firstMatch(locationStr);

      if (match != null) {
        double deptLat = double.parse(match.group(1)!);
        double deptLng = double.parse(match.group(2)!);
        deptLatLng = LatLng(deptLat, deptLng);
      } else {
        deptLatLng = LatLng(30.7090931, 76.6889095);
      }

      // 3) Get user current location
      Position pos =
      await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      userLatLng = LatLng(pos.latitude, pos.longitude);

      // 4) Add markers
      _setUserMarker(userLatLng!);
      _setDeptMarker(deptLatLng!, deptName);

      // 5) Draw route
      await _updateRoute();

      // 6) Fit camera
      _fitCameraToPoints();

      // 7) Listen for location updates continuously
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((Position newPos) async {
        final newLatLng = LatLng(newPos.latitude, newPos.longitude);
        userLatLng = newLatLng;
        _setUserMarker(userLatLng!);

        double distance = _distanceMeters(userLatLng!, deptLatLng!);

        if (distance < 5 && !_isNearDept) {
          _isNearDept = true;
          _polylines.clear();
          setState(() {});
          _controller?.animateCamera(
              CameraUpdate.newLatLngZoom(userLatLng!, 18));
        } else if (distance >= 5 && _isNearDept) {
          _isNearDept = false;
          await _updateRoute();
          _fitCameraToPoints();
          setState(() {});
        }
      });
    } catch (e) {
      print('Init error: $e');
      Get.snackbar('Error', 'Something went wrong: $e');
    } finally {
      setState(() {});
    }
  }

  void _setUserMarker(LatLng pos) {
    _markers.removeWhere((m) => m.markerId.value == 'userMarker');
    _markers.add(Marker(
      markerId: const MarkerId('userMarker'),
      position: pos,
      infoWindow: const InfoWindow(title: 'You'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ));
    setState(() {});
  }

  void _setDeptMarker(LatLng pos, String title) {
    _markers.removeWhere((m) => m.markerId.value == 'deptMarker');
    _markers.add(Marker(
      markerId: const MarkerId('deptMarker'),
      position: pos,
      infoWindow: InfoWindow(title: title),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));
    setState(() {});
  }

  double _distanceMeters(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);
  }

  Future<void> _updateRoute() async {
    if (userLatLng == null || deptLatLng == null) return;

    if (_distanceMeters(userLatLng!, deptLatLng!) < 5) {
      _polylines.clear();
      setState(() {});
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(userLatLng!, 18));
      return;
    }

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${userLatLng!.latitude},${userLatLng!.longitude}&destination=${deptLatLng!.latitude},${deptLatLng!.longitude}&mode=driving&key=$googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['routes'].isNotEmpty) {
        List<PointLatLng> points =
        _decodePolyline(data['routes'][0]['overview_polyline']['points']);
        List<LatLng> polylineCoords =
        points.map((p) => LatLng(p.latitude, p.longitude)).toList();

        _polylines.removeWhere((p) => p.polylineId.value == 'route');
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: polylineCoords,
          width: 5,
          color: Colors.blue,
        ));

        setState(() {});
        _fitCameraToPoints();
      }
    } catch (e) {
      print('Route error: $e');
    }
  }

  List<PointLatLng> _decodePolyline(String encoded) {
    List<PointLatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(PointLatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }

  void _fitCameraToPoints() {
    if (userLatLng == null || deptLatLng == null) return;
    double south = userLatLng!.latitude < deptLatLng!.latitude
        ? userLatLng!.latitude
        : deptLatLng!.latitude;
    double west = userLatLng!.longitude < deptLatLng!.longitude
        ? userLatLng!.longitude
        : deptLatLng!.longitude;
    double north = userLatLng!.latitude > deptLatLng!.latitude
        ? userLatLng!.latitude
        : deptLatLng!.latitude;
    double east = userLatLng!.longitude > deptLatLng!.longitude
        ? userLatLng!.longitude
        : deptLatLng!.longitude;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(deptName),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: pgiCenter, zoom: 17),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _controller = controller;
              _fitCameraToPoints();
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          if (_isNearDept)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'same_place_message'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (deptLatLng == null || userLatLng == null)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class PointLatLng {
  final double latitude;
  final double longitude;
  PointLatLng(this.latitude, this.longitude);
}
