/// Each question has 5 options mapping to the 5 love languages.
/// The value is the love language key that gets a point when selected.
class LoveLanguageQuestion {
  final String question;
  final List<LoveLanguageOption> options;

  const LoveLanguageQuestion({
    required this.question,
    required this.options,
  });
}

class LoveLanguageOption {
  final String text;
  final String language; // key into LoveLanguageResult.languageInfo

  const LoveLanguageOption({required this.text, required this.language});
}

const List<LoveLanguageQuestion> loveLanguageQuestions = [
  LoveLanguageQuestion(
    question: 'After a long day, what would make you feel most loved?',
    options: [
      LoveLanguageOption(text: 'Hearing "I\'m so proud of you"', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Coming home to a cooked meal', language: 'actsOfService'),
      LoveLanguageOption(text: 'Receiving a surprise gift', language: 'receivingGifts'),
      LoveLanguageOption(text: 'Cuddling on the couch together', language: 'qualityTime'),
      LoveLanguageOption(text: 'A warm hug at the door', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'What matters most to you in a relationship?',
    options: [
      LoveLanguageOption(text: 'Hearing "I love you" often', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Partner helping with responsibilities', language: 'actsOfService'),
      LoveLanguageOption(text: 'Thoughtful presents on special occasions', language: 'receivingGifts'),
      LoveLanguageOption(text: 'Dedicated date nights together', language: 'qualityTime'),
      LoveLanguageOption(text: 'Holding hands in public', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'How would your ideal partner show they care?',
    options: [
      LoveLanguageOption(text: 'Leaving sweet notes for me', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Running errands without being asked', language: 'actsOfService'),
      LoveLanguageOption(text: 'Bringing me flowers or small surprises', language: 'receivingGifts'),
      LoveLanguageOption(text: 'Planning a weekend getaway for us', language: 'qualityTime'),
      LoveLanguageOption(text: 'Back rubs after a tough day', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'What would hurt you most in a relationship?',
    options: [
      LoveLanguageOption(text: 'Harsh or critical words', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Partner never helping around the house', language: 'actsOfService'),
      LoveLanguageOption(text: 'Forgetting important dates', language: 'receivingGifts'),
      LoveLanguageOption(text: 'Always being too busy for me', language: 'qualityTime'),
      LoveLanguageOption(text: 'Not being physically affectionate', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'Pick the best anniversary surprise:',
    options: [
      LoveLanguageOption(text: 'A heartfelt love letter', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Partner plans everything so I can relax', language: 'actsOfService'),
      LoveLanguageOption(text: 'A meaningful piece of jewellery', language: 'receivingGifts'),
      LoveLanguageOption(text: 'A full day spent doing my favourite things', language: 'qualityTime'),
      LoveLanguageOption(text: 'A couples\' spa day', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'When you\'re feeling down, you\'d prefer your partner to:',
    options: [
      LoveLanguageOption(text: 'Tell me everything will be okay', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Take care of things I need to do', language: 'actsOfService'),
      LoveLanguageOption(text: 'Bring me my favourite treat', language: 'receivingGifts'),
      LoveLanguageOption(text: 'Sit with me and listen', language: 'qualityTime'),
      LoveLanguageOption(text: 'Hold me close', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'What makes you feel most appreciated?',
    options: [
      LoveLanguageOption(text: 'Being told how much I mean to them', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Having my car washed or clothes ironed', language: 'actsOfService'),
      LoveLanguageOption(text: 'Finding a gift they picked just for me', language: 'receivingGifts'),
      LoveLanguageOption(text: 'Having their full attention during conversation', language: 'qualityTime'),
      LoveLanguageOption(text: 'A gentle touch on the shoulder', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'Your ideal Saturday with your partner:',
    options: [
      LoveLanguageOption(text: 'Long conversations sharing dreams', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Them cooking my favourite dish', language: 'actsOfService'),
      LoveLanguageOption(text: 'Shopping together, buying each other things', language: 'receivingGifts'),
      LoveLanguageOption(text: 'Exploring a new place, just us two', language: 'qualityTime'),
      LoveLanguageOption(text: 'Lazy morning cuddling in bed', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'During a family gathering, you\'d love your partner to:',
    options: [
      LoveLanguageOption(text: 'Compliment me in front of everyone', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Help serve food and clean up', language: 'actsOfService'),
      LoveLanguageOption(text: 'Bring a gift for my parents', language: 'receivingGifts'),
      LoveLanguageOption(text: 'Stay by my side the whole time', language: 'qualityTime'),
      LoveLanguageOption(text: 'Keep their arm around me', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'The most romantic gesture would be:',
    options: [
      LoveLanguageOption(text: 'A voice note saying how much they love me', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Making chai for me every morning', language: 'actsOfService'),
      LoveLanguageOption(text: 'Surprising me with concert tickets', language: 'receivingGifts'),
      LoveLanguageOption(text: 'A phone-free dinner date', language: 'qualityTime'),
      LoveLanguageOption(text: 'Dancing together in the living room', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'When apart from your partner, you miss:',
    options: [
      LoveLanguageOption(text: 'Hearing their voice and sweet words', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'The things they do for me daily', language: 'actsOfService'),
      LoveLanguageOption(text: 'The little gifts they bring home', language: 'receivingGifts'),
      LoveLanguageOption(text: 'Spending time together doing nothing', language: 'qualityTime'),
      LoveLanguageOption(text: 'Their warmth and physical presence', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'After an argument, what helps you feel reconnected?',
    options: [
      LoveLanguageOption(text: 'A sincere apology with kind words', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Them doing something nice without asking', language: 'actsOfService'),
      LoveLanguageOption(text: 'A peace offering like my favourite dessert', language: 'receivingGifts'),
      LoveLanguageOption(text: 'Sitting together and talking it through', language: 'qualityTime'),
      LoveLanguageOption(text: 'A long hug', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'What would make you feel special on your birthday?',
    options: [
      LoveLanguageOption(text: 'A heartfelt birthday speech', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Partner organising everything for the party', language: 'actsOfService'),
      LoveLanguageOption(text: 'The perfect gift they remembered I wanted', language: 'receivingGifts'),
      LoveLanguageOption(text: 'A whole day spent together, just us', language: 'qualityTime'),
      LoveLanguageOption(text: 'Waking up to kisses and cuddles', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'In a long-distance relationship, you\'d value most:',
    options: [
      LoveLanguageOption(text: 'Good morning/goodnight texts daily', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Them helping manage things from afar', language: 'actsOfService'),
      LoveLanguageOption(text: 'Care packages sent to my door', language: 'receivingGifts'),
      LoveLanguageOption(text: 'Long video calls every evening', language: 'qualityTime'),
      LoveLanguageOption(text: 'Counting days until we can be close again', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'When meeting your partner\'s parents, you\'d feel best if they:',
    options: [
      LoveLanguageOption(text: 'Introduced me with glowing words', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Drove me there and handled everything', language: 'actsOfService'),
      LoveLanguageOption(text: 'Brought me something to wear for the occasion', language: 'receivingGifts'),
      LoveLanguageOption(text: 'Stayed close and made sure I felt included', language: 'qualityTime'),
      LoveLanguageOption(text: 'Held my hand to calm my nerves', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'Your partner gets a promotion. You\'d love them to:',
    options: [
      LoveLanguageOption(text: 'Thank me for supporting their journey', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Use the raise to make our life easier', language: 'actsOfService'),
      LoveLanguageOption(text: 'Buy me something to celebrate together', language: 'receivingGifts'),
      LoveLanguageOption(text: 'Take time off to celebrate with me', language: 'qualityTime'),
      LoveLanguageOption(text: 'Pick me up and spin me around', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'What keeps the spark alive?',
    options: [
      LoveLanguageOption(text: 'Flirty compliments even after years', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Surprising me by doing my chores', language: 'actsOfService'),
      LoveLanguageOption(text: 'Random surprise gifts for no reason', language: 'receivingGifts'),
      LoveLanguageOption(text: 'Regular date nights, no distractions', language: 'qualityTime'),
      LoveLanguageOption(text: 'Still being playful and affectionate', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'When stressed about work, you need your partner to:',
    options: [
      LoveLanguageOption(text: 'Encourage me and believe in me', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Handle dinner and household stuff', language: 'actsOfService'),
      LoveLanguageOption(text: 'Leave a comfort snack on my desk', language: 'receivingGifts'),
      LoveLanguageOption(text: 'Just be there, no phone, full attention', language: 'qualityTime'),
      LoveLanguageOption(text: 'Give me a calming massage', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'The best Diwali/Eid gift from your partner:',
    options: [
      LoveLanguageOption(text: 'A card with a beautiful message', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Decorating the house together for me', language: 'actsOfService'),
      LoveLanguageOption(text: 'Matching outfits or jewellery', language: 'receivingGifts'),
      LoveLanguageOption(text: 'Spending the whole festival together', language: 'qualityTime'),
      LoveLanguageOption(text: 'A tight embrace at midnight', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'In everyday life, what matters most?',
    options: [
      LoveLanguageOption(text: 'Being praised for what I do', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Partner sharing household duties equally', language: 'actsOfService'),
      LoveLanguageOption(text: 'Coming home to find small surprises', language: 'receivingGifts'),
      LoveLanguageOption(text: 'Eating meals together without screens', language: 'qualityTime'),
      LoveLanguageOption(text: 'Casual physical closeness throughout the day', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'Your dream wedding moment:',
    options: [
      LoveLanguageOption(text: 'Personal vows that make everyone cry', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Partner handling all the planning stress', language: 'actsOfService'),
      LoveLanguageOption(text: 'A meaningful wedding ring or heirloom', language: 'receivingGifts'),
      LoveLanguageOption(text: 'A private moment together amid the chaos', language: 'qualityTime'),
      LoveLanguageOption(text: 'The first dance, close and intimate', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'How do you show love to your partner?',
    options: [
      LoveLanguageOption(text: 'I tell them how amazing they are', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'I do things to make their life easier', language: 'actsOfService'),
      LoveLanguageOption(text: 'I buy them thoughtful presents', language: 'receivingGifts'),
      LoveLanguageOption(text: 'I plan activities for us to do together', language: 'qualityTime'),
      LoveLanguageOption(text: 'I show it through physical affection', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'After travelling apart, you\'d want your partner to:',
    options: [
      LoveLanguageOption(text: 'Say "I missed you so much"', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Have the house clean and ready for me', language: 'actsOfService'),
      LoveLanguageOption(text: 'Have a welcome home gift waiting', language: 'receivingGifts'),
      LoveLanguageOption(text: 'Clear their schedule for the day', language: 'qualityTime'),
      LoveLanguageOption(text: 'Run to me with a huge hug', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'A small thing that would mean the world:',
    options: [
      LoveLanguageOption(text: 'A random text saying "thinking of you"', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Finding my shoes polished in the morning', language: 'actsOfService'),
      LoveLanguageOption(text: 'A single rose left on my pillow', language: 'receivingGifts'),
      LoveLanguageOption(text: 'An unplanned walk together', language: 'qualityTime'),
      LoveLanguageOption(text: 'Fingers running through my hair', language: 'physicalTouch'),
    ],
  ),
  LoveLanguageQuestion(
    question: 'What would make you fall deeper in love?',
    options: [
      LoveLanguageOption(text: 'Being told "You make me a better person"', language: 'wordsOfAffirmation'),
      LoveLanguageOption(text: 'Them sacrificing their comfort for mine', language: 'actsOfService'),
      LoveLanguageOption(text: 'A surprise trip or experience planned for me', language: 'receivingGifts'),
      LoveLanguageOption(text: 'Them choosing me over other plans', language: 'qualityTime'),
      LoveLanguageOption(text: 'The way they look at and touch me', language: 'physicalTouch'),
    ],
  ),
];
