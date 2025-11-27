import 'package:geolocator/geolocator.dart';

/// Obtiene la ubicación actual del dispositivo, solicitando permisos si es necesario.
/// Devuelve un objeto Position con latitud y longitud.
/// Lanza una excepción si los permisos son denegados o el servicio está desactivado.
Future<Position> obtenerUbicacionActual() async {
  // Verifica que el servicio de ubicación esté activo
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Opcional: muestra un mensaje para que el usuario active la ubicación
    return Future.error('El servicio de ubicación está desactivado.');
  }

  // Verifica permisos
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Permiso de ubicación denegado.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error('Permiso de ubicación denegado permanentemente.');
  }

  // Accede a la ubicación actual
  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  return position;
}
