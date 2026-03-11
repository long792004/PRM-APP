import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'exam_result_screen.dart';

class IeltsSpeakingScreen extends StatefulWidget {
  final String questionId;
  final String prompt; // Part 2 Cue Card content

  const IeltsSpeakingScreen({
    super.key,
    required this.questionId,
    required this.prompt,
  });

  @override
  State<IeltsSpeakingScreen> createState() => _IeltsSpeakingScreenState();
}

class _IeltsSpeakingScreenState extends State<IeltsSpeakingScreen> with SingleTickerProviderStateMixin {
  late AudioRecorder _audioRecorder;
  String? _audioPath;

  bool _isRecording = false;
  bool _isEvaluating = false;
  bool _isPreparing = true;

  Timer? _timer;
  int _secondsElapsed = 0;
  
  // Thời gian đếm ngược
  final int _prepSeconds = 60; // 1 phút chuẩn bị
  final int _speakSeconds = 120; // 2 phút nói
  int _currentCountdown = 60;

  // Animation cho luồng sóng âm
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _currentCountdown = _prepSeconds;
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_currentCountdown > 0) {
          _currentCountdown--;
        } else {
          // Hết giờ
          _timer?.cancel();
          if (_isPreparing) {
            // Tự động chuyển qua thu âm
            _startRecording();
          } else if (_isRecording) {
            // Tự động dừng thu âm
            _stopRecording();
          }
        }
      });
    });
  }

  Future<void> _startRecording() async {
    try {
      if (kIsWeb || await Permission.microphone.request().isGranted) {
        String? path;
        if (!kIsWeb) {
          final directory = await getTemporaryDirectory();
          path = '${directory.path}/speaking_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }
        
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
          path: path,
        );

        setState(() {
          _isPreparing = false;
          _isRecording = true;
          _currentCountdown = _speakSeconds; // Đếm ngược 2 phút nói
        });
        
        _startTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng cấp quyền Microphone để thu âm.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _audioPath = path;
    });
  }

  Future<void> _submitRecording() async {
    if (_audioPath == null) return;
    
    if (!kIsWeb) {
      final file = File(_audioPath!);
      if (!await file.exists()) return;
    }

    setState(() => _isEvaluating = true);
    
    try {
      final result = await ApiService.submitSpeaking(widget.questionId, _audioPath!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nộp bài thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ExamResultScreen(resultData: result),
          ),
        );
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
      if (mounted) setState(() => _isEvaluating = false);
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('IELTS Speaking Part 2', style: TextStyle(color: AppColors.gray900)),
        backgroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.gray900),
        elevation: 1,
      ),
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Trạng thái Timer
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isPreparing 
                      ? AppColors.warning.withOpacity(0.1) 
                      : (_isRecording ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isPreparing 
                        ? AppColors.warning 
                        : (_isRecording ? AppColors.error : AppColors.success),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _isPreparing 
                          ? 'Preparation Time' 
                          : (_isRecording ? 'Speaking Time' : 'Completed'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isPreparing 
                            ? AppColors.warning 
                            : (_isRecording ? AppColors.error : AppColors.success),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(_currentCountdown),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: _isPreparing 
                            ? AppColors.warning 
                            : (_isRecording ? AppColors.error : AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Cue Card
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.assignment_ind_outlined, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text(
                                'Candidate Task Card',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Text(
                            widget.prompt,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.8,
                              color: AppColors.gray900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Vùng Thu Âm
              SizedBox(
                height: 180,
                child: Center(
                  child: _audioPath == null
                      ? _buildRecordButton()
                      : _buildActionButtons(),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _isPreparing
              ? _startRecording
              : (_isRecording ? _stopRecording : null),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final scale = _isRecording ? 1.0 + (_animationController.value * 0.15) : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? AppColors.error : AppColors.primary,
                    boxShadow: [
                      if (_isRecording)
                        BoxShadow(
                          color: AppColors.error.withOpacity(0.5),
                          blurRadius: 20 * _animationController.value,
                          spreadRadius: 10 * _animationController.value,
                        )
                      else
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                    ],
                  ),
                  child: Icon(
                    _isPreparing ? Icons.mic : (_isRecording ? Icons.stop : Icons.mic),
                    color: AppColors.white,
                    size: 36,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            if (_isPreparing) {
              _startRecording();
            } else if (_isRecording) {
              _stopRecording();
            }
          },
          icon: Icon(_isPreparing ? Icons.play_arrow_rounded : Icons.check_circle_outline),
          label: Text(
            _isPreparing ? 'Bỏ qua chuẩn bị & Bắt đầu nói ngay' : 'Dừng & Chờ Nộp Bài Ngay',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isPreparing ? AppColors.primary : AppColors.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _isEvaluating
                  ? null
                  : () {
                      setState(() {
                        _audioPath = null;
                        _isPreparing = true;
                        _isRecording = false;
                        _currentCountdown = _prepSeconds;
                      });
                      _startTimer();
                    },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh, color: AppColors.gray600),
              label: const Text('Thu âm lại', style: TextStyle(color: AppColors.gray600)),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _isEvaluating ? null : _submitRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              icon: _isEvaluating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                  : const Icon(Icons.send_rounded, color: AppColors.white),
              label: Text(
                _isEvaluating ? 'AI đang chấm...' : 'Nộp bài',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
