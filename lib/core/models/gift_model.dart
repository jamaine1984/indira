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
    // Indian Traditional Gifts - AT THE TOP
    GiftModel(id: 'diya', name: 'Diya Lamp', emoji: '🪔', category: 'traditional'),
    GiftModel(id: 'sari', name: 'Silk Sari', emoji: '🥻', category: 'traditional'),
    GiftModel(id: 'lotus', name: 'Lotus Flower', emoji: '🪷', category: 'traditional'),
    GiftModel(id: 'peacock', name: 'Peacock Feather', emoji: '🦚', category: 'traditional'),
    GiftModel(id: 'temple', name: 'Temple Visit', emoji: '🛕', category: 'traditional'),
    GiftModel(id: 'om', name: 'Om Symbol', emoji: '🕉️', category: 'traditional'),
    GiftModel(id: 'elephant', name: 'Elephant Figurine', emoji: '🐘', category: 'traditional'),
    GiftModel(id: 'marigold', name: 'Marigold Garland', emoji: '🏵️', category: 'traditional'),

    // Romantic Gifts
    GiftModel(id: 'rose', name: 'Rose Bouquet', emoji: '🌹', category: 'romantic'),
    GiftModel(id: 'heart', name: 'Heart Chocolate', emoji: '🍫', category: 'romantic'),
    GiftModel(id: 'ring', name: 'Diamond Ring', emoji: '💍', category: 'romantic'),
    GiftModel(id: 'love_letter', name: 'Love Letter', emoji: '💌', category: 'romantic'),
    GiftModel(id: 'candles', name: 'Romantic Candles', emoji: '🕯️', category: 'romantic'),
    GiftModel(id: 'champagne', name: 'Champagne', emoji: '🍾', category: 'romantic'),

    // More Romantic
    GiftModel(id: 'kiss', name: 'Kiss', emoji: '💋', category: 'romantic'),
    GiftModel(id: 'couple', name: 'Couple Dance', emoji: '💃', category: 'romantic'),
    GiftModel(id: 'sunset', name: 'Sunset View', emoji: '🌅', category: 'romantic'),
    GiftModel(id: 'moon', name: 'Moonlight Date', emoji: '🌙', category: 'romantic'),
    GiftModel(id: 'poem', name: 'Love Poem', emoji: '📜', category: 'romantic'),
    GiftModel(id: 'photo', name: 'Photo Frame', emoji: '🖼️', category: 'romantic'),
    GiftModel(id: 'hug', name: 'Warm Hug', emoji: '🤗', category: 'romantic'),
    GiftModel(id: 'cupid', name: 'Cupid Arrow', emoji: '💘', category: 'romantic'),

    // More Fun & Cute
    GiftModel(id: 'butterfly', name: 'Butterfly', emoji: '🦋', category: 'fun'),
    GiftModel(id: 'dolphin', name: 'Dolphin', emoji: '🐬', category: 'fun'),
    GiftModel(id: 'panda', name: 'Panda', emoji: '🐼', category: 'fun'),
    GiftModel(id: 'kitten', name: 'Cute Kitten', emoji: '🐱', category: 'fun'),
    GiftModel(id: 'puppy', name: 'Puppy', emoji: '🐶', category: 'fun'),
    GiftModel(id: 'hamster', name: 'Hamster', emoji: '🐹', category: 'fun'),
    GiftModel(id: 'parrot', name: 'Parrot', emoji: '🦜', category: 'fun'),
    GiftModel(id: 'rabbit', name: 'Bunny', emoji: '🐰', category: 'fun'),

    // More Food & Drinks
    GiftModel(id: 'samosa', name: 'Samosa', emoji: '🥟', category: 'food'),
    GiftModel(id: 'biryani', name: 'Biryani', emoji: '🍛', category: 'food'),
    GiftModel(id: 'ladoo', name: 'Ladoo Sweet', emoji: '🟠', category: 'food'),
    GiftModel(id: 'chai', name: 'Chai Tea', emoji: '🍵', category: 'food'),
    GiftModel(id: 'mango', name: 'Mango', emoji: '🥭', category: 'food'),
    GiftModel(id: 'coconut', name: 'Coconut', emoji: '🥥', category: 'food'),
    GiftModel(id: 'icecream', name: 'Ice Cream', emoji: '🍦', category: 'food'),
    GiftModel(id: 'chocolate', name: 'Chocolate Bar', emoji: '🍫', category: 'food'),

    // More Luxury
    GiftModel(id: 'crown_jewel', name: 'Crown Jewel', emoji: '👑', category: 'luxury'),
    GiftModel(id: 'sports_car', name: 'Sports Car', emoji: '🏎️', category: 'luxury'),
    GiftModel(id: 'yacht', name: 'Yacht', emoji: '🛥️', category: 'luxury'),
    GiftModel(id: 'mansion', name: 'Mansion', emoji: '🏛️', category: 'luxury'),
    GiftModel(id: 'gold_bar', name: 'Gold Bar', emoji: '🪙', category: 'luxury'),
    GiftModel(id: 'crystal', name: 'Crystal', emoji: '💎', category: 'luxury'),
    GiftModel(id: 'tiara', name: 'Tiara', emoji: '👸', category: 'luxury'),
    GiftModel(id: 'emerald', name: 'Emerald', emoji: '💚', category: 'luxury'),

    // More Experiences
    GiftModel(id: 'spa', name: 'Spa Day', emoji: '💆', category: 'experience'),
    GiftModel(id: 'helicopter', name: 'Helicopter Ride', emoji: '🚁', category: 'experience'),
    GiftModel(id: 'balloon_ride', name: 'Hot Air Balloon', emoji: '🎈', category: 'experience'),
    GiftModel(id: 'cruise', name: 'Cruise Trip', emoji: '🚢', category: 'experience'),
    GiftModel(id: 'safari', name: 'Safari Adventure', emoji: '🦁', category: 'experience'),
    GiftModel(id: 'mountain', name: 'Mountain Trek', emoji: '🏔️', category: 'experience'),
    GiftModel(id: 'dance', name: 'Dance Lessons', emoji: '🕺', category: 'experience'),
    GiftModel(id: 'cooking', name: 'Cooking Class', emoji: '👨‍🍳', category: 'experience'),

    // Special & Unique
    GiftModel(id: 'shooting_star', name: 'Shooting Star', emoji: '💫', category: 'special'),
    GiftModel(id: 'four_leaf', name: 'Lucky Clover', emoji: '🍀', category: 'special'),
    GiftModel(id: 'trophy', name: 'Trophy', emoji: '🏆', category: 'special'),
    GiftModel(id: 'medal', name: 'Gold Medal', emoji: '🥇', category: 'special'),
    GiftModel(id: 'key', name: 'Key to Heart', emoji: '🔑', category: 'special'),
    GiftModel(id: 'lock', name: 'Love Lock', emoji: '🔒', category: 'special'),
    GiftModel(id: 'infinity', name: 'Infinity', emoji: '♾️', category: 'special'),
    GiftModel(id: 'compass', name: 'Compass', emoji: '🧭', category: 'special'),
  ];

  static List<GiftModel> getByCategory(String category) {
    return allGifts.where((gift) => gift.category == category).toList();
  }

  static List<String> get categories {
    return ['romantic', 'fun', 'food', 'luxury', 'experience', 'traditional', 'special'];
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
      case 'traditional':
        return 'Traditional Indian';
      case 'special':
        return 'Special & Unique';
      default:
        return category;
    }
  }
}
