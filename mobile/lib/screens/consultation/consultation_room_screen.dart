import 'package:flutter/material.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import '../../config/theme.dart';

class ConsultationRoomScreen extends StatefulWidget {
  final String roomId;
  final String doctorName;
  
  const ConsultationRoomScreen({
    super.key,
    required this.roomId,
    required this.doctorName,
  });

  @override
  State<ConsultationRoomScreen> createState() => _ConsultationRoomScreenState();
}

class _ConsultationRoomScreenState extends State<ConsultationRoomScreen> {
  final _jitsiMeet = JitsiMeet();
  bool _isJoining = true;
  String _status = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _joinMeeting();
  }

  Future<void> _joinMeeting() async {
    try {
      var options = JitsiMeetConferenceOptions(
        serverURL: "https://meet.jit.si",
        room: "swasthya-${widget.roomId}",
        configOverrides: {
          "startWithAudioMuted": false,
          "startWithVideoMuted": false,
          "subject": "Consultation with ${widget.doctorName}",
        },
        featureFlags: {
          "unsaferoomwarning.enabled": false,
          "ios.screensharing.enabled": true,
          "chat.enabled": true,
          "invite.enabled": false,
          "meeting-password.enabled": false,
          "pip.enabled": true,
          "lobby-mode.enabled": false,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: "Patient",
          email: "",
        ),
      );

      var listener = JitsiMeetEventListener(
        conferenceJoined: (url) {
          setState(() {
            _isJoining = false;
            _status = 'Connected';
          });
        },
        conferenceTerminated: (url, error) {
          Navigator.of(context).pop();
        },
        participantJoined: (email, name, role, participantId) {
          setState(() => _status = '${widget.doctorName} joined');
        },
        participantLeft: (participantId) {
          setState(() => _status = 'Waiting for doctor...');
        },
      );

      await _jitsiMeet.join(options, listener);
    } catch (e) {
      setState(() {
        _isJoining = false;
        _status = 'Connection failed: $e';
      });
    }
  }

  Future<void> _hangUp() async {
    await _jitsiMeet.hangUp();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isJoining) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 24),
              Text(_status, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                'Joining call with ${widget.doctorName}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
    }

    // Jitsi handles its own UI, this is a fallback
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Call with ${widget.doctorName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: _hangUp,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text(_status, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text('End-to-End Encrypted', style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _hangUp,
              icon: const Icon(Icons.call_end),
              label: const Text('End Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
