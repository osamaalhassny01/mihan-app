import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/mahir_controller.dart';
import '../../models/mahir_models.dart';

class MahirChatView extends StatefulWidget {
  final MahirProfessionModel? profession;

  const MahirChatView({super.key, this.profession});

  @override
  State<MahirChatView> createState() => _MahirChatViewState();
}

class _MahirChatViewState extends State<MahirChatView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickPrompts = const [
    'ما هي الأدوات المطلوبة للبدء؟ 🧰',
    'اشرح لي الخطوات من الصفر خطوة بخطوة 📋',
    'ما هي أهم إرشادات السلامة والوقاية؟ ⚠️',
    'ما هي أكثر الأخطاء الشائعة وكيف أتجنبها؟ 💡',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _sendCurrentMessage(MahirController controller) {
    final text = _textController.text.trim();
    if (text.isEmpty || controller.isSending) return;

    _textController.clear();
    controller.sendMessage(text).then((_) => _scrollToBottom());
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final mahir = context.watch<MahirController>();
    final profession = widget.profession ?? mahir.currentProfession;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.secondaryLight, width: 1.5),
              ),
              child: Center(
                child: Text(
                  profession?.icon ?? '🛠️',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'ماهر AI',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'المعلم الذكي',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    profession != null ? 'مهنة: ${profession.name}' : 'مدرّب المهن الشامل',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'إعادة بدء الجلسة',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              if (profession != null) {
                mahir.startChatForProfession(profession).then((_) => _scrollToBottom());
              } else {
                mahir.startGeneralChat().then((_) => _scrollToBottom());
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط تنبيه نطاق المهنة
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    profession != null
                        ? 'ماهر مخصص لتعليمك خطوة بخطوة في: ${profession.name}'
                        : 'ماهر يجيبك فقط على ما يخص المهن العملية والحرف اليدوية.',
                    style: const TextStyle(fontSize: 11.5, color: AppTheme.primaryDark, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // قائمة الرسائل
          Expanded(
            child: mahir.isChatLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primary),
                        SizedBox(height: 14),
                        Text('جاري تحضير الجلسة التعليمية مع ماهر...', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    itemCount: mahir.messages.length + (mahir.isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == mahir.messages.length) {
                        return _buildTypingIndicator();
                      }
                      final msg = mahir.messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),

          // الأسئلة السريعة المقترحة
          if (!mahir.isSending && mahir.messages.length <= 3)
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return ActionChip(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.border),
                    label: Text(
                      _quickPrompts[i],
                      style: const TextStyle(fontSize: 11, color: AppTheme.primaryDark),
                    ),
                    onPressed: () {
                      _textController.text = _quickPrompts[i];
                      _sendCurrentMessage(mahir);
                    },
                  );
                },
              ),
            ),

          // حقل الإدخال
          _buildInputBar(mahir),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MahirMessageModel msg) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppTheme.primaryDark,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('👨‍🏫', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isUser ? null : Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        'ماهر AI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  SelectableText(
                    msg.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isUser ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.person, size: 20, color: AppTheme.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppTheme.primaryDark,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('👨‍🏫', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                ),
                SizedBox(width: 10),
                Text(
                  'ماهر يُجهّز الخطوات والشرح لك...',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(MahirController mahir) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TextField(
                  controller: _textController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendCurrentMessage(mahir),
                  decoration: const InputDecoration(
                    hintText: 'اسأل ماهر عن أي خطوة، أداة، أو طريقة عمل...',
                    hintStyle: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: mahir.isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: mahir.isSending ? null : () => _sendCurrentMessage(mahir),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
