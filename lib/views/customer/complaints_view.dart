import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../widgets/presentation_widgets.dart';

class ComplaintsView extends StatefulWidget {
  const ComplaintsView({super.key});

  @override
  State<ComplaintsView> createState() => _ComplaintsViewState();
}

class _ComplaintsViewState extends State<ComplaintsView> {
  List<dynamic> _complaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    final res = await ApiService.get('/api/complaints');
    if (res.success && res.data is List) {
      setState(() {
        _complaints = res.data as List;
      });
    }
    setState(() => _isLoading = false);
  }

  void _showNewComplaintDialog() {
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              top: 24,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'تقديم شكوى أو طلب دعم فني',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'اكتب مشكلتك بدقة وسيقوم فريق الدعم الفني بمتابعتها وموافاتك بالرد فوراً.',
                    style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'موضوع الشكوى / المشكلة *',
                    hint: 'مثال: مشكلة في تنفيذ الطلب، تأخر الفني...',
                    controller: subjectCtrl,
                    prefixIcon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    label: 'تفاصيل الشكوى بالكامل *',
                    hint: 'اشرح تفاصيل المشكلة بكل وضوح...',
                    controller: descCtrl,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),

                  CustomButton(
                    text: 'إرسال الشكوى للإدارة',
                    icon: Icons.send_rounded,
                    isLoading: isSubmitting,
                    onPressed: () async {
                      final sub = subjectCtrl.text.trim();
                      final desc = descCtrl.text.trim();
                      if (sub.length < 3 || desc.length < 5) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى ملء موضوع الشكوى ووصفها بالتفصيل')),
                        );
                        return;
                      }

                      setModalState(() => isSubmitting = true);
                      final res = await ApiService.post('/api/complaints', {
                        'subject': sub,
                        'description': desc,
                      });
                      setModalState(() => isSubmitting = false);

                      if (res.success) {
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تسجيل شكواك بنجاح وسيقوم فريق الدعم بمتابعتها.'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                        _loadComplaints();
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res.message), backgroundColor: AppTheme.error),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showComplaintDetails(dynamic comp) async {
    final compId = comp['id'];
    final replyCtrl = TextEditingController();
    bool isSending = false;

    // Fetch full messages
    final res = await ApiService.get('/api/complaints/$compId');
    final messages = (res.success && res.data != null && res.data['messages'] is List)
        ? (res.data['messages'] as List)
        : [];

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: EdgeInsets.only(
              top: 20,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        comp['subject'] ?? 'شكوى',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Text(
                  'رقم الشكوى: ${comp['complaint_number'] ?? "-"} • التاريخ: ${comp['created_at'] ?? ""}',
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                ),
                const Divider(height: 16),

                // Main description
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    comp['description'] ?? '',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
                  ),
                ),
                const SizedBox(height: 12),

                // Messages list
                const Text(
                  'الردود والمتابعة:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: messages.isEmpty
                      ? const Center(
                          child: Text(
                            'بانتظار رد ومتابعة فريق الدعم الفني...',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        )
                      : ListView.separated(
                          itemCount: messages.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final msg = messages[idx];
                            final isSupport = msg['sender_role'] == 'admin' || msg['sender_role'] == 'employee';
                            return Align(
                              alignment: isSupport ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSupport ? AppTheme.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSupport ? AppTheme.primary.withValues(alpha: 0.3) : Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isSupport ? 'فريق الدعم الفني' : 'أنت',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSupport ? AppTheme.primary : AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      msg['message'] ?? '',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: replyCtrl,
                        decoration: InputDecoration(
                          hintText: 'اكتب ردك هنا...',
                          hintStyle: const TextStyle(fontSize: 12),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: isSending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, size: 20),
                      onPressed: isSending
                          ? null
                          : () async {
                              final text = replyCtrl.text.trim();
                              if (text.isEmpty) return;

                              setModalState(() => isSending = true);
                              final replyRes = await ApiService.post('/api/complaints/$compId/reply', {
                                'message': text,
                              });
                              setModalState(() => isSending = false);

                              if (replyRes.success) {
                                replyCtrl.clear();
                                final reload = await ApiService.get('/api/complaints/$compId');
                                if (reload.success && reload.data != null && reload.data['messages'] is List) {
                                  setModalState(() {
                                    messages.clear();
                                    messages.addAll(reload.data['messages'] as List);
                                  });
                                }
                              }
                            },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدعم الفني والشكاوى'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        onPressed: _showNewComplaintDialog,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('تقديم شكوى جديدة'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadComplaints,
              child: _complaints.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.support_agent_rounded, size: 56, color: AppTheme.primary),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد شكاوى مسجلة لديك',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'فريق الدعم الفني في خدمتك دائماً لمتابعة أي مشكلة تواجهك.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _complaints.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final comp = _complaints[i];
                        final status = comp['status'] ?? 'open';
                        String statusLabel = 'مفتوحة';
                        Color statusColor = Colors.orange;

                        if (status == 'resolved') {
                          statusLabel = 'تم الحل';
                          statusColor = Colors.green;
                        } else if (status == 'in_review') {
                          statusLabel = 'قيد المتابعة';
                          statusColor = Colors.blue;
                        } else if (status == 'closed') {
                          statusLabel = 'مغلقة';
                          statusColor = Colors.grey;
                        }

                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showComplaintDetails(comp),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        comp['subject'] ?? 'شكوى',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  comp['description'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                                ),
                                const Divider(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'رقم الشكوى: ${comp['complaint_number'] ?? "-"}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                    const Row(
                                      children: [
                                        Text('عرض المحادثة', style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                        Icon(Icons.chevron_left, size: 16, color: AppTheme.primary),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
