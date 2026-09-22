class Track {
  Track({
    required this.id,
    required this.title,
    this.thumbnail,
    this.duration,
    this.uploader,
  });

  final String id;
  final String title;
  final String? thumbnail;
  final int? duration;
  final String? uploader;

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Sin título',
        thumbnail: json['thumbnail'] as String?,
        duration: json['duration'] as int?,
        uploader: json['uploader'] as String?,
      );
}
