enum WisdomPostType { tip, remedy, question, story }

enum WisdomTopic {
  coldFlu,
  digestion,
  joints,
  diabetesCare,
  kidsCare,
  womenHealth,
  recoveryFood,
  lifeWisdom,
  other,
}

class WisdomAnswer {
  final String id;
  final String postId;
  final String authorName;
  final int authorAge;
  final String body;
  final DateTime createdAt;
  final int helpfulCount;
  final bool isFromElder;

  const WisdomAnswer({
    required this.id,
    required this.postId,
    required this.authorName,
    this.authorAge = 0,
    required this.body,
    required this.createdAt,
    this.helpfulCount = 0,
    this.isFromElder = false,
  });
}

class WisdomPost {
  final String id;
  final String authorName;
  final int authorAge;
  final bool isElder;
  final String title;
  final String body;
  final WisdomPostType type;
  final WisdomTopic topic;
  final DateTime createdAt;
  final int helpfulCount;
  final int replyCount;
  final List<WisdomAnswer> answers;
  final List<String> tags;

  const WisdomPost({
    required this.id,
    required this.authorName,
    this.authorAge = 0,
    this.isElder = false,
    required this.title,
    required this.body,
    required this.type,
    required this.topic,
    required this.createdAt,
    this.helpfulCount = 0,
    this.replyCount = 0,
    this.answers = const [],
    this.tags = const [],
  });

  String get typeLabel {
    switch (type) {
      case WisdomPostType.tip:
        return 'Health Tip';
      case WisdomPostType.remedy:
        return 'Home Remedy';
      case WisdomPostType.question:
        return 'Question';
      case WisdomPostType.story:
        return 'Life Story';
    }
  }

  String get topicLabel {
    switch (topic) {
      case WisdomTopic.coldFlu:
        return 'Cold & Flu';
      case WisdomTopic.digestion:
        return 'Digestion';
      case WisdomTopic.joints:
        return 'Joints & Pain';
      case WisdomTopic.diabetesCare:
        return 'Diabetes Care';
      case WisdomTopic.kidsCare:
        return 'Kids Care';
      case WisdomTopic.womenHealth:
        return 'Women\'s Wellness';
      case WisdomTopic.recoveryFood:
        return 'Food for Recovery';
      case WisdomTopic.lifeWisdom:
        return 'Life Wisdom';
      case WisdomTopic.other:
        return 'General';
    }
  }
}
