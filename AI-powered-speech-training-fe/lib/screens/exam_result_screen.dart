import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class ExamResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const ExamResultScreen({super.key, required this.resultData});

  @override
  Widget build(BuildContext context) {
    final feedback = resultData['feedback'] ?? {};
    final double overall = (feedback['overall'] as num?)?.toDouble() ?? 0.0;
    final double fluency = (feedback['fluency'] as num?)?.toDouble() ?? 0.0;
    final double pronunciation = (feedback['pronunciation'] as num?)?.toDouble() ?? 0.0;
    final double grammar = (feedback['grammar'] as num?)?.toDouble() ?? 0.0;
    final double vocabulary = (feedback['vocabulary'] as num?)?.toDouble() ?? 0.0;
    final double coherence = (feedback['coherence'] as num?)?.toDouble() ?? 0.0;

    final String transcript = resultData['transcript'] ?? '';
    final List<String> issues = List<String>.from(feedback['issues'] ?? []);
    final List<String> suggestions = List<String>.from(feedback['suggestions'] ?? []);
    final List<String> strengths = List<String>.from(feedback['strengths'] ?? []);

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detailed Evaluation', style: TextStyle(color: AppColors.gray900)),
        backgroundColor: AppColors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.gray900),
      ),
      backgroundColor: AppColors.gray50,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Chart & Overall Score Section
              _buildScoreOverview(
                overall: overall,
                fluency: fluency,
                pronunciation: pronunciation,
                grammar: grammar,
                vocabulary: vocabulary,
                coherence: coherence,
                isMobile: isMobile,
              ),
              const SizedBox(height: 24),

              // Transcript & Highlights
              if (transcript.isNotEmpty)
                _buildTranscriptSection(transcript, issues),

              const SizedBox(height: 24),

              // Issues & Suggestions List
              if (issues.isNotEmpty || suggestions.isNotEmpty)
                _buildCorrectionsSection(issues, suggestions),

              const SizedBox(height: 24),

              // Strengths List
              if (strengths.isNotEmpty)
                _buildStrengthsSection(strengths),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreOverview({
    required double overall,
    required double fluency,
    required double pronunciation,
    required double grammar,
    required double vocabulary,
    required double coherence,
    required bool isMobile,
  }) {
    // 5 criteria for radar chart
    final criteriaInfo = [
      {'name': 'Fluency', 'score': fluency},
      {'name': 'Pronunciation', 'score': pronunciation},
      {'name': 'Grammar', 'score': grammar},
      {'name': 'Vocabulary', 'score': vocabulary},
      {'name': 'Coherence', 'score': coherence},
    ];

    final chartWidget = SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RadarChart(
            RadarChartData(
              dataSets: [
                RadarDataSet(
                  fillColor: AppColors.primary.withOpacity(0.2),
                  borderColor: AppColors.primary,
                  entryRadius: 3,
                  dataEntries: criteriaInfo
                      .map((c) => RadarEntry(value: c['score'] as double))
                      .toList(),
                  borderWidth: 2,
                )
              ],
              radarBackgroundColor: Colors.transparent,
              borderData: FlBorderData(show: false),
              radarBorderData: const BorderSide(color: Colors.transparent),
              getTitle: (index, angle) {
                final name = criteriaInfo[index]['name'] as String;
                final score = criteriaInfo[index]['score'] as double;
                return RadarChartTitle(
                  text: '$name\n$score',
                  angle: angle,
                  positionPercentageOffset: 0.1,
                );
              },
              radarShape: RadarShape.polygon,
              tickCount: 9,
              ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 10),
              tickBorderData: BorderSide(color: AppColors.gray300.withOpacity(0.5)),
              gridBorderData: BorderSide(color: AppColors.gray300.withOpacity(0.5), width: 1.5),
            ),
            swapAnimationDuration: const Duration(milliseconds: 400),
          ),
          // Overall Score in the center of Radar Chart
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Band',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray500,
                ),
              ),
              Text(
                overall.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Performance Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900),
            ),
            const SizedBox(height: 24),
            chartWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptSection(String transcript, List<String> issues) {
    // A simple logic to try highlighting text from 'issues'.
    // Since GPT gives descriptive strings for issues (not exact substrings),
    // substring matching might not always hit. We will try to do a robust split if possible,
    // otherwise fallback to normal text.
    
    // Convert transcript to lowercase for searching, but keep original for display
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.notes, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Transcription / Essay',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildHighlightedText(transcript, issues),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, List<String> tokensToHighlight) {
    // If we had exact mistaken words, we could highlight them.
    // For now, let's just return normal text since "issues" from GPT
    // are usually descriptive sentences like: "Grammar issue: used 'done' instead of 'did'".
    // If the user meant literal phrases to be highlighted, we can try to extract quotes.
    
    final List<String> highlightPhrases = [];
    for (var issue in tokensToHighlight) {
      // Extract strings within quotes if any ('...' or "...")
      var matches = RegExp(r"['""](.*?)['""]").allMatches(issue);
      for (var m in matches) {
        if (m.group(1) != null && m.group(1)!.trim().length > 2) {
          highlightPhrases.add(m.group(1)!);
        }
      }
    }

    if (highlightPhrases.isEmpty) {
       return Text(
        text,
        style: const TextStyle(fontSize: 16, height: 1.6, color: AppColors.gray800),
      );
    }

    // A simplistic highlight approach
    List<TextSpan> spans = [];
    String remaining = text;
    
    // Sort phrases by length descending to match longest first
    highlightPhrases.sort((a, b) => b.length.compareTo(a.length));

    for (var phrase in highlightPhrases) {
      // we only do a very simple first match per phrase for demonstration
      final int idx = remaining.toLowerCase().indexOf(phrase.toLowerCase());
      if (idx != -1) {
        spans.add(TextSpan(text: remaining.substring(0, idx)));
        spans.add(TextSpan(
          text: remaining.substring(idx, idx + phrase.length),
          style: const TextStyle(
            backgroundColor: Color(0xFFFFE0B2), // Orange-light
            color: AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ));
        remaining = remaining.substring(idx + phrase.length);
      }
    }
    spans.add(TextSpan(text: remaining));

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, height: 1.6, color: AppColors.gray800),
        children: spans.isEmpty ? [TextSpan(text: text)] : spans,
      ),
    );
  }

  Widget _buildCorrectionsSection(List<String> issues, List<String> suggestions) {
    final itemCount = issues.length > suggestions.length ? issues.length : suggestions.length;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.build_circle_outlined, color: AppColors.error),
                SizedBox(width: 8),
                Text(
                  'Issues & Corrections',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900),
                ),
              ],
            ),
            const Divider(height: 32),
            ...List.generate(itemCount, (index) {
              final issueText = index < issues.length ? issues[index] : '';
              final suggestionText = index < suggestions.length ? suggestions[index] : '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Text(
                          issueText.isNotEmpty ? issueText : '--',
                          style: const TextStyle(color: AppColors.error, fontSize: 14),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.arrow_forward_rounded, color: AppColors.gray400),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: Text(
                          suggestionText.isNotEmpty ? suggestionText : '--',
                          style: const TextStyle(color: AppColors.success, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthsSection(List<String> strengths) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.star_border_rounded, color: AppColors.success),
                SizedBox(width: 8),
                Text(
                  'Strengths to Keep',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900),
                ),
              ],
            ),
            const Divider(height: 32),
            ...strengths.map((str) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      str,
                      style: const TextStyle(fontSize: 15, color: AppColors.gray800, height: 1.4),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}
