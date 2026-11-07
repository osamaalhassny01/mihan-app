import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../services/api_service.dart';
import '../customer/customer_request_detail_view.dart';
import '../provider/provider_request_detail_view.dart';
import '../widgets/presentation_widgets.dart';

class NotificationsButton extends StatelessWidget {
  const NotificationsButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'الإشعارات',
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const NotificationsView()),
        ),
      );
}

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _markingAll = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final response = await ApiService.get('/api/notifications');
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (response.success && response.data is Map) {
        _items = ((response.data['items'] as List?) ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _error = null;
      } else {
        _error = response.message;
      }
    });
  }

  Future<void> _readAll() async {
    setState(() => _markingAll = true);
    final response = await ApiService.post('/api/notifications/read-all', {});
    if (!mounted) return;
    setState(() {
      _markingAll = false;
      if (response.success) {
        for (final item in _items) {
          item['is_read'] = 1;
        }
      }
    });
    if (!response.success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(response.message)));
    }
  }

  Future<void> _open(Map<String, dynamic> item) async {
    final response =
        await ApiService.post('/api/notifications/${item['id']}/read', {});
    if (!mounted) return;
    if (response.success) setState(() => item['is_read'] = 1);
    final link = Uri.tryParse(item['link']?.toString() ?? '')?.path ?? '';
    final match =
        RegExp(r'^/(customer|provider)/requests/(\d+)$').firstMatch(link);
    final auth = context.read<AuthController>();
    if (match != null) {
      final id = int.parse(match.group(2)!);
      Widget? page;
      if (match.group(1) == 'customer' && auth.isCustomer) {
        page = CustomerRequestDetailView(requestId: id);
      } else if (match.group(1) == 'provider' && auth.isProvider) {
        page = ProviderRequestDetailView(requestId: id);
      }
      if (page != null) {
        await Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => page!));
        return;
      }
    }
    if (!mounted) return;
    await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(item['title']?.toString() ?? 'إشعار'),
              content: SingleChildScrollView(
                  child: Text(item['message']?.toString() ?? '')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إغلاق'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((item) => item['is_read'].toString() != '1');
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات'), actions: [
        IconButton(
            tooltip: 'تحديث الإشعارات',
            onPressed: _load,
            icon: const Icon(Icons.refresh)),
        if (hasUnread)
          TextButton(
              onPressed: _markingAll ? null : _readAll,
              child: const Text('قراءة الكل')),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyStateWidget(
                  title: 'تعذر تحميل الإشعارات',
                  message: _error!,
                  onRetry: _load)
              : _items.isEmpty
                  ? EmptyStateWidget(
                      title: 'لا توجد إشعارات بعد',
                      message: 'ستجد هنا تحديثات طلباتك ورسائل النظام.',
                      onRetry: _load)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final unread = item['is_read'].toString() != '1';
                          return Card(
                            color: unread
                                ? AppTheme.primary.withValues(alpha: 0.06)
                                : Colors.white,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Icon(
                                  unread
                                      ? Icons.mark_email_unread_outlined
                                      : Icons.drafts_outlined,
                                  color: AppTheme.primary),
                              title: Text(item['title']?.toString() ?? '',
                                  style: TextStyle(
                                      fontWeight: unread
                                          ? FontWeight.bold
                                          : FontWeight.normal)),
                              subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Text(item['message']?.toString() ?? '',
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 6),
                                    Text(item['created_at']?.toString() ?? '',
                                        style: const TextStyle(fontSize: 11)),
                                  ]),
                              onTap: () => _open(item),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
