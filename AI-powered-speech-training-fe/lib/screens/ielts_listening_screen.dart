import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class IeltsListeningScreen extends StatefulWidget {
  final String examId;
  final String title;
  final String audioUrl;
  final List<dynamic> questions; // Danh sách câu hỏi từ API

  const IeltsListeningScreen({
    super.key,
    required this.examId,
    required this.title,
    required this.audioUrl,
    required this.questions,
  });

  @override
  State<IeltsListeningScreen> createState() => _IeltsListeningScreenState();
}

class _IeltsListeningScreenState extends State<IeltsListeningScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Map lưu trữ đáp án của user. Key = questionId, Value = userAnswer
  final Map<String, String> _userAnswers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() async {
    // Set source for the audio player
    try {
      debugPrint("Đang nạp audio URL: ${widget.audioUrl}");
      await _audioPlayer.setSource(UrlSource(widget.audioUrl));
    } catch (e) {
      debugPrint("Lỗi tải âm thanh: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải file nghe: $e'), backgroundColor: AppColors.error),
        );
      }
    }

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  void _seekBackward() {
    final newPosition = _position - const Duration(seconds: 10);
    if (newPosition < Duration.zero) {
      _audioPlayer.seek(Duration.zero);
    } else {
      _audioPlayer.seek(newPosition);
    }
  }

  void _seekForward() {
    final newPosition = _position + const Duration(seconds: 10);
    if (newPosition > _duration) {
      _audioPlayer.seek(_duration);
    } else {
      _audioPlayer.seek(newPosition);
    }
  }

  void _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_duration == Duration.zero) {
           // Nếu chưa load được duration, nỗ lực set lại source
           await _audioPlayer.setSource(UrlSource(widget.audioUrl));
        }
        await _audioPlayer.resume();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi phát âm thanh: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _submitAnswers() async {
    // Thu thập tất cả câu trả lời
    final List<Map<String, String>> answersPayload = [];
    for (var q in widget.questions) {
      final qId = q['id'].toString();
      final answer = _userAnswers[qId] ?? '';
      answersPayload.add({
        'questionId': qId,
        'userAnswer': answer,
      });
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await ApiService.submitObjective(widget.examId, answersPayload);
      if (mounted) {
        _audioPlayer.stop(); // Dừng nhạc khi nộp bài thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nộp bài thành công! Bạn đúng ${result['correctCount']}/${result['totalQuestions']} câu.'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: AppColors.gray900)),
        backgroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.gray900),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: _buildAudioPlayerUI(),
        ),
      ),
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        child: Column(
          children: [
            const Divider(height: 1, thickness: 1, color: AppColors.gray200),
            Expanded(
              child: _buildQuestionsView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayerUI() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray700),
              ),
              Text(
                _formatDuration(_duration),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray700),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withOpacity(0.2),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.1),
            ),
            child: Slider(
              min: 0,
              max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
              value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0),
              onChanged: (val) {
                _audioPlayer.seek(Duration(seconds: val.toInt()));
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10, color: AppColors.gray800),
                iconSize: 32,
                onPressed: _seekBackward,
              ),
              const SizedBox(width: 16),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: AppColors.white),
                  iconSize: 32,
                  onPressed: _togglePlayPause,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.forward_10, color: AppColors.gray800),
                iconSize: 32,
                onPressed: _seekForward,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsView() {
    return Container(
      color: AppColors.gray50,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(bottom: BorderSide(color: AppColors.gray200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Questions (1 - ${widget.questions.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.questions.length + 1, // +1 for submit button
              itemBuilder: (context, index) {
                if (index == widget.questions.length) {
                  return _buildSubmitButton();
                }
                final question = widget.questions[index];
                return _buildQuestionItem(question, index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(dynamic question, int questionNumber) {
    final qId = question['id'].toString();
    final qText = question['questionText'] ?? '';
    final qType = question['questionType'] ?? 'MULTIPLE_CHOICE';
    final content = question['content'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$questionNumber',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      qText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray900,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (qType == 'FILL_BLANK')
              TextField(
                onChanged: (val) {
                  setState(() => _userAnswers[qId] = val);
                },
                decoration: InputDecoration(
                  hintText: 'Nhập câu trả lời của bạn',
                  filled: true,
                  fillColor: AppColors.gray50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.gray300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.gray300),
                  ),
                ),
              )
            else if (qType == 'MULTIPLE_CHOICE' && content != null && content['options'] != null)
              ...List.generate(
                (content['options'] as List).length,
                (i) {
                  final option = content['options'][i].toString();
                  return RadioListTile<String>(
                    title: Text(option),
                    value: option,
                    groupValue: _userAnswers[qId],
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _userAnswers[qId] = val);
                      }
                    },
                  );
                },
              )
            else
              TextField(
                onChanged: (val) {
                  setState(() => _userAnswers[qId] = val);
                },
                decoration: const InputDecoration(hintText: 'A, B, C, or D'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitAnswers,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: _isSubmitting
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
            : const Icon(Icons.check_circle_outline, color: AppColors.white),
        label: Text(
          _isSubmitting ? 'Đang nộp bài...' : 'Hoàn thành bài thi',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
