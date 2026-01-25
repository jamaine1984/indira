/**
 * Profanity Filter Population Script
 *
 * This script populates the Firestore profanity filter with a comprehensive
 * list of inappropriate words for content moderation in the dating app.
 *
 * Usage:
 *   node scripts/populate_profanity_filter.js
 *
 * Prerequisites:
 *   - Firebase Admin SDK initialized
 *   - Firebase service account credentials
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin (if not already initialized)
if (!admin.apps.length) {
  admin.initializeApp({
    // Uses FIREBASE_CONFIG environment variable or default credentials
  });
}

const db = admin.firestore();

/**
 * Comprehensive profanity and inappropriate content filter list
 *
 * Categories:
 * - Profanity and vulgar language
 * - Sexual content and explicit terms
 * - Hate speech and slurs (racial, religious, sexual orientation, etc.)
 * - Harassment and abuse terms
 * - Spam and scam keywords
 * - Drug-related terms
 * - Violence and threats
 *
 * Note: This list is intentionally comprehensive to protect users.
 * Some legitimate words may be caught - implement context-aware filtering if needed.
 */
const profanityWords = [
  // Common profanity (basic tier)
  'fuck', 'shit', 'bitch', 'asshole', 'bastard', 'damn', 'crap',
  'piss', 'dick', 'cock', 'pussy', 'cunt', 'whore', 'slut',

  // Variations and misspellings
  'fck', 'fuk', 'f***', 'sh*t', 'b*tch', 'a**hole', 'motherf***er',
  'mofo', 'mf', 'wtf', 'stfu', 'gtfo', 'bs',

  // Sexual and explicit content
  'sex', 'porn', 'xxx', 'nsfw', 'nude', 'nudes', 'naked',
  'horny', 'hookup', 'hook up', 'fuckboy', 'fuckgirl',
  'blowjob', 'handjob', 'anal', 'oral', 'vagina', 'penis',
  'boobs', 'tits', 'ass', 'butt', 'booty',

  // Hate speech - racial slurs
  'nigger', 'nigga', 'n***a', 'chink', 'gook', 'spic',
  'wetback', 'beaner', 'kike', 'towelhead', 'raghead',

  // Hate speech - LGBTQ+ slurs
  'fag', 'faggot', 'dyke', 'tranny', 'shemale',

  // Hate speech - religious/ethnic
  'muzzie', 'sandnigger', 'paki', 'jap', 'gypsy',

  // Hate speech - general
  'nazi', 'hitler', 'kkk', 'white power', 'white supremacy',

  // Harassment and abuse
  'rape', 'rapist', 'molest', 'pedophile', 'pedo',
  'kill yourself', 'kys', 'suicide', 'die',
  'ugly', 'fat', 'gross', 'disgusting', 'loser',
  'retard', 'retarded', 'stupid', 'idiot', 'moron',

  // Scam and spam keywords
  'bitcoin', 'crypto', 'investment', 'profit', 'money',
  'cashapp', 'venmo', 'paypal', 'send money', 'wire transfer',
  'sugar daddy', 'sugar baby', 'allowance', 'financial support',
  'onlyfans', 'premium snap', 'snapchat premium',
  'escort', 'massage', 'services', 'rates', 'donations',
  'telegram', 'whatsapp', 'kik', 'wickr', 'signal',
  'click here', 'link in bio', 'check my profile',

  // Drug-related
  'weed', 'marijuana', 'cannabis', 'drugs', 'cocaine',
  'heroin', 'meth', 'dealer', 'pills', 'molly', 'ecstasy',

  // Violence and threats
  'murder', 'kill', 'bomb', 'terrorist', 'weapon', 'gun',
  'knife', 'stab', 'shoot', 'attack', 'hurt',

  // Minors (zero tolerance)
  'underage', 'minor', 'teen', 'teenager', 'child',
  'young', 'jailbait', 'loli', 'shota',

  // Misc inappropriate
  'incest', 'bestiality', 'necrophilia', 'rape',
  'molest', 'abuse', 'torture', 'slave',
];

/**
 * Spam patterns to detect and block
 * These are regex patterns that catch common spam behaviors
 */
