import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/customer_controller.dart';
import '../widgets/presentation_widgets.dart';
import 'customer_request_detail_view.dart';
import 'create_request_view.dart';

class CustomerRequestsView extends StatefulWidget {
  const CustomerRequestsView({super.key});

  @override
  State<CustomerRequestsView> createState() => _CustomerRequestsViewState();
}

class _CustomerRequestsViewState extends State<CustomerRequestsView> {
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerController>().loadRequests();
    });
  }

  void _onFilterChanged(String? filter) {
    setState(() => _selectedFilter = filter);
    context.read<CustomerController>().loadRequests(status: filter);
  }

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<CustomerController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلباتي'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.secondary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('طلب جديد', style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateRequestView()),
          );
        },
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('الكل', null),
                const SizedBox(width: 8),
                _buildFilterChip('بانتظار الموافقة', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('مقبول', 'accepted'),
                const SizedBox(width: 8),
                _buildFilterChip('قيد التنفيذ', 'in_progress'),
                const SizedBox(width: 8),
                _buildFilterChip('مكتمل', 'completed'),
              ],
            ),
          ),

          Expanded(
            child: customer.isLoading
                ? const Center(child: CircularProgressIndicator())
                : customer.requests.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.assignment_outlined,
                        title: 'لا توجد طلبات بعد',
                        message: 'يمكنك إنشاء طلب صيانة أو خدمة فنية بكل سهولة.',
                        onRetry: () => customer.loadRequests(status: _selectedFilter),
                      )
                    : RefreshIndicator(
                        onRefresh: () => customer.loadRequests(status: _selectedFilter),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: customer.requests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final req = customer.requests[index];
                            return InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CustomerRequestDetailView(requestId: req.id),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.build_circle_outlined,
                                                color: AppTheme.primary,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  req.requestNumber,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: AppTheme.primary,
                                                  ),
                                                ),
                                                Text(
                                                  req.serviceNameAr ?? 'خدمة فنية',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        StatusBadge(status: req.status, label: req.statusArabic),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      req.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Divider(height: 1),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        if (req.providerName != null) ...[
                                          const Icon(Icons.person_pin_circle_outlined, size: 16, color: AppTheme.secondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            req.providerName!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.secondary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                        ] else ...[
                                          const Icon(Icons.access_time_rounded, size: 15, color: AppTheme.textSecondary),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'بانتظار قبول فني',
                                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                          ),
                                          const Spacer(),
                                        ],
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              req.createdAt.split(' ')[0],
                                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                            ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _selectedFilter == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onFilterChanged(status),
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
