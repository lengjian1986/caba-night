import 'dart:typed_data';

class PickedAvatar {
  const PickedAvatar({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

Future<PickedAvatar?> pickAvatar() async => null;
