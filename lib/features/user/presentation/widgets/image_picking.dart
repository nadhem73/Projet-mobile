import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medilink/core/theme/app_colors.dart';

/// Choix fait dans la feuille de sélection d'image.
sealed class ImageChoice {
  const ImageChoice();
}

class PickedImage extends ImageChoice {
  const PickedImage(this.bytes);
  final Uint8List bytes;
}

class RemoveImage extends ImageChoice {
  const RemoveImage();
}

/// Propose Galerie / Appareil photo (et « Supprimer » si [allowRemove]),
/// puis renvoie l'image redimensionnée et compressée en JPEG.
Future<ImageChoice?> pickImage(
  BuildContext context, {
  double maxWidth = 1600,
  int quality = 80,
  bool allowRemove = false,
  String title = 'Ajouter une image',
}) async {
  final source = await showModalBottomSheet<Object>(
    context: context,
    showDragHandle: true,
    builder:
        (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choisir dans la galerie'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Prendre une photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              if (allowRemove)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  title: const Text('Supprimer la photo', style: TextStyle(color: AppColors.error)),
                  onTap: () => Navigator.pop(context, const RemoveImage()),
                ),
            ],
          ),
        ),
  );
  if (source is RemoveImage) return source;
  if (source is! ImageSource) return null;

  final file = await ImagePicker().pickImage(source: source, maxWidth: maxWidth, imageQuality: quality);
  if (file == null) return null;
  return PickedImage(await file.readAsBytes());
}
