import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_record.dart';
import '../repositories/study_record_repository.dart';

enum Period { day, week, month, year }

class StudyRecordScreen extends StatefulWidget {
  const StudyRecordScreen({super.key});

  @override
  State<StudyRecordScreen> createState() => _StudyRecordScreenState();
}

class _StudyRecordScreenState extends State<StudyRecordScreen> {
  final StudyRecordRepository _repo = StudyRecordRepository();
  List<StudyRecord> _records = [];
  Period _selectedPeriod = Period.day;
  int _userId = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndRecords();
  }

  Future<void> _loadUserIdAndRecords() async {
    final prefs = await SharedPreferences.getInstance();
    // 从缓存用户信息中读取 userId
    final cached = prefs.getString('cached_user_info');
    if (cached != null) {
      try {
        final data = Map<String, dynamic>.from(await Future.value(jsonDecode(cached)));
        _userId = data['userId'] ?? 0;
      } catch (_) {}
    }
    if (_userId > 0) {
      final list = await _repo.getStudyRecords(_userId);
      setState(() {
        _records = list;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Map<DateTime, int> _aggregateByDate() {
    final map = <DateTime, int>{};
    for (var r in _records) {
      final day = DateTime(r.date.year, r.date.month, r.date.day);
      map[day] = (map[day] ?? 0) + r.duration;
    }
    return map;
  }

  List<MapEntry<DateTime, int>> _entriesForPeriod() {
    final byDate = _aggregateByDate().entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    // TODO: 根据 _selectedPeriod 过滤不同粒度，目前统一按日
    return byDate;
  }

  /// 构建过去20周的日期列表（每周7天）
  List<DateTime> _last20WeeksDays() {
    final today = DateTime.now();
    final totalDays = 20 * 7;
    final start = today.subtract(Duration(days: totalDays - 1));
    return List.generate(totalDays, (i) => DateTime(start.year, start.month, start.day + i));
  }

  /// 绘制最近20周的热力图
  Widget _buildHeatMap() {
    final dataMap = _aggregateByDate();
    final days = _last20WeeksDays();
    final maxVal = dataMap.values.isEmpty ? 0 : dataMap.values.reduce((a, b) => a > b ? a : b);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(20, (weekIdx) {
          final weekDays = days.skip(weekIdx * 7).take(7).toList();
          return Column(
            children: weekDays.map((day) {
              final key = DateTime(day.year, day.month, day.day);
              final val = dataMap[key] ?? 0;
              final intensity = maxVal > 0 ? (val / maxVal) : 0.0;
              final color = Colors.green.withValues(alpha: 0.2 + 0.8 * intensity);
              return Padding(
                padding: const EdgeInsets.all(2),
                child: Tooltip(
                  message: '${day.toLocal().toIso8601String().split('T').first}: $val 分钟',
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习记录')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 自定义周期选择栏
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.lightGreen[100],
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: Period.values.map((p) {
                        final isSelected = p == _selectedPeriod;
                        final label = {
                          Period.day: '日',
                          Period.week: '周',
                          Period.month: '月',
                          Period.year: '年',
                        }[p]!;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedPeriod = p),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              height: 28,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.green : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white : Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 热力图标题与帮助图标
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('热力图', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('热力图说明'),
                              content: const Text('热力图展示最近20周的学习时长，小方块代表一天，颜色深度与当日学习时长成正比，未学习为浅色。'),
                              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('我知道了'))],
                            ),
                          );
                        },
                        child: const Icon(Icons.help_outline, size: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(height: 200, child: _buildHeatMap()),
                  const SizedBox(height: 16),
                  const Text('学习时长统计表', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // 自定义条形图展示学习时长
                  _buildBarChart(),
                ],
              ),
            ),
    );
  }

  /// 自定义条形图，展示每日学习时长柱状
  Widget _buildBarChart() {
    final entries = _entriesForPeriod();
    final maxVal = entries.fold<int>(0, (prev, e) => e.value > prev ? e.value : prev);
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: entries.map((e) {
          final double factor = maxVal > 0 ? e.value / maxVal : 0.0;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 200 * factor,
                  width: 10,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${e.key.month}/${e.key.day}',
                  style: const TextStyle(fontSize: 8),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
} 