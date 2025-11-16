class GiftModel {
  final String id;
  final String name;
  final String emoji;
  final String category;

  const GiftModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'category': category,
    };
  }

  factory GiftModel.fromJson(Map<String, dynamic> json) {
    return GiftModel(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      category: json['category'] as String,
    );
  }
}

class GiftCatalog {
  static const List<GiftModel> allGifts = [
    // Romantic Gifts
    GiftModel(id: 'rose', name: 'Rose Bouquet', emoji: '🌹', category: 'romantic'),
    GiftModel(id: 'heart', name: 'Heart Chocolate', emoji: '🍫', category: 'romantic'),
    GiftModel(id: 'ring', name: 'Diamond Ring', emoji: '💍', category: 'romantic'),
    GiftModel(id: 'love_letter', name: 'Love Letter', emoji: '💌', category: 'romantic'),
    GiftModel(id: 'candles', name: 'Romantic Candles', emoji: '🕯️', category: 'romantic'),
    GiftModel(id: 'champagne', name: 'Champagne', emoji: '🍾', category: 'romantic'),

    // Fun & Cute
    GiftModel(id: 'teddy', name: 'Teddy Bear', emoji: '🧸', category: 'fun'),
    GiftModel(id: 'balloon', name: 'Heart Balloon', emoji: '🎈', category: 'fun'),
    GiftModel(id: 'crown', name: 'Crown', emoji: '👑', category: 'fun'),
    GiftModel(id: 'unicorn', name: 'Unicorn', emoji: '🦄', category: 'fun'),
    GiftModel(id: 'rainbow', name: 'Rainbow', emoji: '🌈', category: 'fun'),
    GiftModel(id: 'star', name: 'Star', emoji: '⭐', category: 'fun'),

    // Food & Drinks
    GiftModel(id: 'cake', name: 'Birthday Cake', emoji: '🎂', category: 'food'),
    GiftModel(id: 'coffee', name: 'Coffee', emoji: '☕', category: 'food'),
    GiftModel(id: 'wine', name: 'Wine Bottle', emoji: '🍷', category: 'food'),
    GiftModel(id: 'pizza', name: 'Pizza', emoji: '🍕', category: 'food'),
    GiftModel(id: 'cupcake', name: 'Cupcake', emoji: '🧁', category: 'food'),
    GiftModel(id: 'donut', name: 'Donut', emoji: '🍩', category: 'food'),

    // Luxury
    GiftModel(id: 'diamond', name: 'Diamond', emoji: '💎', category: 'luxury'),
    GiftModel(id: 'watch', name: 'Luxury Watch', emoji: '⌚', category: 'luxury'),
    GiftModel(id: 'perfume', name: 'Perfume', emoji: '🌸', category: 'luxury'),
    GiftModel(id: 'necklace', name: 'Necklace', emoji: '📿', category: 'luxury'),
    GiftModel(id: 'purse', name: 'Designer Purse', emoji: '👜', category: 'luxury'),
    GiftModel(id: 'lipstick', name: 'Lipstick', emoji: '💄', category: 'luxury'),

    // Experiences
    GiftModel(id: 'plane', name: 'Trip', emoji: '✈️', category: 'experience'),
    GiftModel(id: 'camera', name: 'Camera', emoji: '📷', category: 'experience'),
    GiftModel(id: 'ticket', name: 'Concert Ticket', emoji: '🎫', category: 'experience'),
    GiftModel(id: 'music', name: 'Music', emoji: '🎵', category: 'experience'),
    GiftModel(id: 'movie', name: 'Movie Night', emoji: '🎬', category: 'experience'),
    GiftModel(id: 'beach', name: 'Beach Day', emoji: '🏖️', category: 'experience'),
  ];

  static List<GiftModel> getByCategory(String category) {
    return allGifts.where((gift) => gift.category == category).toList();
  }

  static List<String> get categories {
    return ['romantic', 'fun', 'food', 'luxury', 'experience'];
  }

  static String getCategoryName(String category) {
    switch (category) {
      case 'romantic':
        return 'Romantic';
      case 'fun':
        return 'Fun & Cute';
      case 'food':
        return 'Food & Drinks';
      case 'luxury':
        return 'Luxury';
      case 'experience':
        return 'Experiences';
      default:
        return category;
    }
  }
}
