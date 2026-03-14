import 'dart:io';
import 'package:image_picker/image_picker.dart';

class StorageService {
  // Eliminado: Supabase dependency

  Future<String?> uploadPropertyImage({
    required String propertyId,
    required XFile imageFile,
    required int index,
  }) async {
    // TODO: Implementar subida a Laravel API
    print('ℹ️ StorageService: Subida de imagen deshabilitada (Sin Supabase)');
    return null;
  }

  Future<List<String>> uploadPropertyImages({
    required String propertyId,
    required List<XFile> imageFiles,
  }) async {
    print('ℹ️ StorageService: Subida de imágenes deshabilitada (Sin Supabase)');
    return [];
  }

  // Guardar foto de perfil
  Future<String?> uploadProfilePhoto({
    required String userId,
    required File imageFile,
  }) async {
    print(
      'ℹ️ StorageService: Subida de foto de perfil deshabilitada (Sin Supabase)',
    );
    return null;
  }

  // Eliminar imagen
  Future<bool> deletePropertyImage(String imageUrl) async {
    print(
      'ℹ️ StorageService: Eliminación de imagen deshabilitada (Sin Supabase)',
    );
    return true;
  }

  // Eliminar todas las imágenes de un inmueble (carpeta)
  Future<bool> deletePropertyImages(String propertyId) async {
    print('ℹ️ StorageService: Eliminación masiva deshabilitada (Sin Supabase)');
    return true;
  }
}
