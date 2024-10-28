import 'dart:async';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:ollama/ollama.dart';
import 'package:otzaria/models/links.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as anthropic;
import 'package:langchain/langchain.dart' as langchain;
import 'package:langchain_google/langchain_google.dart';

class ChatbotInterfaceLogic {
  late Ollama _ollama;
  late ChatGoogleGenerativeAI gemini;
  late anthropic.AnthropicClient _client;
  TextBookTab tab;
  final List<Message> _messages;

  ChatbotInterfaceLogic(
    this.tab,
    this._messages,
  ) {
    OpenAI.apiKey = Settings.getValue('key-openai-api-key') ?? '';
    _client = anthropic.AnthropicClient(
        apiKey: Settings.getValue('key-anthropic-api-key') ?? '');
    _ollama = Ollama();
    gemini = ChatGoogleGenerativeAI(
        apiKey: Settings.getValue('key-gemini-api-key') ?? '');
  }

  Stream<String> getChatbotResponse(String text) async* {
    final startIndex = tab.positionsListener.itemPositions.value.first.index;
    final endIndex = tab.positionsListener.itemPositions.value.last.index;
    final title = await refFromIndex(startIndex, tab.tableOfContents);
    final source = title +
        '\n' +
        (stripHtmlIfNeeded(removeVolwels(await tab.text))
            .split('\n')
            .sublist(startIndex, endIndex + 1)
            .join('\n'));
    final thisLinks = getLinksforIndexs(
        links: tab.links,
        commentatorsToShow: tab.commentatorsToShow.value,
        indexes: [for (var i = startIndex; i <= endIndex; i++) i]);

    final commentries = (await thisLinks)
        .map((link) async => link.heRef + '\n' + await link.content)
        .toList();
    final resolvedCommentries = (await _resolveLinks(commentries)).join('\n');
    final content = getContextContent(source, resolvedCommentries);
    Stream<String> respondStream = Stream.empty();
    switch (Settings.getValue('key-ai-engine')) {
      case 'ollama':
        respondStream = ollamaResponse(content);
        break;
      case 'openai':
        respondStream = openaiResponse(content);
        break;
      case 'anthropic':
        respondStream = claudeResponse(content);
        break;
      case 'gemini':
        respondStream = geminiResponse(content, text);
      default:
        break;
    }

    await for (final response in respondStream) {
      yield response;
    }
  }

  String getContextContent(String source, String commentary) {
    return '''ענה על השאלות הבאות בעברית בלבד, על פי הטקסט שיוצג לפניך מארון הספרים היהודי. כמו כן יובאו לך פרשנויות קלאסיות, במידה וקיימות, והיצמד אליהן בביאור הטקסט ובעניית השאלות. שים לב כי יתכן וחלק מהחומר לא יהיה רלונטי לתשובה. סרב לענות על שאלות שאינן נוגעות לטקסט האמור במישרין. להלן הטקסט:
                         ${source}
                         להלן הפרשנים:
                         ${commentary}
                         ''';
  }

  Stream<String> ollamaResponse(String content) async* {
    List<ChatMessage> messages = _messages
        .map((m) => ChatMessage(
            role: m.isUser ? 'user' : 'assistant',
            content: m.isUser ? '[INST]${m.text}[/INST]' : m.text))
        .toList();
    messages[0] = ChatMessage(
        role: 'user',
        content:
            '[INST]${content}\n להלן השאלות: \n ${messages[0].content.replaceAll(
                  '[INST]',
                  '',
                )}');
    //remove the last message
    messages = messages.sublist(0, messages.length - 1);
    print(messages);

    final stream = _ollama.chat(messages, model: 'dictaLM');
    String fullResponse = '';
    await for (final response in stream) {
      fullResponse += response.text;
      yield fullResponse;
    }
  }

  Stream<String> openaiResponse(String content) async* {
    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(content),
      ],
      role: OpenAIChatMessageRole.system,
    );

    // the user message that will be sent to the request.
    final messages = _messages
        .map((m) => OpenAIChatCompletionChoiceMessageModel(
              content: [
                OpenAIChatCompletionChoiceMessageContentItemModel.text(
                  m.text,
                ),
                //! image url contents are allowed only for models with image support such gpt-4.
              ],
              role: m.isUser
                  ? OpenAIChatMessageRole.user
                  : OpenAIChatMessageRole.assistant,
            ))
        .toList();

// all messages to be sent.
    messages.insert(0, systemMessage);

// the actual request.
    final chatCompletion = OpenAI.instance.chat.createStream(
      model: "gpt-4o",
      seed: 6,
      messages: messages,
      temperature: 0.2,
      maxTokens: 1500,
    );
    String fullResponse = '';

    await for (final response in chatCompletion) {
      fullResponse += response.choices.first.delta.content?.first?.text ?? '';
      yield fullResponse;
    }
  }

  Stream<String> claudeResponse(String content) async* {
    final massege = await _client.createMessage(
      request: anthropic.CreateMessageRequest(
          model: anthropic.Model.model(anthropic.Models.claude35Sonnet20240620),
          maxTokens: 2048,
          messages: _messages
              .map((m) => anthropic.Message(
                    role: m.isUser
                        ? anthropic.MessageRole.user
                        : anthropic.MessageRole.assistant,
                    content: anthropic.MessageContent.text(m.text),
                  ))
              .toList(),
          system: content),
    );
    yield massege.content.text;
  }

  Future<List<String>> _resolveLinks(List<Future<String>> links) async {
    List<String> resolvedLinks = [];
    for (var link in links) {
      resolvedLinks.add((await link));
    }
    return resolvedLinks;
  }

  Stream<String> geminiResponse(String content, String text) async* {
    final messages = _messages
        .map((m) => m.isUser
            ? langchain.ChatMessage.humanText(m.text)
            : langchain.ChatMessage.ai(m.text))
        .toList();
    messages.insert(0, langchain.ChatMessage.system(content));

    final prompt = langchain.PromptValue.chat(messages);
    final results = gemini.stream(prompt);

    String fullResponse = '';

    await for (final response in results) {
      fullResponse += response.output.content;
      yield fullResponse;
    }
  }
}

class Message {
  String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
