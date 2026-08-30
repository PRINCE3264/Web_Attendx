import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AIVoiceAssistantSheet extends StatefulWidget {
  const AIVoiceAssistantSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      builder: (_) => const AIVoiceAssistantSheet(),
    );
  }

  @override
  State<AIVoiceAssistantSheet> createState() => _AIVoiceAssistantSheetState();
}

class _AIVoiceAssistantSheetState extends State<AIVoiceAssistantSheet> with SingleTickerProviderStateMixin {
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  bool _isProcessing = false;
  String _statusText = "Hold to speak...";
  String? _transcription;
  String? _aiResponse;
  
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/temp_audio.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
          path: path,
        );
        
        setState(() {
          _isRecording = true;
          _statusText = "Listening...";
          _transcription = null;
          _aiResponse = null;
        });
      }
    } catch (e) {
      debugPrint("Error starting record: $e");
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _statusText = "AI is thinking...";
      });

      if (path != null) {
        await _processAudio(path);
      }
    } catch (e) {
      debugPrint("Error stopping record: $e");
      setState(() {
        _isProcessing = false;
        _statusText = "Error recording audio.";
      });
    }
  }

  Future<void> _processAudio(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);

      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('askVoiceAssistant');
      
      final result = await callable.call(<String, dynamic>{
        'audioBase64': base64Audio,
      });

      final data = result.data as Map<dynamic, dynamic>;
      final responseText = data['text'] as String;
      final transcriptionText = data['transcription'] as String;
      final responseAudioBase64 = data['audioBase64'] as String;

      setState(() {
        _transcription = transcriptionText;
        _aiResponse = responseText;
        _isProcessing = false;
        _statusText = "AI responded.";
      });

      // Play the audio
      final audioBytes = base64Decode(responseAudioBase64);
      await _audioPlayer.play(BytesSource(audioBytes));

    } catch (e) {
      debugPrint("Cloud Function Error: $e");
      setState(() {
        _isProcessing = false;
        _statusText = "Error communicating with AI.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPadding > 0 ? bottomPadding + 16 : 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(
              'AttendX AI Assistant',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            
            if (_transcription != null) ...[
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16).copyWith(bottomRight: const Radius.circular(0)),
                  ),
                  child: Text(
                    '"$_transcription"',
                    style: GoogleFonts.inter(fontSize: 15, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_aiResponse != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: const Radius.circular(0)),
                  ),
                  child: Text(
                    _aiResponse!,
                    style: GoogleFonts.inter(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            Text(
              _statusText,
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecording(),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.redAccent : Theme.of(context).primaryColor,
                      boxShadow: [
                        if (_isRecording || _isProcessing)
                          BoxShadow(
                            color: (_isRecording ? Colors.redAccent : Theme.of(context).primaryColor).withOpacity(0.5),
                            blurRadius: 20 + (10 * _pulseController.value),
                            spreadRadius: 5 + (5 * _pulseController.value),
                          )
                      ],
                    ),
                    child: Icon(
                      _isProcessing ? Icons.hourglass_empty : Icons.mic,
                      color: Colors.white,
                      size: 36,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hold to talk',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
    );
  }
}

class AIVoiceButton extends StatelessWidget {
  const AIVoiceButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'ai_voice_btn',
      backgroundColor: Colors.indigoAccent,
      onPressed: () => AIVoiceAssistantSheet.show(context),
      child: const Icon(Icons.graphic_eq, color: Colors.white),
    );
  }
}
