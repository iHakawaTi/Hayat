import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/premium_background.dart';
import '../../chat/data/chat_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Messages: {role: 'user' | 'assistant', content: 'text'}
  final List<Map<String, String>> _messages = [
    {'role': 'assistant', 'content': 'Hello! I am Hayat AI. How can I help you save a life today?'}
  ];
  
  bool _isTyping = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isTyping = true;
      _controller.clear();
    });
    
    _scrollToBottom();

    try {
      final response = await ref.read(chatServiceProvider).sendMessage(text);
      
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': response});
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': "Sorry, I'm having trouble connecting right now. Please try again."});
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Hayat AI Assistant", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const PremiumBackground(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _messages.length) {
                        // Typing indicator
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                const SizedBox(width: 8),
                                Text("Thinking...", style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                        ).animate().fadeIn();
                      }
                      
                      final msg = _messages[i];
                      final isUser = msg['role'] == 'user';
                      
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isUser ? AppTheme.primaryRed : Colors.white10,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                              bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                            ),
                          ),
                          child: Text(
                            msg['content']!, 
                            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white10,
                            hintText: "Ask me about blood donation...",
                            hintStyle: const TextStyle(color: Colors.white30),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: _isTyping ? Colors.grey : AppTheme.primaryRed,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: _isTyping ? null : _sendMessage,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
