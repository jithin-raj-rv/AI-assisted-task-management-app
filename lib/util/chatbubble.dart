import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';
import 'package:to_do_list/util/smalltextgradient.dart';

/// Helper function to copy text to clipboard with feedback
Future<void> _copyToClipboard(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  
  // Show a simple toast-like feedback
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Text copied to clipboard'),
      duration: const Duration(milliseconds: 1500),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/**
 * A chat bubble container that provides chat-like styling for tiles.
 * Can be used for user messages (right-aligned) or AI/other messages (left-aligned).
 */
class ChatBubbleTile extends ConsumerWidget {
  final Widget child;
  final bool isUser;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool useGradient;

  const ChatBubbleTile({
    super.key,
    required this.child,
    this.isUser = true,
    this.padding,
    this.margin,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: margin ?? const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: padding ?? const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: useGradient
              ? LinearGradient(
                  colors: isUser
                      ? [appTheme.primary, appTheme.secondary]
                      : [appTheme.secondary.withOpacity(0.5), appTheme.primary.withOpacity(0.3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: useGradient
              ? null
              : (isUser
                  ? appTheme.primary
                  : appTheme.secondary.withOpacity(0.5)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: child,
      ),
    );
  }
}

/**
 * A simple chat message bubble widget with text
 */
class ChatMessageBubble extends ConsumerWidget {
  final String text;
  final bool isUser;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? margin;
  final bool useGradient;
  final bool enableCopy; // New parameter to enable/disable copying

  const ChatMessageBubble({
    super.key,
    required this.text,
    this.isUser = true,
    this.textStyle,
    this.margin,
    this.useGradient = false,
    this.enableCopy = true, // Default to enabled
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);
    
    return ChatBubbleTile(
      isUser: isUser,
      margin: margin,
      useGradient: useGradient,
      child: GestureDetector(
        onLongPress: enableCopy 
          ? () => _copyToClipboard(context, text)
          : null,
        child: SelectableText(
          text,
          style: textStyle ?? TextStyle(
            color: appTheme.foreground.withOpacity(0.65),
            fontSize: 16,
          ),
          cursorColor: appTheme.primary,
          selectionColor: appTheme.primary.withOpacity(0.3),
          toolbarOptions: const ToolbarOptions(
            copy: true,
            selectAll: true,
          ),
        ),
      ),
    );
  }
}

/**
 * A gradient chat bubble with Smalltextgradient for the text
 */
class GradientChatBubble extends ConsumerWidget {
  final String text;
  final bool isUser;
  final double fontSize;
  final TextOverflow overflow;
  final EdgeInsetsGeometry? margin;
  final bool enableCopy; // New parameter to enable/disable copying

  const GradientChatBubble({
    super.key,
    required this.text,
    this.isUser = true,
    this.fontSize = 16,
    this.overflow = TextOverflow.clip,
    this.margin,
    this.enableCopy = true, // Default to enabled
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);
    
    return ChatBubbleTile(
      isUser: isUser,
      margin: margin,
      useGradient: true,
      child: GestureDetector(
        onLongPress: enableCopy 
          ? () => _copyToClipboard(context, text)
          : null,
        child: SelectableText(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.normal,
            foreground: Paint()
              ..shader = LinearGradient(
                colors: isUser
                    ? [appTheme.primary, appTheme.secondary]
                    : [appTheme.secondary, appTheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(
                const Rect.fromLTWH(0, 0, 200, 100),
              ),
          ),
          cursorColor: appTheme.primary,
          selectionColor: appTheme.primary.withOpacity(0.3),
          toolbarOptions: const ToolbarOptions(
            copy: true,
            selectAll: true,
          ),
        ),
      ),
    );
  }
}

/**
 * A chat input field styled to match the chat bubbles
 */
class ChatInputField extends ConsumerWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onSubmit;
  final VoidCallback? onSend;
  final bool autofocus;
  final int maxLines;
  final double minHeight;
  final double maxHeight;

  const ChatInputField({
    super.key,
    required this.controller,
    this.hintText = 'Type a message...',
    this.onSubmit,
    this.onSend,
    this.autofocus = false,
    this.maxLines = 6,
    this.minHeight = 48,
    this.maxHeight = 160,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            appTheme.background.withOpacity(0.8),
            appTheme.primary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: appTheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [appTheme.primary, appTheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: TextField(
                  controller: controller,
                  autofocus: autofocus,
                  maxLines: maxLines,
                  minLines: 1,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => onSubmit?.call(),
                  // Auto-resize based on content
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [appTheme.primary, appTheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }
}

/**
 * A loading indicator styled for chat
 */
class ChatLoadingIndicator extends ConsumerWidget {
  final Color? color;

  const ChatLoadingIndicator({super.key, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? appTheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
