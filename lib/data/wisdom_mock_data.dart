import '../models/wisdom_post.dart';

/// Seed content for Wisdom Circle — elders share experience;
/// community answers questions. Not medical advice.
class WisdomMockData {
  WisdomMockData._();

  static final posts = <WisdomPost>[
    WisdomPost(
      id: 'w1',
      authorName: 'Kamala Ajji',
      authorAge: 72,
      isElder: true,
      title: 'Tulsi-ginger kadha when cold starts',
      body:
          'When someone in the house starts sneezing or gets a sore throat, I boil 4 tulsi leaves, a small piece of ginger, a pinch of turmeric and black pepper in 2 cups water for 8 minutes. Add a spoon of honey after it cools a little. Drink warm twice a day. Rest and warm water help more than any tablet for mild cold. If fever lasts more than 2 days, see a doctor.',
      type: WisdomPostType.remedy,
      topic: WisdomTopic.coldFlu,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      helpfulCount: 128,
      replyCount: 6,
      tags: ['cold', 'kadha', 'tulsi'],
      answers: [
        WisdomAnswer(
          id: 'a1',
          postId: 'w1',
          authorName: 'Ramesh Thatha',
          authorAge: 68,
          body:
              'I add a small piece of cinnamon too. Works well in monsoon. Don\'t give honey to babies under 1 year.',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          helpfulCount: 34,
          isFromElder: true,
        ),
        WisdomAnswer(
          id: 'a2',
          postId: 'w1',
          authorName: 'Priya S.',
          authorAge: 34,
          body:
              'Tried this for my husband last week — throat felt better by evening. Thank you Ajji!',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          helpfulCount: 12,
        ),
      ],
    ),
    WisdomPost(
      id: 'w2',
      authorName: 'Lakshmi Paati',
      authorAge: 69,
      isElder: true,
      title: 'Light food when stomach is upset',
      body:
          'For loose motion or heavy stomach after outside food: give soft rice with thin buttermilk (majjiga) and a pinch of salt. Avoid spicy pickles and milk for a day. Jeera water (roast jeera, boil, cool, sip) settles gas. Small meals, not empty stomach. If there is blood or high fever, hospital only — no home experiments.',
      type: WisdomPostType.tip,
      topic: WisdomTopic.digestion,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      helpfulCount: 96,
      replyCount: 4,
      tags: ['digestion', 'buttermilk', 'jeera'],
    ),
    WisdomPost(
      id: 'w3',
      authorName: 'Ananya R.',
      authorAge: 29,
      isElder: false,
      title: 'Mother-in-law has knee pain — what helps at home?',
      body:
              'My MIL (65) has morning stiffness in knees. Doctor said mild arthritis. Apart from medicines, what gentle home care do elders recommend? Warm oil massage? Walks? Diet?',
      type: WisdomPostType.question,
      topic: WisdomTopic.joints,
      createdAt: DateTime.now().subtract(const Duration(hours: 10)),
      helpfulCount: 22,
      replyCount: 3,
      tags: ['joints', 'arthritis', 'care'],
      answers: [
        WisdomAnswer(
          id: 'a3',
          postId: 'w3',
          authorName: 'Venkat Thatha',
          authorAge: 74,
          body:
              'Warm sesame oil massage at night, then wrap with soft cloth. 15-minute slow walk after breakfast, not on hard marble barefoot. Avoid sitting on floor for long. Turmeric milk at night helped me. Continue doctor\'s advice first.',
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          helpfulCount: 41,
          isFromElder: true,
        ),
      ],
    ),
    WisdomPost(
      id: 'w4',
      authorName: 'Saraswati Ajji',
      authorAge: 78,
      isElder: true,
      title: 'Why I still cook one full meal for the family every Sunday',
      body:
          'After retirement, loneliness comes quietly. Cooking for children and grandchildren on Sunday keeps my hands and mind busy. We sit together, talk about the week, and I teach my granddaughter one recipe. Money is not everything — sharing table is health for the heart. Young mothers: call your parents often. We wait for that ring.',
      type: WisdomPostType.story,
      topic: WisdomTopic.lifeWisdom,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      helpfulCount: 210,
      replyCount: 18,
      tags: ['family', 'cooking', 'love'],
    ),
    WisdomPost(
      id: 'w5',
      authorName: 'Meera Amma',
      authorAge: 66,
      isElder: true,
      title: 'Sugar-friendly evening snack ideas',
      body:
          'For those watching sugar: roasted chana, cucumber sticks with salt-pepper, or small bowl of curd with flax seeds. Avoid fruit juices — whole fruit is better (in limited portion as per doctor). Never skip dinner completely; light vegetable soup or millets khichdi works. Check sugar as doctor advised; these are only food habits from our home.',
      type: WisdomPostType.tip,
      topic: WisdomTopic.diabetesCare,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      helpfulCount: 77,
      replyCount: 5,
      tags: ['diabetes', 'snacks', 'diet'],
    ),
    WisdomPost(
      id: 'w6',
      authorName: 'Rahul K.',
      authorAge: 41,
      isElder: false,
      title: 'Child has mild cough at night — any safe home tip?',
      body:
          'My 6-year-old coughs more after 11pm. No fever. Pediatrician said viral, steam and hydration. Any gentle kitchen remedies elders use for kids (safe ones)?',
      type: WisdomPostType.question,
      topic: WisdomTopic.kidsCare,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      helpfulCount: 15,
      replyCount: 2,
      tags: ['kids', 'cough'],
      answers: [
        WisdomAnswer(
          id: 'a4',
          postId: 'w6',
          authorName: 'Kamala Ajji',
          authorAge: 72,
          body:
              'Warm water with a little honey (only if child is above 1 year) before bed. Keep head slightly raised. Steam with plain water 5 minutes, adult must stay. No harsh kadha for small kids without doctor. If breathing is hard, go to hospital immediately.',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          helpfulCount: 28,
          isFromElder: true,
        ),
      ],
    ),
    WisdomPost(
      id: 'w7',
      authorName: 'Fatima Bi',
      authorAge: 70,
      isElder: true,
      title: 'After fever — soft foods that rebuild strength',
      body:
          'Once fever goes: start with soft khichdi, moong dal water, stewed apple. Avoid oily biryani for 2–3 days. Tender coconut water if doctor allows. Sleep is the real medicine. Patience with food helps recovery faster than heavy meals.',
      type: WisdomPostType.tip,
      topic: WisdomTopic.recoveryFood,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      helpfulCount: 64,
      replyCount: 3,
      tags: ['recovery', 'fever', 'khichdi'],
    ),
    WisdomPost(
      id: 'w8',
      authorName: 'Suresh Thatha',
      authorAge: 71,
      isElder: true,
      title: 'How we managed money and peace as a joint family',
      body:
          'We never argued about money in front of children. Monthly, my wife and I sat with a notebook — rent, rice, school, temple. Small savings in a steel dabba taught our daughters discipline. Today they run home businesses (pickles and stitching). Respect for each other\'s work is more important than big salary.',
      type: WisdomPostType.story,
      topic: WisdomTopic.lifeWisdom,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      helpfulCount: 155,
      replyCount: 11,
      tags: ['family', 'savings', 'respect'],
    ),
  ];

  static List<WisdomPost> byTopic(WisdomTopic? topic) {
    if (topic == null) return posts;
    return posts.where((p) => p.topic == topic).toList();
  }

  static List<WisdomPost> byType(WisdomPostType? type) {
    if (type == null) return posts;
    return posts.where((p) => p.type == type).toList();
  }

  static WisdomPost? byId(String id) {
    try {
      return posts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
