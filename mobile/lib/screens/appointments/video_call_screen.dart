import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallScreen extends StatefulWidget {
  final int appointmentId;
  final String roomId;
  final String? domain;
  final String consultationType;
  final String? doctorName;
  final String? doctorImage;

  const VideoCallScreen({
    super.key,
    required this.appointmentId,
    required this.roomId,
    this.domain,
    required this.consultationType,
    this.doctorName,
    this.doctorImage,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final JitsiMeet _jitsiMeet = JitsiMeet();
  bool _isConnecting = true;
  bool _isInCall = false;
  bool _isMuted = false;
  bool _isVideoOff = false;
  int _callDuration = 0;
  Timer? _timer;
  String? _error;

  // AI Clinical notes
  final List<Map<String, String>> _aiNotes = [];

  @override
  void initState() {
    super.initState();
    _joinMeeting();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _jitsiMeet.hangUp();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _callDuration++);
    });
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _joinMeeting() async {
    try {
      // Request required permissions before joining
      final permissions = await [
        Permission.camera,
        Permission.microphone,
        Permission.bluetoothConnect,
      ].request();

      // Check if essential permissions are granted
      if (permissions[Permission.camera]?.isDenied == true ||
          permissions[Permission.microphone]?.isDenied == true) {
        setState(() {
          _error =
              'Camera and microphone permissions are required for video calls';
          _isConnecting = false;
        });
        return;
      }

      final options = JitsiMeetConferenceOptions(
        serverURL: 'https://${widget.domain ?? 'meet.jit.si'}',
        room: widget.roomId,
        configOverrides: {
          'startWithAudioMuted': false,
          'startWithVideoMuted': false,
          'subject': 'Medical Consultation',
        },
        featureFlags: {
          'welcomepage.enabled': false,
          'prejoinpage.enabled': false,
          'invite.enabled': false,
          'recording.enabled': false,
          'live-streaming.enabled': false,
          'meeting-name.enabled': false,
          'call-integration.enabled': true,
          'pip.enabled': true,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: 'Patient',
          email: '',
        ),
      );

      // Set up event listeners
      final listener = JitsiMeetEventListener(
        conferenceJoined: (url) {
          setState(() {
            _isConnecting = false;
            _isInCall = true;
          });
          _startTimer();
          // Add initial AI note
          _addAiNote('Session started', 'Connection established with doctor');
        },
        conferenceTerminated: (url, error) {
          _timer?.cancel();
          if (mounted) {
            context.pop();
          }
        },
        participantJoined: (email, name, role, participantId) {
          _addAiNote('Participant joined', '$name has joined the call');
        },
        audioMutedChanged: (muted) {
          setState(() => _isMuted = muted);
        },
        videoMutedChanged: (muted) {
          setState(() => _isVideoOff = muted);
        },
      );

      await _jitsiMeet.join(options, listener);
    } catch (e) {
      setState(() {
        _error = 'Failed to join: $e';
        _isConnecting = false;
      });
    }
  }

  void _addAiNote(String title, String content) {
    setState(() {
      _aiNotes
          .insert(0, {'title': title, 'content': content, 'time': 'Just Now'});
      if (_aiNotes.length > 5) _aiNotes.removeLast();
    });
  }

  Future<void> _toggleMute() async {
    await _jitsiMeet.setAudioMuted(!_isMuted);
    setState(() => _isMuted = !_isMuted);
  }

  Future<void> _toggleVideo() async {
    await _jitsiMeet.setVideoMuted(!_isVideoOff);
    setState(() => _isVideoOff = !_isVideoOff);
  }

  Future<void> _endCall() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('End Call?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to end this consultation?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('End Call'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _jitsiMeet.hangUp();
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnecting) {
      return _buildConnectingScreen();
    }

    if (_error != null) {
      return _buildErrorScreen();
    }

    // Jitsi handles its own UI, but we show our overlay when minimized
    return Scaffold(
      backgroundColor: const Color(0xFF101822),
      body: Stack(
        children: [
          // Jitsi Meet handles the video UI internally
          // We just show our custom overlays

          // Top Bar Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _buildTopBar(),
            ),
          ),

          // AI Clinical Notes Overlay
          if (_aiNotes.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: _buildAiNoteCard(_aiNotes.first),
            ),

          // Control Dock
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildControlDock(),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF101822),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF136DEC).withOpacity(0.1),
              ),
              child: const Icon(Icons.videocam,
                  size: 48, color: Color(0xFF136DEC)),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Color(0xFF136DEC)),
            const SizedBox(height: 24),
            const Text(
              'Connecting to consultation...',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Room: ${widget.roomId}',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF101822),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101822),
        title: const Text('Connection Error'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isConnecting = true;
                  });
                  _joinMeeting();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF101822).withOpacity(0.95),
        border: Border(
            bottom: BorderSide(color: Colors.grey.shade800.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          // Doctor Avatar with status
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF136DEC).withOpacity(0.2),
                  border: Border.all(
                      color: const Color(0xFF136DEC).withOpacity(0.2),
                      width: 2),
                ),
                child: widget.doctorImage != null
                    ? ClipOval(
                        child: Image.network(widget.doctorImage!,
                            fit: BoxFit.cover))
                    : const Icon(Icons.person, color: Color(0xFF136DEC)),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFF101822), width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Doctor info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.doctorName ?? 'Doctor',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.lock, size: 12, color: const Color(0xFF136DEC)),
                    const SizedBox(width: 4),
                    Text(
                      'Encrypted',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text('•',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ),
                    Text(
                      _formatDuration(_callDuration),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Color(0xFF136DEC),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // End Call Button
          GestureDetector(
            onTap: _endCall,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.call_end, size: 18, color: Colors.red.shade400),
                  const SizedBox(width: 8),
                  Text(
                    'End',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiNoteCard(Map<String, String> note) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101822).withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF136DEC).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.medical_services,
                color: Color(0xFF136DEC), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AI Clinical Note',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        note['time'] ?? '',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade400),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  note['content'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlDock() {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF101822),
        border: Border(
            top: BorderSide(color: Colors.grey.shade800.withOpacity(0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: 'Mute',
            isActive: _isMuted,
            onTap: _toggleMute,
          ),
          _buildControlButton(
            icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
            label: 'Video',
            isActive: _isVideoOff,
            onTap: _toggleVideo,
          ),
          _buildControlButton(
            icon: Icons.chat_bubble,
            label: 'Chat',
            isPrimary: true,
            hasNotification: true,
            onTap: () {
              // Open chat (Jitsi handles this internally)
            },
          ),
          _buildControlButton(
            icon: Icons.flip_camera_ios,
            label: 'Flip',
            onTap: () {
              // Flip camera (Jitsi handles this)
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    bool isPrimary = false,
    bool hasNotification = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPrimary
                      ? const Color(0xFF136DEC)
                      : (isActive
                          ? Colors.red.withOpacity(0.2)
                          : const Color(0xFF1E293B)),
                  boxShadow: isPrimary
                      ? [
                          BoxShadow(
                            color: const Color(0xFF136DEC).withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isPrimary
                      ? Colors.white
                      : (isActive ? Colors.red : Colors.white),
                ),
              ),
              if (hasNotification)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF101822), width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
              color: isPrimary ? const Color(0xFF136DEC) : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
