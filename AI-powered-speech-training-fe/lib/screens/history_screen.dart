import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recording.dart';
import '../models/feedback.dart' as model;
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  final Function(Recording) onViewRecording;

  const HistoryScreen({
    super.key,
    required this.onViewRecording,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Recording>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _historyFuture = ApiService.getHistory().then((data) => data.map((json) {
          final map = json as Map<String, dynamic>;
          final fb = map['feedback'] as Map<String, dynamic>?;
          return Recording(
            id: map['id'] as String,
            topicId: map['topicId'] as String,
            topicTitle: map['topicTitle'] as String,
            audioUrl: map['audioUrl'] as String,
            duration: map['duration'] as int,
            createdAt: map['createdAt'] as String,
            transcript: map['transcript'] as String? ?? '',
            feedback: fb != null
                ? model.Feedback.fromJson(fb)
                : model.Feedback(
                    overall: 0, fluency: 0, pronunciation: 0,
                    grammar: 0, vocabulary: 0, coherence: 0,
                    strengths: [], issues: [], suggestions: [],
                  ),
          );
        }).toList());
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return FutureBuilder<List<Recording>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        final recordings = snapshot.data ?? [];

        final totalRecordings = recordings.length;
        final avgScore = recordings.isEmpty
            ? 0.0
            : recordings.map((r) => r.feedback.overall).reduce((a, b) => a + b) /
                recordings.length;
        final todayRecordings = recordings
            .where((r) =>
                DateTime.parse(r.createdAt).day == DateTime.now().day &&
                DateTime.parse(r.createdAt).month == DateTime.now().month)
            .length;
        final totalMinutes = recordings.isEmpty
            ? 0
            : recordings.map((r) => r.duration).reduce((a, b) => a + b) ~/ 60;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lịch sử luyện tập',
              style: TextStyle(
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Xem lại các bài luyện nói và theo dõi tiến độ',
              style: TextStyle(fontSize: 16, color: AppColors.gray600),
            ),
            const SizedBox(height: 24),

            // Stats
            GridView.count(
              crossAxisCount: isMobile ? 2 : 4,
              shrinkWrap: true,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isMobile ? 1.5 : 2,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StatCard(title: 'Tổng bài luyện', value: totalRecordings.toString(), icon: Icons.book_outlined, color: AppColors.primary),
                _StatCard(title: 'Điểm TB', value: avgScore.toStringAsFixed(1), icon: Icons.star_outline, color: AppColors.warning),
                _StatCard(title: 'Hôm nay', value: todayRecordings.toString(), icon: Icons.today_outlined, color: AppColors.success),
                _StatCard(title: 'Tổng thời gian', value: '${totalMinutes}m', icon: Icons.timer_outlined, color: AppColors.secondary),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : snapshot.hasError
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                              const SizedBox(height: 16),
                              Text('${snapshot.error}', textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => setState(() => _loadHistory()),
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        )
                      : recordings.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history, size: 64, color: AppColors.gray300),
                                  SizedBox(height: 16),
                                  Text('Chưa có bài luyện nào', style: TextStyle(fontSize: 16, color: AppColors.gray500)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async => setState(() => _loadHistory()),
                              child: ListView.separated(
                                itemCount: recordings.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final recording = recordings[index];
                                  return _RecordingCard(
                                    recording: recording,
                                    onTap: () => widget.onViewRecording(recording),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.gray600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 24 : 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _RecordingCard extends StatelessWidget {
  final Recording recording;
  final VoidCallback onTap;

  const _RecordingCard({
    required this.recording,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final date = DateTime.parse(recording.createdAt);
    final dateStr = DateFormat('HH:mm dd/MM/yyyy').format(date);
    final durationStr =
        '${(recording.duration ~/ 60)}:${(recording.duration % 60).toString().padLeft(2, '0')}';

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Topic Info
                    Text(
                      recording.topicTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: AppColors.gray500),
                            const SizedBox(width: 6),
                            Text(dateStr, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time, size: 14, color: AppColors.gray500),
                            const SizedBox(width: 6),
                            Text(durationStr, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Scores
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall: ${recording.feedback.overall.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ScoreChip(label: 'Fluency', score: recording.feedback.fluency),
                              _ScoreChip(label: 'Grammar', score: recording.feedback.grammar),
                              _ScoreChip(label: 'Vocab', score: recording.feedback.vocabulary),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(icon: const Icon(Icons.headphones), onPressed: () {}, tooltip: 'Nghe lại'),
                        OutlinedButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.visibility, size: 18),
                          label: const Text('Chi tiết'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Topic Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recording.topicTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: AppColors.gray500,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gray600,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppColors.gray500,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                durationStr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gray600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Scores
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Overall: ${recording.feedback.overall.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _ScoreChip(
                                label: 'Fluency',
                                score: recording.feedback.fluency,
                              ),
                              const SizedBox(width: 8),
                              _ScoreChip(
                                label: 'Grammar',
                                score: recording.feedback.grammar,
                              ),
                              const SizedBox(width: 8),
                              _ScoreChip(
                                label: 'Vocab',
                                score: recording.feedback.vocabulary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Actions
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.headphones),
                          onPressed: () {},
                          tooltip: 'Nghe lại',
                        ),
                        OutlinedButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.visibility, size: 18),
                          label: const Text('Xem chi tiết'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final double score;

  const _ScoreChip({
    required this.label,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Text(
        '$label: ${score.toStringAsFixed(1)}',
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.gray700,
        ),
      ),
    );
  }
}
