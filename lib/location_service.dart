import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ✅ Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error("❌ Location services are disabled.");
    }

    // ✅ Check location permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      // 🔴 If the user still denies permission, return an error
      if (permission == LocationPermission.denied) {
        return Future.error("❌ Location permission denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error("❌ Location permissions are permanently denied.");
    }

    // ✅ Get current GPS location with high accuracy
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
