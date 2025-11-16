import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Update user location in Firestore
  Future<bool> updateUserLocation(String userId) async {
    try {
      final position = await getCurrentLocation();
      if (position == null) return false;

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'location': GeoPoint(position.latitude, position.longitude),
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating user location: $e');
      return false;
    }
  }

  /// Calculate distance between two GeoPoints in kilometers
  double calculateDistance(GeoPoint point1, GeoPoint point2) {
    return Geolocator.distanceBetween(
          point1.latitude,
          point1.longitude,
          point2.latitude,
          point2.longitude,
        ) /
        1000; // Convert meters to kilometers
  }

  /// Open app settings (for when permission is denied forever)
  Future<bool> openSettings() async {
    return await Geolocator.openAppSettings();
  }
}
