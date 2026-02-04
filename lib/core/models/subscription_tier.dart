enum SubscriptionTier {
  free,
  silver,
  gold,
}

class SubscriptionLimits {
  final int dailyMessages;
  final int dailyLikes;
  final bool unlimitedGifts;
  final bool hasAds;
  final int adsToRefill;

  const SubscriptionLimits({
    required this.dailyMessages,
    required this.dailyLikes,
    required this.unlimitedGifts,
    required this.hasAds,
    required this.adsToRefill,
  });

  static const free = SubscriptionLimits(
    dailyMessages: 3,  // Free users get 3 messages per day
    dailyLikes: 3,     // Free users get 3 likes per day
    unlimitedGifts: false,
    hasAds: true,
    adsToRefill: 3,    // Watch 3 ads to refill
  );

  static const silver = SubscriptionLimits(
    dailyMessages: 25,  // Silver users get 25 messages per day
    dailyLikes: 10,     // Silver users get 10 likes per day
    unlimitedGifts: false,
    hasAds: true,
    adsToRefill: 3,    // Watch 3 ads to refill
  );

  static const gold = SubscriptionLimits(
    dailyMessages: -1, // -1 means unlimited
    dailyLikes: -1, // -1 means unlimited
    unlimitedGifts: true,
    hasAds: false,
    adsToRefill: 0,
  );

  static SubscriptionLimits fromTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return free;
      case SubscriptionTier.silver:
        return silver;
      case SubscriptionTier.gold:
        return gold;
    }
  }
}

class SubscriptionPlan {
  final SubscriptionTier tier;
  final String name;
  final double price;
  final String priceDisplay;
  final SubscriptionLimits limits;
  final List<String> features;

  const SubscriptionPlan({
    required this.tier,
    required this.name,
    required this.price,
    required this.priceDisplay,
    required this.limits,
    required this.features,
  });

  static const freePlan = SubscriptionPlan(
    tier: SubscriptionTier.free,
    name: 'Free',
    price: 0.0,
    priceDisplay: 'Free',
    limits: SubscriptionLimits.free,
    features: [
      '3 messages per day',
      '3 likes per day',
      'Watch 3 ads to refill',
      'Basic matching',
    ],
  );

  static const silverPlan = SubscriptionPlan(
    tier: SubscriptionTier.silver,
    name: 'Silver',
    price: 2.99,
    priceDisplay: '\$2.99/month',
    limits: SubscriptionLimits.silver,
    features: [
      '25 messages per day',
      '10 likes per day',
      'Watch 3 ads to refill',
      'Priority matching',
      'See who liked you',
    ],
  );

  static const goldPlan = SubscriptionPlan(
    tier: SubscriptionTier.gold,
    name: 'Gold',
    price: 9.99,
    priceDisplay: '\$9.99/month',
    limits: SubscriptionLimits.gold,
    features: [
      'Unlimited messages',
      'Unlimited likes',
      'Profile boost',
      'No ads (except 1 for gifts)',
      'Priority matching',
      'See who liked you',
      'Advanced filters',
    ],
  );

  static List<SubscriptionPlan> get allPlans => [freePlan, silverPlan, goldPlan];

  static SubscriptionPlan fromTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return freePlan;
      case SubscriptionTier.silver:
        return silverPlan;
      case SubscriptionTier.gold:
        return goldPlan;
    }
  }
}
