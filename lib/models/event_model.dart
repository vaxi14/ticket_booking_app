class Event {
  final String id;
  final String name;
  final String date;
  final String location;
  final String imageUrl;
  final double price;
  final String about;
  final List<Guest> guests;
  final bool hasSeatLayout; // Added hasSeatLayout field

  Event({
    required this.id,
    required this.name,
    required this.date,
    required this.location,
    required this.imageUrl,
    required this.price,
    required this.about,
    required this.guests,
    required this.hasSeatLayout, // Now correctly required
  });

  /// Convert Firestore document to Event object
  factory Event.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Event(
      id: documentId,
      name: data['name'] ?? 'Unknown',
      date: data['date'] ?? 'No Date',
      location: data['location'] ?? 'No Location',
      imageUrl: data['imageUrl'] ?? '',
      price: double.tryParse(data['price']?.toString() ?? '0.0') ?? 0.0,
      about: data['about'] ?? 'No description available.',
      guests: (data['guests'] as List<dynamic>?)
              ?.map((guest) => Guest.fromDynamic(guest))
              .toList() ??
          [],
      hasSeatLayout: data['hasSeatLayout'] ?? false, // Fetching from Firestore safely
    );
  }
}

/// Guest model to handle both names and image URLs
class Guest {
  final String name;
  final String imageUrl;

  Guest({required this.name, required this.imageUrl});

  /// Handle guests that might be just names or image URLs
  factory Guest.fromDynamic(dynamic guest) {
    if (guest is String) {
      return Guest(name: guest, imageUrl: '');
    } else if (guest is Map<String, dynamic>) {
      return Guest(
        name: guest['name'] ?? 'Unknown Guest',
        imageUrl: guest['imageUrl'] ?? '',
      );
    }
    return Guest(name: 'Unknown Guest', imageUrl: '');
  }
}
