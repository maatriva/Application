import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/colors.dart';
import '../../../dashboard/presentation/widgets/dashboard_header.dart';
import '../../../dashboard/presentation/widgets/bottom_navigation.dart';
import '../../provider/ai_assistant_provider.dart';
import '../widgets/ai_avatar.dart';
import '../widgets/assistant_bubble.dart';
import '../widgets/user_bubble.dart';
import '../widgets/suggestion_chip.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/typing_indicator.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ref.read(aiAssistantProvider.notifier).addMessage(text);
    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiAssistantProvider);

    // Automatically scroll to bottom if a new message is appended or AI is typing
    ref.listen(aiAssistantProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.isTyping != next.isTyping) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DashboardHeader(),
      body: Column(
        children: [
          // Scrollable Chat area
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Beautiful AI Avatar Greeting section at the top
                  const AiAvatar(),

                  // Conversation Bubble History
                  ...aiState.messages.map((message) {
                    if (message.isUser) {
                      return UserBubble(text: message.text);
                    } else {
                      return AssistantBubble(text: message.text);
                    }
                  }),

                  // Typing indicator
                  if (aiState.isTyping) const TypingIndicator(),

                  const SizedBox(height: 12),

                  // Horizontal Suggested Questions List
                  const Text(
                    "Suggested Questions",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    children: aiState.suggestions.map((suggestion) {
                      return SuggestionChip(
                        label: suggestion,
                        onTap: () {
                          _controller.text = suggestion;
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Message input bar at bottom
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: ChatInputBar(controller: _controller, onSend: _sendMessage),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: -1,
        onTap: (index) {
          if (index == 0) {
            context.go('/?tab=0');
          } else if (index == 1) {
            context.go('/?tab=1');
          } else if (index == 2) {
            context.go('/predictive-health');
          } else if (index == 3) {
            context.go('/shop');
          }
        },
      ),
    );
  }
}
