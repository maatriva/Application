import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/chat_message.dart';

class AiAssistantState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final List<String> suggestions;

  AiAssistantState({
    required this.messages,
    required this.isTyping,
    required this.suggestions,
  });

  AiAssistantState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    List<String>? suggestions,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}

class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  AiAssistantNotifier()
    : super(
        AiAssistantState(
          messages: [
            ChatMessage(
              text:
                  "Hi Sarah! I've analyzed Leo's sleep patterns from last night. He slept for 6 hours straight, which is a great improvement.",
              isUser: false,
              timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            ),
            ChatMessage(
              text:
                  "That's wonderful news! Why was he crying around 3 AM though?",
              isUser: true,
              timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
            ),
            ChatMessage(
              text:
                  "Based on motion detection and sound analysis, your baby briefly woke due to discomfort before returning to sleep.",
              isUser: false,
              timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
            ),
          ],
          isTyping: false,
          suggestions: [
            "Why is my baby crying?",
            "Explain today's health report.",
            "Sleep analysis",
            "Feeding schedule",
            "Growth report",
            "Temperature status",
          ],
        ),
      );

  void addMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Update state with user's message and set typing indicator to true
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
    );

    // Generate responsive mock reply after a short delay
    _generateMockReply(text);
  }

  void _generateMockReply(String userQuery) {
    String reply = "";
    final query = userQuery.toLowerCase();

    if (query.contains("why is my baby crying") ||
        query.contains("cry") ||
        query.contains("crying")) {
      reply =
          "Crying is Leo's natural way of communicating. Last night around 3 AM, our sound sensors detected a high-pitched cry lasting 4 minutes. Combined with motion telemetry, it suggests mild gas or a brief sleep-position change. He settled back down smoothly without intervention.";
    } else if (query.contains("health report") ||
        query.contains("report") ||
        query.contains("health")) {
      reply =
          "Today's Health Report summary:\n• Heart Rate: 115 BPM (Highly Stable)\n• Body Temp: 36.5°C (Perfect Range)\n• Breathing Rate: 32 RPM (Normal & Steady)\n• Crying episodes: 2 short alerts, both resolved quickly. Overall, Leo's vitals are superb!";
    } else if (query.contains("sleep analysis") ||
        query.contains("sleep") ||
        query.contains("asleep")) {
      reply =
          "Sleep Analysis for Leo:\n• Total Duration: 8.2 hours\n• Sleep Efficiency: 91%\n• Deep Sleep Cycles: 3 cycles (about 2.5 hours total)\n• Waking events: 1 brief event. He is developing a robust circadian rhythm. Great job sticking to the bedtime routine!";
    } else if (query.contains("feeding") ||
        query.contains("schedule") ||
        query.contains("feed")) {
      reply =
          "Leo's recommended Feeding Schedule for today:\n• 7:00 AM: Milk (completed)\n• 10:30 AM: Milk (suggested)\n• 2:00 PM: Milk & pureed carrots\n• 5:30 PM: Milk\n• 8:30 PM: Milk (pre-sleep). Maintaining this spacing will aid his digestion and support longer night sleep.";
    } else if (query.contains("growth") ||
        query.contains("percentile") ||
        query.contains("grow")) {
      reply =
          "According to Leo's last pediatrician check-in and active logs, Leo is in the 78th percentile for weight and 82nd percentile for height. He is gaining steady muscle mass and showing excellent active reflexes.";
    } else if (query.contains("temp") ||
        query.contains("temperature") ||
        query.contains("room")) {
      reply =
          "Leo's current vitals and environment check out beautifully:\n• Body Temperature: 36.5°C (ideal and stable)\n• Nursery Temperature: 22.4°C (perfect sweet spot for babies is between 20°C and 22.2°C). Keep the room well-ventilated.";
    } else {
      reply =
          "That's a great question, Sarah! I am continuously monitoring Leo's biometric sensors, breathing rhythms, and sleep cycles. Let me know if you would like me to compile a specific trend chart or check his live feed.";
    }

    Timer(const Duration(seconds: 2), () {
      final aiMessage = ChatMessage(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isTyping: false,
      );
    });
  }
}

final aiAssistantProvider =
    StateNotifierProvider<AiAssistantNotifier, AiAssistantState>((ref) {
      return AiAssistantNotifier();
    });
