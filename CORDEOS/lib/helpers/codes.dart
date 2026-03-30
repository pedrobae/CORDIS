import 'dart:math';

/// Generates a unique 8-character alphanumeric code
String generateShareCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random.secure();
  return List.generate(
    8,
    (index) => chars[random.nextInt(chars.length)],
  ).join();
}

String generateFirebaseId() {
  return DateTime.now().microsecondsSinceEpoch.toString();
}
