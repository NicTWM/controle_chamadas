// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void baixarArquivoWeb(List<int> bytes, String nomeArquivo) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', nomeArquivo)
    ..click();
  html.Url.revokeObjectUrl(url);
}