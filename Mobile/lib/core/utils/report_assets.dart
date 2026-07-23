class ReportContent {
  const ReportContent({required this.text, required this.imageUrls});

  final String text;
  final List<String> imageUrls;

  bool get hasImages => imageUrls.isNotEmpty;
}

class ReportAssetParser {
  static final RegExp _imagesBlockRegex = RegExp(
    r'\[IMAGENES\](.*?)\[/IMAGENES\]',
    dotAll: true,
  );

  static ReportContent parse(String? rawReport) {
    final report = rawReport?.trim() ?? '';
    if (report.isEmpty) {
      return const ReportContent(text: '', imageUrls: []);
    }

    final imageUrls = <String>[];
    final cleanedReport = report.replaceAllMapped(_imagesBlockRegex, (match) {
      final rawUrls = match.group(1) ?? '';
      imageUrls.addAll(
        rawUrls
            .split(',')
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty),
      );
      return '';
    });

    return ReportContent(
      text: _normalizeBlankLines(cleanedReport),
      imageUrls: List.unmodifiable(imageUrls),
    );
  }

  static String _normalizeBlankLines(String value) {
    return value.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }
}
