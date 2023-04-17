import 'package:flutter/foundation.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class PdfHandler {
  static Future<String> getPDFromHtml(Delta delta, String docId) async {
    final list = <Map<String, dynamic>>[];
    for (final ele in delta.toList()) {
      list.add(
        {
          'insert': ele.data.toString(),
          'attributes': ele.attributes,
        },
      );
    }
    final html = QuillDeltaToHtmlConverter(list).convert();

    if (kIsWeb) {
      throw UnsupportedError('Operation not avaliable for web');
    } else {
      final directory = await getExternalStorageDirectory();
      final generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
        html,
        directory!.path,
        docId,
      );

      return generatedPdfFile.path;
    }
  }
}
