class StudyResource {
  final String id;
  final String title;
  final String coverImage;
  final String type; // 'video', 'document', 'quiz' etc.
  final String author;
  final String description;
  final String duration;
  final String difficulty;
  final List<String> tags;
  final int viewCount;
  final double rating;
  final String lastUpdated;

  const StudyResource({
    required this.id,
    required this.title,
    required this.coverImage,
    required this.type,
    required this.author,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.tags,
    required this.viewCount,
    required this.rating,
    required this.lastUpdated,
  });
}

class Problem {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final double successRate;
  final int submissions;
  final List<String> tags;

  Problem({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.successRate,
    required this.submissions,
    required this.tags,
  });
}

class Reply {
  final String id;
  final String authorName;
  final String authorAvatar;
  final String content;
  final DateTime createdAt;
  final String? codeSnippet;
  final String? codeLanguage;
  final List<String>? images;
  final String? audioUrl;
  final int likes;
  final bool isAccepted;
  final List<SubReply> subReplies;

  const Reply({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.createdAt,
    this.codeSnippet,
    this.codeLanguage,
    this.images,
    this.audioUrl,
    required this.likes,
    required this.isAccepted,
    this.subReplies = const [],
  });
}

class SubReply {
  final String id;
  final String authorName;
  final String authorAvatar;
  final String content;
  final DateTime createdAt;
  final String? codeSnippet;
  final String? codeLanguage;
  final List<String>? images;
  final String? audioUrl;
  final int likes;
  final String replyToName;

  const SubReply({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.createdAt,
    this.codeSnippet,
    this.codeLanguage,
    this.images,
    this.audioUrl,
    required this.likes,
    required this.replyToName,
  });
}

final List<StudyResource> studyResources = [
  StudyResource(
    id: "1",
    title: "算法基础：数据结构入门",
    coverImage: "assets/1.jpeg",
    type: "video",
    author: "张教授",
    description: "深入浅出讲解基础数据结构，包括数组、链表、栈、队列等核心概念。\n\n"
        "课程要点：\n"
        "• 数组和字符串处理\n"
        "• 链表操作和实现\n"
        "• 栈和队列应用\n"
        "• 实战练习题解析",
    duration: "3小时",
    difficulty: "入门",
    tags: ["数据结构", "算法", "编程基础"],
    viewCount: 1200,
    rating: 4.8,
    lastUpdated: "2024-03-15",
  ),
  StudyResource(
    id: "2",
    title: "动态规划专题讲解",
    coverImage: "assets/2.jpeg",
    type: "document",
    author: "李博士",
    description: "系统讲解动态规划的思想方法和经典题型。\n\n"
        "包含内容：\n"
        "• DP基本概念\n"
        "• 经典题型分析\n"
        "• 解题技巧总结\n"
        "• 进阶问题探讨",
    duration: "2小时",
    difficulty: "进阶",
    tags: ["动态规划", "算法", "进阶技巧"],
    viewCount: 850,
    rating: 4.9,
    lastUpdated: "2024-03-10",
  ),
];

final List<Problem> problems = [
  Problem(
    id: '1',
    title: '两数之和',
    description: '给定一个整数数组 nums 和一个目标值 target，请你在该数组中找出和为目标值的那两个整数，并返回他们的数组下标。',
    difficulty: '简单',
    successRate: 45.5,
    submissions: 1200,
    tags: ['算法', '哈希表'],
  ),
  Problem(
    id: '2',
    title: '反转链表',
    description: '反转一个单链表。',
    difficulty: '简单',
    successRate: 60.2,
    submissions: 800,
    tags: ['数据结构', '链表'],
  ),
  Problem(
    id: '3',
    title: 'LRU缓存机制',
    description: '设计和实现一个 LRU (最近最少使用) 缓存机制。',
    difficulty: '中等',
    successRate: 35.8,
    submissions: 500,
    tags: ['算法', '数据结构', '哈希表'],
  ),
  Problem(
    id: '4',
    title: '设计推特',
    description: '设计一个简化版的推特(Twitter)，可以让用户实现发送推文，关注/取消关注其他用户，能够看见关注人（包括自己）的最近十条推文。',
    difficulty: '中等',
    successRate: 30.1,
    submissions: 300,
    tags: ['系统设计', '数据结构'],
  ),
  Problem(
    id: '5',
    title: '数据库连接池',
    description: '设计一个数据库连接池，实现连接的获取和释放。',
    difficulty: '中等',
    successRate: 40.2,
    submissions: 200,
    tags: ['数据库', '系统设计'],
  ),
  Problem(
    id: '6',
    title: '实现Promise.all',
    description: '实现一个类似Promise.all的函数，接收一个Promise数组，返回一个新的Promise。',
    difficulty: '中等',
    successRate: 55.5,
    submissions: 400,
    tags: ['前端开发', 'JavaScript'],
  ),
  Problem(
    id: '7',
    title: 'RESTful API设计',
    description: '设计一个RESTful API，实现用户注册、登录、获取用户信息等功能。',
    difficulty: '中等',
    successRate: 48.8,
    submissions: 350,
    tags: ['后端开发', 'API设计'],
  ),
];