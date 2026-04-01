import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'mentor_live_session_web.dart';
import 'mentor_live_session_mobile.dart';

/// Mentor Live Session - Base Responsive Wrapper
class MentorLiveSession extends StatelessWidget {
  const MentorLiveSession({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const MentorLiveSessionWeb();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return const MentorLiveSessionWeb();
        }
        return const MentorLiveSessionMobile();
      },
    );
  }
}
