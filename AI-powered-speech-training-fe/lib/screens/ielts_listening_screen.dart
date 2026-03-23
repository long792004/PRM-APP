import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'exam_result_screen.dart';

class IeltsListeningScreen extends StatefulWidget {
  final String examId;
  final String title;
  final String audioUrl;
  final List<dynamic> questions; // Danh sách câu hỏi từ API
  final bool isPartOfFullExam;

  const IeltsListeningScreen({
    super.key,
    required this.examId,
    required this.title,
    required this.audioUrl,
    required this.questions,
    this.isPartOfFullExam = false,
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
        
        if (widget.isPartOfFullExam) {
          Navigator.pop(context, result);
        } else {
          // Thay vì pop, ta điều hướng sang màn hình kết quả chi tiết
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ExamResultScreen(resultData: result),
            ),
          );
        }
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: AppColors.gray900, fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.gray900),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Color(0xFFFFFFFF)],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAudioPlayerUI(),
              Expanded(
                child: _buildQuestionsView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioPlayerUI() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15),
              ),
              Text(
                _formatDuration(_duration),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray500, fontSize: 15),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withOpacity(0.15),
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
                icon: const Icon(Icons.replay_10_rounded, color: AppColors.gray700),
                iconSize: 36,
                onPressed: _seekBackward,
              ),
              const SizedBox(width: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: IconButton(
                  icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: AppColors.white),
                  iconSize: 36,
                  onPressed: _togglePlayPause,
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.forward_10_rounded, color: AppColors.gray700),
                iconSize: 36,
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
      color: Colors.transparent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.quiz_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Text(
                  'Questions (1 - ${widget.questions.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(color: AppColors.gray200.withOpacity(0.5)),
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.primaryLight, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submitAnswers,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
              : const Icon(Icons.check_circle_rounded, color: AppColors.white),
          label: Text(
            _isSubmitting ? 'Đang nộp bài...' : 'Hoàn thành bài thi',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}
