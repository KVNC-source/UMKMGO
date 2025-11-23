// lib/models/address.dart

class Address {
  final String id;
  final String label;
  final String street;
  final String city;
  final String phone;

  Address({
    required this.id,
    required this.label,
    required this.street,
    required this.city,
    required this.phone,
  });

  String get fullAddress => '$street, $city';

  // --- NEW: Convert from Firebase ---
  factory Address.fromMap(Map<String, dynamic> map, String documentId) {
    return Address(
      id: documentId,
      label: map['label'] ?? '',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      phone: map['phone'] ?? '',
    );
  }

  // --- NEW: Convert to Firebase ---
  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'street': street,
      'city': city,
      'phone': phone,
    };
  }
}