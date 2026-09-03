import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

class PickedAvatar {
  const PickedAvatar({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

Future<PickedAvatar?> pickAvatar() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = false;
  input.click();
  await input.onChange.first;
  final file = input.files?.first;
  if (file == null) return null;

  final reader = html.FileReader();
  reader.readAsDataUrl(file);
  await reader.onLoadEnd.first;
  final result = reader.result;
  if (result is String && result.contains(',')) {
    return PickedAvatar(
      bytes: Uint8List.fromList(base64Decode(result.split(',').last)),
      filename: file.name,
    );
  }
  return null;
}
