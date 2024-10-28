import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/screens/reading/text/generative_ui/generative_ui_logic.dart';
import 'package:otzaria/screens/settings_screen.dart';

class ChatbotInterface extends StatefulWidget {
  final TextBookTab tab;
  const ChatbotInterface({Key? key, required this.tab}) : super(key: key);

  @override
  _ChatbotInterfaceState createState() => _ChatbotInterfaceState();
}

class _ChatbotInterfaceState extends State<ChatbotInterface>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _streamSubscription;
  late ChatbotInterfaceLogic logic;

  @override
  void initState() {
    super.initState();
    logic = ChatbotInterfaceLogic(widget.tab, _messages);
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        Message(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
    });

    final responseStream = logic.getChatbotResponse(text);
    final botMessage = Message(
      text: '...',
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(botMessage);
    });

    _streamSubscription?.cancel();
    _streamSubscription = responseStream.listen(
      (response) {
        setState(() {
          botMessage.text = response;
          _scrollToBottom();
        });
      },
      onError: (error) {
        setState(() {
          botMessage.text = "שגיאה: $error";
          _scrollToBottom();
        });
      },
    );

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _messages.isEmpty ? null : _clearChat,
            tooltip: 'איפוס',
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'הקלד כאן את שאלתך...',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            tooltip: 'שלח',
            onPressed: () => _sendMessage(_controller.text),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  void _clearChat() {
    _streamSubscription?.cancel();
    setState(() {
      _messages.clear();
    });
  }
}

class _MessageBubble extends StatefulWidget {
  final Message message;

  const _MessageBubble({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          widget.message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: widget.message.isUser
              ? Theme.of(context).primaryColor
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message.text,
              style: TextStyle(
                color: widget.message.isUser ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.message.isUser
                  ? 'אתה: ${widget.message.timestamp.hour}:${widget.message.timestamp.minute.toString().padLeft(2, '0')}'
                  : '${aiEngines[Settings.getValue('key-ai-engine')]}: ${widget.message.timestamp.hour}:${widget.message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: widget.message.isUser ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
