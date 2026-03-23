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
  final bool isPartOfFullExam;

  const IeltsSpeakingScreen({
    super.key,
    required this.questionId,
    required this.prompt,
    this.isPartOfFullExam = false,
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
            _stopAndSubmit();
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
        
        if (path != null) {
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
            path: path,
          );
        } else {
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
            path: '', // For web, a non-null string is needed but the content is ignored or handled. Let's look at the API. Or better, just use start()
          );
        }

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

  Future<void> _stopAndSubmit() async {
    _timer?.cancel();
    final path = await _audioRecorder.stop();
    debugPrint("STOPPED RECORDING. PATH RETURNED: $path");
    setState(() {
      _isRecording = false;
      _audioPath = path;
    });
    // Auto submit right after stop
    if (path != null && path.isNotEmpty) {
      _submitRecording();
    }
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
        if (widget.isPartOfFullExam) {
          Navigator.pop(context, result);
        } else {
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
      }
    } catch (e, stacktrace) {
      if (mounted) {
        debugPrint("SUBMIT ERROR: $e");
        debugPrint(stacktrace.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 10),
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
    
    // Define status configuration purely for UI variables
    Color statusColor = _isPreparing ? AppColors.warning : (_isRecording ? AppColors.error : AppColors.success);
    String statusText = _isPreparing ? 'Preparation Time' : (_isRecording ? 'Speaking Time' : 'Completed');
    IconData statusIcon = _isPreparing ? Icons.timer_outlined : (_isRecording ? Icons.mic_none_outlined : Icons.check_circle_outline);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('IELTS Speaking Part 2', 
          style: TextStyle(color: AppColors.gray900, fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.gray900),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEFF6FF), // soft blue top
              Color(0xFFFFFFFF), // solid white bottom
            ],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40.0, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Floating Timer Pill
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(_currentCountdown),
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: statusColor,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Enhanced Cue Card
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.06),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: AppColors.gray200.withOpacity(0.5),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Card Header
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBg.withOpacity(0.5),
                              border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
                            ),
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
                                  child: const Icon(Icons.assignment_ind_rounded, color: AppColors.primary, size: 22),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  'Candidate Task Card',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gray900,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Card Body
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(28.0),
                              child: Text(
                                widget.prompt,
                                style: const TextStyle(
                                  fontSize: 17,
                                  height: 1.8,
                                  color: AppColors.gray800,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Record Area
                _buildRecordButton(),
                const SizedBox(height: 20),
              ],
            ),
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
          onTap: _isEvaluating ? null : (_isPreparing
              ? _startRecording
              : (_isRecording ? _stopAndSubmit : null)),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final scale = _isRecording ? 1.0 + (_animationController.value * 0.15) : 1.0;
              final Color glowColor = _isRecording ? AppColors.error : AppColors.primary;
              
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow
                  if (_isRecording || _isPreparing)
                    Container(
                      width: 100 * scale,
                      height: 100 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: glowColor.withOpacity(_isRecording ? 0.2 : 0.05),
                      ),
                    ),
                  // Inner Pulse
                  if (_isRecording)
                    Container(
                      width: 85 * scale,
                      height: 85 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: glowColor.withOpacity(0.3),
                      ),
                    ),
                  // Main Button
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isRecording 
                            ? [const Color(0xFFFF6B6B), AppColors.error]
                            : [AppColors.primaryLight, AppColors.primary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                          spreadRadius: _isRecording ? (_animationController.value * 5) : 0,
                        )
                      ],
                    ),
                    child: Icon(
                      _isPreparing ? Icons.mic_rounded : (_isRecording ? Icons.stop_rounded : Icons.check_rounded),
                      color: AppColors.white,
                      size: 38,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        
        // Action Text Button
        if (_isPreparing || _isRecording)
          InkWell(
            onTap: _isEvaluating ? null : () {
              if (_isPreparing) {
                _startRecording();
              } else if (_isRecording) {
                _stopAndSubmit();
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_isPreparing ? Icons.play_circle_fill_rounded : Icons.check_circle_rounded, 
                    color: _isPreparing ? AppColors.primary : AppColors.error, 
                    size: 20
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isPreparing ? 'Bỏ qua chuẩn bị & Bắt đầu nói ngay' : 'Dừng & Nộp Bài',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _isPreparing ? AppColors.primary : AppColors.error,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: const BorderSide(color: AppColors.gray300, width: 1.5),
            backgroundColor: AppColors.white,
          ),
          icon: const Icon(Icons.refresh_rounded, color: AppColors.gray700),
          label: const Text('Thu âm lại', style: TextStyle(color: AppColors.gray800, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _isEvaluating ? null : _submitRecording,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: AppColors.primary.withOpacity(0.5),
          ),
          icon: _isEvaluating
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white))
              : const Icon(Icons.send_rounded, color: AppColors.white),
          label: Text(
            _isEvaluating ? 'AI Đang chấm...' : 'Nộp bài',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
          ),
        ),
      ],
    );
  }
}