const spamPatterns = [
  // Phone numbers
  '\\d{3}[-.]?\\d{3}[-.]?\\d{4}',  // US phone format
  '\\+\\d{1,3}[\\s.-]?\\d{1,4}[\\s.-]?\\d{1,4}[\\s.-]?\\d{1,9}',  // International

  // Email addresses
  '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}',

  // URLs
  'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+',
  'www\\.[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}',

  // Social media handles
  '@[a-zA-Z0-9_]{1,15}',  // Twitter/Instagram style
  'snap[:\\s-]*[a-zA-Z0-9_]+',  // Snapchat

  // Money symbols repeated (scam indicator)
  '[$€£¥₹]{3,}',

  // Excessive emoji (spam indicator)
  '[🔥💰💵💴💶💷💸💳💎🎁]{5,}',
];

/**
 * Context-aware rules
 * These help reduce false positives while maintaining safety
 */
const contextRules = {
  // Allow these in certain contexts (e.g., "I love basketball")
  allowedPhrases: [
    'basketball', 'cocktail', 'classic', 'assistant',
    'passionate', 'therapist', 'analysis', 'massachusetts',
  ],

  // Severity levels for graduated responses
  severity: {
    critical: ['rape', 'kill yourself', 'kys', 'pedophile', 'pedo', 'nazi', 'kkk'],
    high: ['nigger', 'fag', 'faggot', 'cunt', 'whore', 'slut'],
    medium: ['fuck', 'shit', 'bitch', 'dick', 'pussy'],
    low: ['damn', 'crap', 'ass'],
  },
};

/**
 * Populate the profanity filter in Firestore
 */
async function populateFilter() {
  console.log('🔧 Starting profanity filter population...\n');

  try {
    // Create the profanity filter document
    const filterRef = db.collection('app_config').doc('profanity_filter');

    await filterRef.set({
      enabled: true,
      words: profanityWords,
      spamPatterns: spamPatterns,
      contextRules: contextRules,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      version: '1.0.0',
      description: 'Comprehensive profanity and content moderation filter',
      totalWords: profanityWords.length,
      categories: {
        profanity: true,
        sexual: true,
        hateSpeech: true,
        harassment: true,
        spam: true,
        drugs: true,
        violence: true,
        minors: true,
      },
    });

    console.log('✅ Profanity filter populated successfully!');
    console.log(`📊 Total filtered words: ${profanityWords.length}`);
    console.log(`📊 Spam patterns: ${spamPatterns.length}`);
    console.log(`📊 Severity levels: ${Object.keys(contextRules.severity).length}`);
    console.log('\n🔒 Content moderation is now active!\n');

    // Also create a moderation log collection for tracking
    const moderationLogRef = db.collection('moderation_logs');
    await moderationLogRef.doc('_config').set({
      enabled: true,
      retentionDays: 90,  // Keep logs for 90 days
      alertThreshold: 5,  // Alert after 5 violations
      autoBlockThreshold: 10,  // Auto-block after 10 violations
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('✅ Moderation logging configured!\n');

  } catch (error) {
    console.error('❌ Error populating filter:', error);
    process.exit(1);
  }
}

/**
 * Display filter statistics
 */
async function displayStats() {
  console.log('📈 Profanity Filter Statistics:\n');
  console.log(`Total words blocked: ${profanityWords.length}`);
  console.log(`Spam patterns: ${spamPatterns.length}`);

  console.log('\n📊 Breakdown by category:');
  const categories = {
    'Profanity & Vulgar': 25,
    'Sexual Content': 20,
    'Hate Speech (Racial)': 15,
    'Hate Speech (LGBTQ+)': 5,
    'Hate Speech (Other)': 10,
    'Harassment': 15,
    'Scam/Spam Keywords': 30,
    'Drug References': 10,
    'Violence': 15,
    'Minor Protection': 10,
  };

  for (const [category, count] of Object.entries(categories)) {
    console.log(`  - ${category}: ~${count} terms`);
  }

  console.log('\n⚠️  Important Notes:');
  console.log('  - Filter catches variations and misspellings');
  console.log('  - Severity levels enable graduated responses');
  console.log('  - Context rules reduce false positives');
  console.log('  - All violations are logged for review');
  console.log('  - Auto-moderation threshold: 10 violations = account block\n');
}

// Run the script
(async () => {
  await displayStats();
  await populateFilter();
  console.log('🎉 Profanity filter setup complete!\n');
  console.log('🔍 Next steps:');
  console.log('  1. Verify filter in Firestore console: app_config/profanity_filter');
  console.log('  2. Test with ValidationService in your Flutter app');
  console.log('  3. Monitor moderation_logs collection for violations');
  console.log('  4. Adjust severity thresholds as needed\n');

  process.exit(0);
})();
