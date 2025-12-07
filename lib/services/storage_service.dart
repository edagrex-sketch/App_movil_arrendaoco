import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final _supabase = Supabase.instance.client;

  Future<String?> uploadPropertyImage({
    required String propertyId,
    required XFile imageFile,
    required int index,
  }) async {
    try {
      final file = File(imageFile.path);
      final fileExt = p.extension(imageFile.path);
      final fileName =
          'property_${propertyId}_${DateTime.now().millisecondsSinceEpoch}_$index$fileExt';
      final storagePath = '$propertyId/$fileName';

      // Subir a Supabase Storage bucket 'inmuebles'
      await _supabase.storage
          .from('inmuebles')
          .upload(
            storagePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Obtener URL pública
      final imageUrl = _supabase.storage
          .from('inmuebles')
          .getPublicUrl(storagePath);
      print('☁️ [Supabase Storage] Imagen subida: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('🔴 [Supabase Storage] Error al subir imagen: $e');
      throw e;
    }
  }

  Future<List<String>> uploadPropertyImages({
    required String propertyId,
    required List<XFile> imageFiles,
  }) async {
    List<String> urls = [];
    Object? lastError;

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final url = await uploadPropertyImage(
          propertyId: propertyId,
          imageFile: imageFiles[i],
          index: i,
        );
        if (url != null) {
          urls.add(url);
        }
      } catch (e) {
        print('⚠️ Error subiendo imagen $i: $e');
        lastError = e;
      }
    }

    if (urls.isEmpty && imageFiles.isNotEmpty && lastError != null) {
      throw lastError;
    }

    return urls;
  }

  // Guardar foto de perfil
  Future<String?> uploadProfilePhoto({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final fileExt = p.extension(imageFile.path);
      final fileName =
          'profile_$userId$fileExt'; // Sobreescribir foto anterior si existe
      final storagePath = 'profiles/$fileName';

      await _supabase.storage
          .from('inmuebles')
          .upload(
            storagePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final imageUrl = _supabase.storage
          .from('inmuebles')
          .getPublicUrl(storagePath);
      return imageUrl;
    } catch (e) {
      print('Error al subir foto de perfil: $e');
      return null;
    }
  }

  // Eliminar imagen (Si recibimos la URL completa, necesitamos extraer el path)
  Future<bool> deletePropertyImage(String imageUrl) async {
    try {
      // Extraer path relativo del URL.
      // URL típica: https://PROJECT.supabase.co/storage/v1/object/public/inmuebles/FOLDER/FILE.jpg
      // Queremos: FOLDER/FILE.jpg

      final Uri uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      // segments: [storage, v1, object, public, inmuebles, FOLDER, FILE.jpg]
      // Index of 'inmuebles' (bucket name)
      final bucketIndex = segments.indexOf('inmuebles');
      if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) return false;

      final path = segments.sublist(bucketIndex + 1).join('/');

      await _supabase.storage.from('inmuebles').remove([path]);
      return true;
    } catch (e) {
      print('Error al eliminar imagen remota: $e');
      return false;
    }
  }

  // Eliminar todas las imágenes de un inmueble (carpeta)
  // Supabase no elimina carpetas explícitamente, elimina archivos.
  // Pero podemos listar archivos en un prefix y borrarlos.
  Future<bool> deletePropertyImages(String propertyId) async {
    try {
      final List<FileObject> objects = await _supabase.storage
          .from('inmuebles')
          .list(path: propertyId);

      if (objects.isEmpty) return true;

      final paths = objects.map((obj) => '$propertyId/${obj.name}').toList();
      await _supabase.storage.from('inmuebles').remove(paths);

      return true;
    } catch (e) {
      print('Error al eliminar carpeta remota: $e');
      return false;
    }
  }
}
