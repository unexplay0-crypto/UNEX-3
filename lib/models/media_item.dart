class MediaItem {
  const MediaItem({
    required this.name,
    required this.url,
    this.logo,
    this.group,
    this.tvgId,
    this.tvgName,
  });

  final String name;
  final String url;
  final String? logo;
  final String? group;
  final String? tvgId;
  final String? tvgName;

  String get stableId => '${tvgId ?? ''}|$name|$url';
}
