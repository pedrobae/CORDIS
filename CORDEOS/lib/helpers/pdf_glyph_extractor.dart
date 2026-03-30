// ignore_for_file: implementation_imports

import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdf/src/pdf/implementation/exporting/pdf_text_extractor/image_renderer.dart';
import 'package:syncfusion_flutter_pdf/src/pdf/implementation/exporting/pdf_text_extractor/page_resource_loader.dart';
import 'package:syncfusion_flutter_pdf/src/pdf/implementation/exporting/pdf_text_extractor/parser/content_parser.dart';
import 'package:syncfusion_flutter_pdf/src/pdf/implementation/exporting/pdf_text_extractor/text_glyph.dart';
import 'package:syncfusion_flutter_pdf/src/pdf/implementation/pages/pdf_page_layer_collection.dart';

/// Helper to extract all glyphs per page using Syncfusion internals.
class PdfGlyphExtractorHelper {
  /// Returns all glyphs for a page index. Glyphs include text and bounds.
  static List<TextGlyph> extractPageGlyphs(
    PdfDocument document,
    int pageIndex,
  ) {
    final PdfPage page = document.pages[pageIndex];
    // Load page resources.
    final resourceLoader = PageResourceLoader();
    final pageResources = resourceLoader.getPageResources(page);

    // Build record collection (same as the stock extractor).
    final recordCollection = _getRecordCollection(page);

    if (recordCollection == null) {
      return <TextGlyph>[];
    }

    // Render glyphs. Height multiplier matches Syncfusion internal usage.
    final renderer = ImageRenderer(
      recordCollection,
      pageResources,
      page.size.height * 1.3333333333333333,
    );
    renderer.pageRotation = page.rotation.index * 90;
    renderer.isExtractLineCollection = true;
    renderer.renderAsImage();
    renderer.isExtractLineCollection = false;

    // Map renderer glyphs to TextGlyph for consistency with the rest of the codebase.
    return renderer.imageRenderGlyphList.map((g) {
      return TextGlyphHelper.initialize(
        (g.name == '') ? g.toUnicode : g.name,
        g.fontFamily,
        g.fontStyle,
        g.boundingRect,
        g.fontSize,
        g.isRotated,
      );
    }).toList();
  }
}

PdfRecordCollection? _getRecordCollection(PdfPage page) {
  PdfRecordCollection? recordCollection;
  List<int>? combinedData = PdfPageLayerCollectionHelper.getHelper(
    page.layers,
  ).combineContent(true);
  if (combinedData != null) {
    final ContentParser parser = ContentParser(combinedData);
    parser.isTextExtractionProcess = true;
    recordCollection = parser.readContent();
    parser.isTextExtractionProcess = false;
    combinedData.clear();
  }
  combinedData = null;
  return recordCollection;
}
