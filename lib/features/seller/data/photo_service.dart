import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models.dart';
import '../../../core/supabase_providers.dart';

/// Handles client-side compression + upload of device photos into the
/// device-photos bucket under shop_{shopId}/device_{deviceId}/.
class PhotoService {
  PhotoService(this._client);

  final SupabaseClient _client;
  final ImagePicker _picker = ImagePicker();

  static const int maxBytes = 1024 * 1024; // 1MB target.

  Future<List<XFile>> pickImages() =>
      _picker.pickMultiImage(imageQuality: 100);

  /// Compresses to WebP under ~1MB, stepping quality/size down until it fits.
  Future<Uint8List> compress(XFile file) async {
    final original = await file.readAsBytes();
    if (original.lengthInBytes <= maxBytes) {
      final once = await FlutterImageCompress.compressWithList(
        original,
        quality: 90,
        minWidth: 1600,
        minHeight: 1600,
        format: CompressFormat.webp,
      );
      return once.lengthInBytes < original.lengthInBytes ? once : original;
    }

    var quality = 85;
    var dimension = 1600;
    Uint8List result = original;
    for (var attempt = 0; attempt < 5; attempt++) {
      result = await FlutterImageCompress.compressWithList(
        original,
        quality: quality,
        minWidth: dimension,
        minHeight: dimension,
        format: CompressFormat.webp,
      );
      if (result.lengthInBytes <= maxBytes) break;
      quality = (quality - 15).clamp(40, 90);
      dimension = (dimension * 0.8).round();
    }
    return result;
  }

  Future<DevicePhoto> uploadPhoto({
    required int shopId,
    required int deviceId,
    required XFile file,
    required int sortOrder,
  }) async {
    final bytes = await compress(file);
    final name =
        '${DateTime.now().microsecondsSinceEpoch}_$sortOrder.webp';
    final path = 'shop_$shopId/device_$deviceId/$name';
    await _client.storage.from('device-photos').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/webp'),
        );
    final row = await _client
        .from('device_photos')
        .insert({
          'device_id': deviceId,
          'storage_path': path,
          'sort_order': sortOrder,
        })
        .select('id, device_id, storage_path, sort_order')
        .single();
    return DevicePhoto.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> softDelete(int photoId) async {
    await _client
        .from('device_photos')
        .update({'is_deleted': true}).eq('id', photoId);
  }

  Future<void> reorder(List<DevicePhoto> ordered) async {
    for (var i = 0; i < ordered.length; i++) {
      if (ordered[i].sortOrder == i) continue;
      await _client
          .from('device_photos')
          .update({'sort_order': i}).eq('id', ordered[i].id);
    }
  }
}

final photoServiceProvider = Provider<PhotoService>(
  (ref) => PhotoService(ref.watch(supabaseClientProvider)),
);
