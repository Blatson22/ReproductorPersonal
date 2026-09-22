import 'package:flutter/material.dart';

import '../models/track.dart';
import '../theme/app_theme.dart';

/// Fila estándar para mostrar una canción en una lista (búsqueda,
/// favoritos, historial, recomendaciones).
class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
    this.trailing,
  });

  final Track track;
  final VoidCallback onTap;
  final Widget? trailing;

  String? get _durationLabel {
    final seconds = track.duration;
    if (seconds == null) return null;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: track.thumbnail != null
                  ? Image.network(
                      track.thumbnail!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (track.uploader != null) track.uploader!,
                      if (_durationLabel != null) _durationLabel!,
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 52,
        height: 52,
        color: AppColors.surfaceElevated,
        child: const Icon(Icons.music_note_rounded, color: AppColors.textSecondary, size: 22),
      );
}
