enum SubscriptionTier {
  free,
  silver,
  gold,
}

class SubscriptionLimits {
  final int dailyMessages;
  final int dailyLikes;
  final int dailyRewinds;  // -1 means unlimited
  final bool unlimitedGifts;
  final bool hasAds;
  final int adsToRefill;
  final int profileBoosts;  // -1 means unlimited
  final int callMinutesPerMonth;  // 0 means no calls, -1 means unlimited

  const SubscriptionLimits({
    required this.dailyMessages,
    required this.dailyLikes,
    required this.dailyRewinds,
    required this.unlimitedGifts,
    required this.hasAds,
    required this.adsToRefill,
    this.profileBoosts = 0,
    this.callMinutesPerMonth = 0,
  });

  static const free = SubscriptionLimits(
    dailyMessages: 3,
    dailyLikes: 3,
    dailyRewinds: 3,
    unlimitedGifts: false,
    hasAds: true,
    adsToRefill: 2,
    profileBoosts: 1,
    callMinutesPerMonth: 0,
  );

  static const silver = SubscriptionLimits(
    dailyMessages: 25,
    dailyLikes: 10,
    dailyRewinds: 10,
    unlimitedGifts: false,
    hasAds: true,
    adsToRefill: 2,
    profileBoosts: 1,
    callMinutesPerMonth: 45,
  );

  static const gold = SubscriptionLimits(
    dailyMessages: -1,
    dailyLikes: -1,
    dailyRewinds: -1,
    unlimitedGifts: true,
    hasAds: false,
    adsToRefill: 0,
    profileBoosts: -1,
    callMinutesPerMonth: 600,
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
      '3 rewinds per day',
      '1 free profile boost',
      'Watch 2 ads to refill',
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
      '10 rewinds per day',
      '1 profile boost per day',
      '45 minutes of call time per month',
      'Watch 2 ads to refill',
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
      'Unlimited rewinds',
      'Unlimited profile boosts',
      '600 minutes of call time per month',
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
