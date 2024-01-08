class Language {
  final String code;
  final String name;
  final String flagAsset; // New property to hold the flag asset path or URL
  bool isSelected;

  Language({
    required this.code,
    required this.name,
    required this.flagAsset,
    this.isSelected = false,
  });
}
