import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/live_ai_call_service.dart';
import '../../widgets/ai/live_ai_call_widget.dart';

/// Live AI Call Screen - Voice-based medical consultations
class LiveAICallScreen extends StatelessWidget {
  final String specialist;
  final String? patientContext;

  const LiveAICallScreen({
    super.key,
    this.specialist = 'physician',
    this.patientContext,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: LiveAICallService.instance,
      child: LiveAICallWidget(
        config: LiveAICallConfig(
          specialist: specialist,
          patientContext: patientContext,
        ),
        title: 'Voice Consultation',
        showAsBottomSheet: false,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}
