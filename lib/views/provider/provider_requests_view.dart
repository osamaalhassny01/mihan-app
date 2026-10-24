import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/provider_controller.dart';
import '../widgets/presentation_widgets.dart';
import 'provider_request_detail_view.dart';

class ProviderRequestsView extends StatefulWidget {
  const ProviderRequestsView({super.key});

  @override
  State<ProviderRequestsView> createState() => _ProviderRequestsViewState();
}

class _ProviderRequestsViewState extends State<ProviderRequestsView> {
  String _filter = 'all'; // all, pending, active, completed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderController>().loadRequests();
    });
  }

  void _showCompleteDialog(BuildContext context, int requestId, ProviderController ctrl) {
    final priceController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إكمال الخدمة وإصدار الفاتورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('يرجى تأكيد السعر النهائي المتفق عليه للخدمة لإصدار الفاتورة للعميل:'),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ الإجمالي (ريال)',
                hintText: 'مثال: 5000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceController.text.trim()) ?? 0.0;
              if (price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')),
                );
                return;
              }
              Navigator.of(ctx).pop();
              await ctrl.completeRequest(requestId, price);
            },
            child: const Text('إكمال وإصدار الفاتورة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderController>();

    final filteredRequests = provider.requests.where((r) {
      if (_filter == 'pending') return r.isPending;
      if (_filter == 'active') return r.isAccepted || r.isInProgress;
      if (_filter == 'completed') return r.isCompleted;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات الخدمة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadRequests(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('الكل', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('بانتظار الموافقة', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('قيد التنفيذ', 'active'),
                const SizedBox(width: 8),
                _buildFilterChip('مكتملة', 'completed'),
              ],
            ),
          ),

          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredRequests.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.assignment_outlined,
                        title: 'لا توجد طلبات في هذا القسم',
                        message: 'ستظهر هنا طلبات العملاء المطابقة لمهنتك ومناطق تغطيتك.',
                        onRetry: () => provider.loadRequests(),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.loadRequests(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredRequests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final req = filteredRequests[index];
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProviderRequestDetailView(requestId: req.id),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          req.requestNumber,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary),
                                        ),
                                        StatusBadge(status: req.status, label: req.statusArabic),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      req.serviceNameAr ?? 'خدمة فنية',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      req.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline, size: 16, color: AppTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          req.customerName ?? 'عميل المنصة',
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                        ),
                                        const Spacer(),
                                        if (req.budget != null)
                                          Text(
                                            '${req.budget} ريال',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary),
                                          ),
                                      ],
                                    ),
                                    const Divider(height: 20),

                                    // Action Buttons based on status
                                    if (req.isPending) ...[
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                                              onPressed: () => provider.acceptRequest(req.id),
                                              child: const Text('قبول الطلب'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
                                              onPressed: () => provider.rejectRequest(req.id),
                                              child: const Text('رفض'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else if (req.isAccepted) ...[
                                      CustomButton(
                                        text: 'بدء التنفيذ والتوجه للموقع',
                                        icon: Icons.play_arrow,
                                        onPressed: () => provider.startRequest(req.id),
                                      ),
                                    ] else if (req.isInProgress) ...[
                                      CustomButton(
                                        text: 'إكمال العمل وإصدار الفاتورة',
                                        icon: Icons.check_circle_outline,
                                        backgroundColor: AppTheme.success,
                                        onPressed: () => _showCompleteDialog(context, req.id, provider),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppTheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.border),
      ),
    );
  }
}
