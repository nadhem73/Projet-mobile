import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Hologramme 3D du patient affiché dans la fiche de consultation :
/// corps masculin ou féminin selon le sexe du dossier médical ('M' / 'F').
class PatientHologram extends StatefulWidget {
  const PatientHologram({super.key, required this.gender, this.height = 320});

  /// Sexe du patient : 'M' ou 'F'.
  final String gender;
  final double height;

  static const _models = {'M': 'assets/models/holo/male.glb', 'F': 'assets/models/holo/female.glb'};

  /// Vrai si un modèle existe pour ce sexe.
  static bool supports(String? gender) => _models.containsKey(gender);

  /// La visionneuse 3D repose sur une WebView : Web, Android et iOS uniquement
  /// (pas sur desktop ni dans les tests, où une silhouette la remplace).
  static bool get _can3d {
    if (kIsWeb) return true;
    return (Platform.isAndroid || Platform.isIOS) && !Platform.environment.containsKey('FLUTTER_TEST');
  }

  @override
  State<PatientHologram> createState() => _PatientHologramState();
}

class _PatientHologramState extends State<PatientHologram> with SingleTickerProviderStateMixin {
  static const _maleTint = Color(0xFF4FB8FF); // bleu
  static const _femaleTint = Color(0xFFFF6FB5); // rose

  late final AnimationController _scan = AnimationController(vsync: this, duration: const Duration(seconds: 3))
    ..repeat();

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  bool get _isMale => widget.gender == 'M';

  /// Couleur de l'hologramme : bleu pour un homme, rose pour une femme.
  Color get _tint => _isMale ? _maleTint : _femaleTint;

  String get _viewerId => 'patient-holo-${widget.gender}';

  /// Composantes RGB de [_tint] entre 0 et 1, multipliées par [k].
  String _rgb([double k = 1]) => [_tint.r, _tint.g, _tint.b].map((c) => (c * k).toStringAsFixed(3)).join(', ');

  /// Remplace les textures du modèle par une surface translucide et lumineuse de la couleur [_tint].
  String get _hologramJs => '''
(() => {
  const mv = document.getElementById('$_viewerId');
  if (!mv) return;
  const apply = () => {
    if (!mv.model) return;
    for (const m of mv.model.materials) {
      try {
        const pbr = m.pbrMetallicRoughness;
        if (pbr.baseColorTexture) pbr.baseColorTexture.setTexture(null);
        if (m.emissiveTexture) m.emissiveTexture.setTexture(null);
        pbr.setBaseColorFactor([${_rgb()}, 0.6]);
        pbr.setMetallicFactor(0.2);
        pbr.setRoughnessFactor(0.6);
        m.setEmissiveFactor([${_rgb(0.55)}]);
        m.setAlphaMode('BLEND');
      } catch (e) {}
    }
  };
  mv.addEventListener('load', apply);
  if (mv.loaded) apply();
})();
''';

  Widget _viewer() => ModelViewer(
    key: ValueKey(widget.gender),
    id: _viewerId,
    src: PatientHologram._models[widget.gender]!,
    alt: _isMale ? 'Hologramme du corps masculin' : 'Hologramme du corps féminin',
    backgroundColor: Colors.transparent,
    autoRotate: true,
    autoRotateDelay: 0,
    rotationPerSecond: '25deg',
    cameraControls: true,
    disableZoom: true,
    disablePan: true,
    interactionPrompt: InteractionPrompt.none,
    exposure: 1.2,
    shadowIntensity: 0,
    relatedJs: _hologramJs,
  );

  /// Silhouette de secours quand la 3D n'est pas disponible.
  Widget _silhouette() => Center(
    child: Icon(
      _isMale ? Icons.man_rounded : Icons.woman_rounded,
      size: widget.height * 0.8,
      color: _tint.withValues(alpha: 0.7),
      shadows: [Shadow(color: _tint.withValues(alpha: 0.6), blurRadius: 24)],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: widget.height,
        // Fond aux couleurs de l'application (vert émeraude), halo central plus clair.
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 0.1),
            radius: 0.95,
            colors: [AppColors.primaryDark, AppColors.primaryDeep],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: PatientHologram._can3d ? _viewer() : _silhouette()),
            // Ligne de scan qui balaie le corps de haut en bas.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _scan,
                  builder:
                      (context, _) => Align(
                        alignment: Alignment(0, _scan.value * 2 - 1),
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: _tint.withValues(alpha: 0.8),
                            boxShadow: [BoxShadow(color: _tint.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 2)],
                          ),
                        ),
                      ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tint.withValues(alpha: 0.12),
                    border: Border.all(color: _tint.withValues(alpha: 0.6)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isMale ? '♂ Homme' : '♀ Femme',
                    style: TextStyle(color: _tint, fontWeight: FontWeight.w600),
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
