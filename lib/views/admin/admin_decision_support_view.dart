import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/admin_decision_models.dart';

class AdminDecisionSupportView extends StatefulWidget {
  const AdminDecisionSupportView({super.key});

  @override
  State<AdminDecisionSupportView> createState() => _AdminDecisionSupportViewState();
}

class _AdminDecisionSupportViewState extends State<AdminDecisionSupportView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  AdminDecisionSupportData? _data;

  // Ask AI state
  final TextEditingController _questionController = TextEditingController();
  bool _isAskingAi = false;
  String? _aiAnswer;
  String? _aiProvider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadDecisionData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _loadDecisionData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.get('/api/admin/decision-support');

    if (!mounted) return;

    if (res.success && res.data != null) {
      setState(() {
        _isLoading = false;
        try {
          _data = AdminDecisionSupportData.fromJson(res.data as Map<String, dynamic>);
        } catch (e) {
          _errorMessage = 'خطأ في معالجة بيانات دعم القرار: $e';
        }
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = res.message.isNotEmpty ? res.message : 'تعذر تحميل بيانات دعم اتخاذ القرار';
      });
    }
  }

  Future<void> _askAiAdvisor([String? predefinedQuestion]) async {
    final query = predefinedQuestion ?? _questionController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isAskingAi = true;
      _aiAnswer = null;
    });

    final res = await ApiService.post('/api/admin/decision-support/ask', {
      'question': query,
    });

    if (!mounted) return;

    setState(() {
      _isAskingAi = false;
      if (res.success && res.data != null) {
        final d = res.data as Map<String, dynamic>;
        _aiAnswer = d['answer'] ?? '';
        _aiProvider = d['provider'] ?? 'local';
      } else {
        _aiAnswer = 'تعذر الحصول على رد الذكاء الاصطناعي: ${res.message}';
      }
    });
  }

  void _openAskAiSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.psychology_rounded, color: AppTheme.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مستشار القرار الإداري الذكي',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'اسأل أي استفسار حول بيانات المنصة والقرارات المقترحة',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'نماذج استفسارات إدارية شائعة:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildPresetChip('ما هي أكثر المناطق التي تعاني من عجز في مقدمي الخدمات؟', setSheetState),
                            _buildPresetChip('حلل أداء المهنيين وحدد من يحتاج إلى متابعة أو إنذار.', setSheetState),
                            _buildPresetChip('ما هي الخدمات الأكثر طلباً والتي تحتاج إلى استقطاب إضافي؟', setSheetState),
                            _buildPresetChip('قدم تقريراً شاملاً عن بؤر الشكاوى وطرق معالجتها.', setSheetState),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Input Box
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: TextField(
                            controller: _questionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'اكتب سؤالك الإداري هنا بحرية...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _isAskingAi
                                ? null
                                : () async {
                                    setSheetState(() => _isAskingAi = true);
                                    await _askAiAdvisor();
                                    setSheetState(() => _isAskingAi = false);
                                  },
                            icon: _isAskingAi
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.auto_awesome_rounded),
                            label: Text(_isAskingAi ? 'جارٍ التحليل بالذكاء الاصطناعي...' : 'تحليل واستشارة الذكاء الاصطناعي'),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // AI Output Card
                        if (_aiAnswer != null) ...[
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.teal.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.lightbulb_rounded, color: AppTheme.primary, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'إجابة مستشار القرار الذكي',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _aiProvider ?? 'local',
                                        style: TextStyle(fontSize: 10, color: Colors.teal.shade900, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                SelectableText(
                                  _aiAnswer!,
                                  style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF1E293B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPresetChip(String text, void Function(void Function()) setSheetState) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 11)),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: () {
        _questionController.text = text;
        setSheetState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('دعم اتخاذ القرار بالذكاء الاصطناعي'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'تحديث التحليلات',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDecisionData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('اسأل المستشار الذكي'),
        onPressed: _openAskAiSheet,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 16),
            Text(
              'جارٍ تجميع بيانات المنصة وتحليل المؤشرات بالذكاء الاصطناعي...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 54),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _loadDecisionData,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _data;
    if (data == null) {
      return const Center(child: Text('لا توجد بيانات متاحة حالياً'));
    }

    final kpis = data.kpis;

    return RefreshIndicator(
      onRefresh: _loadDecisionData,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Hero Card
                  _buildExecutiveHeroCard(),
                  const SizedBox(height: 16),

                  // Quick KPIs Row
                  _buildKpisRow(kpis),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.lightbulb_rounded, size: 20), text: 'التوصيات الذكية'),
                  Tab(icon: Icon(Icons.map_rounded, size: 20), text: 'عجز المناطق (المثال 1)'),
                  Tab(icon: Icon(Icons.assessment_rounded, size: 20), text: 'أداء المهنيين (المثال 2)'),
                  Tab(icon: Icon(Icons.trending_up_rounded, size: 20), text: 'الطلب على الخدمات (المثال 3)'),
                  Tab(icon: Icon(Icons.radar_rounded, size: 20), text: 'رادار الشكاوى (المثال 4)'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRecommendationsTab(data.aiRecommendations),
            _buildSupplyDemandTab(data.supplyDemandDeficit),
            _buildProviderPerformanceTab(data.providerPerformance),
            _buildServiceDemandTab(data.serviceDemand),
            _buildComplaintsTab(data.complaintsHotspots),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF042F2E), Color(0xFF0F766E)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نظام دعم اتخاذ القرار الإداري',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    Text(
                      'استخلاص ذكي للمؤشرات والتوصيات لصانع القرار',
                      style: TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'يقوم النظام آلياً بتحليل حركة الطلبات، فجوات التغطية الجغرافية، كفاءة المهنيين، ونقاط الشكاوى لتقديم توجيهات تشغيلية واستراتيجية فورية للمدير.',
            style: TextStyle(color: Colors.white, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _openAskAiSheet,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Color(0xFF0F766E), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'بدء استشارة تفاعلية مع الذكاء الاصطناعي',
                    style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpisRow(AdminKpis kpis) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'إجمالي الطلبات',
            value: '${kpis.totalRequests}',
            sub: 'إنجاز: ${kpis.completionRate}%',
            color: Colors.blue.shade700,
            icon: Icons.assignment_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'مقدمو الخدمة',
            value: '${kpis.totalProviders}',
            sub: 'موثق: ${kpis.verifiedProviders}',
            color: Colors.teal.shade700,
            icon: Icons.engineering_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'متوسط التقييم',
            value: '${kpis.averageRating}',
            sub: 'من 5.0',
            color: Colors.amber.shade800,
            icon: Icons.star_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'الشكاوى المفتوحة',
            value: '${kpis.openComplaints}',
            sub: 'حل: ${kpis.complaintResolutionRate}%',
            color: kpis.openComplaints > 0 ? Colors.red.shade700 : Colors.green.shade700,
            icon: Icons.report_problem_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String sub,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            sub,
            style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  // 1. AI Recommendations Tab
  Widget _buildRecommendationsTab(List<AiRecommendationItem> recommendations) {
    if (recommendations.isEmpty) {
      return const Center(child: Text('لا توجد توصيات حالية'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final rec = recommendations[index];
        final isUrgent = rec.severity == 'urgent';
        final isWarning = rec.severity == 'warning';

        final cardColor = isUrgent
            ? Colors.red.shade50
            : (isWarning ? Colors.amber.shade50 : Colors.teal.shade50);
        final borderColor = isUrgent
            ? Colors.red.shade300
            : (isWarning ? Colors.amber.shade300 : Colors.teal.shade200);
        final tagBg = isUrgent ? Colors.red : (isWarning ? Colors.amber.shade800 : Colors.teal);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: tagBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isUrgent ? 'عاجل وحرج' : (isWarning ? 'تنبيه تشغيلي' : 'فرصة تحسين'),
                      style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.textSecondary, size: 18),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                rec.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                rec.explanation,
                style: const TextStyle(fontSize: 12.5, height: 1.5, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded, color: tagBg, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rec.recommendation,
                        style: TextStyle(color: tagBg, fontWeight: FontWeight.bold, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 2. Supply vs Demand Deficit Tab (Example 1)
  Widget _buildSupplyDemandTab(List<SupplyDemandDeficitItem> items) {
    if (items.isEmpty) {
      return const Center(child: Text('لا توجد بيانات مناطق متوفرة'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isCritical = item.status == 'critical';
        final isHigh = item.status == 'high_deficit';

        final badgeColor = isCritical ? AppTheme.error : (isHigh ? AppTheme.warning : AppTheme.success);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCritical ? Colors.red.shade200 : AppTheme.border,
              width: isCritical ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nameAr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        if (item.city.isNotEmpty)
                          Text(item.city, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.statusLabel,
                      style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatBadge('الطلبات', '${item.requestsCount}', Icons.assignment_outlined),
                  const SizedBox(width: 8),
                  _buildStatBadge('المتاحين', '${item.availableProviders}', Icons.person_pin_circle_outlined),
                  const SizedBox(width: 8),
                  _buildStatBadge('الموثقين', '${item.verifiedProviders}', Icons.verified_outlined),
                  const SizedBox(width: 8),
                  _buildStatBadge('النسبة', '${item.demandToSupplyRatio}:1', Icons.balance_rounded),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.recommendation,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(label, style: const TextStyle(fontSize: 9.5, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  // 3. Provider Performance Matrix Tab (Example 2)
  Widget _buildProviderPerformanceTab(ProviderPerformanceMatrix matrix) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: Top Performers
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.military_tech_rounded, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'المتميزون وأصحاب الأداء المرتفع',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              Text(
                '${matrix.topPerformers.length} مهني',
                style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (matrix.topPerformers.isEmpty)
            const Text('لا يوجد مهنيون مصنفون كمتميزين حالياً', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))
          else
            ...matrix.topPerformers.map((p) => _buildProviderCard(p, true)),

          const SizedBox(height: 24),

          // Section: Needs Attention
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'يحتاجون إلى متابعة إدارية وتنبيه',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              Text(
                '${matrix.needsAttention.length} مهني',
                style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (matrix.needsAttention.isEmpty)
            const Text('لا يوجد مهنيون بحاجة لمتابعة حرجة حالياً', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))
          else
            ...matrix.needsAttention.map((p) => _buildProviderCard(p, false)),
        ],
      ),
    );
  }

  Widget _buildProviderCard(ProviderPerformanceItem p, bool isStar) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isStar ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isStar ? Colors.green.shade100 : Colors.red.shade100,
                child: Icon(
                  isStar ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
                  color: isStar ? Colors.green.shade800 : Colors.red.shade800,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      p.profession,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isStar ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  p.tierLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isStar ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniMetric('التقييم', '${p.avgRating} ★', Colors.amber.shade800),
              _buildMiniMetric('المنجز', '${p.completedJobs}', Colors.blue.shade800),
              _buildMiniMetric('الإنجاز', '${p.completionRate}%', Colors.teal.shade800),
              _buildMiniMetric('الشكاوى', '${p.complaintsCount}', p.complaintsCount > 0 ? Colors.red : Colors.grey),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isStar ? Colors.green.shade50.withValues(alpha: 0.5) : Colors.red.shade50.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              p.adminAction,
              style: TextStyle(
                fontSize: 11,
                color: isStar ? Colors.green.shade900 : Colors.red.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }

  // 4. Service Demand Analysis Tab (Example 3)
  Widget _buildServiceDemandTab(ServiceDemandAnalysis demand) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Specialization Deficit Card
          if (demand.specializationDeficit.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.campaign_rounded, color: Colors.amber.shade900, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'تخصصات بحاجة لاستقطاب مزيد من الفنيين',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...demand.specializationDeficit.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '• ${s.nameAr}: ${s.recommendation ?? ''}',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900, height: 1.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Most Demanded
          const Text(
            'الخدمات الأكثر طلباً وإقبالاً',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          ...demand.mostDemanded.map((s) => _buildServiceTile(s, true)),

          const SizedBox(height: 20),

          // Least Demanded
          const Text(
            'الخدمات الأقل طلباً (فرص تنشيط وتسويق)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          ...demand.leastDemanded.map((s) => _buildServiceTile(s, false)),
        ],
      ),
    );
  }

  Widget _buildServiceTile(ServiceDemandItem s, bool isHigh) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHigh ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isHigh ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: isHigh ? Colors.green : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.nameAr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                Text(
                  s.categoryName,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${s.requestsCount} طلب',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isHigh ? Colors.green.shade800 : Colors.grey.shade700,
                ),
              ),
              Text(
                '${s.activeProvidersCount} فني متاح',
                style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Complaints Hotspots Tab (Example 4)
  Widget _buildComplaintsTab(ComplaintsHotspotsData complaints) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Overview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: complaints.totalComplaints > 0 ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: complaints.totalComplaints > 0 ? Colors.red.shade200 : Colors.green.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  complaints.totalComplaints > 0 ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                  color: complaints.totalComplaints > 0 ? Colors.red : Colors.green,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إجمالي الشكاوى المسجلة بالمنصة: ${complaints.totalComplaints}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: complaints.totalComplaints > 0 ? Colors.red.shade900 : Colors.green.shade900,
                          fontSize: 14,
                        ),
                      ),
                      const Text(
                        'رصد مناطق النزاع وجودة الخدمة للتدخل الإداري الاستباقي',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Hotspots by Service
          const Text(
            'أعلى الخدمات تسجيلاً للشكاوى',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          if (complaints.hotspotsByService.isEmpty)
            const Text('لا توجد شكاوى مرتبطة بخدمات معينة', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))
          else
            ...complaints.hotspotsByService.map(
              (h) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.build_rounded, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        h['service_name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${h['complaints_count']} شكوى',
                        style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Hotspots by Location
          const Text(
            'أعلى المناطق تسجيلاً للشكاوى',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          if (complaints.hotspotsByLocation.isEmpty)
            const Text('لا توجد شكاوى متمركزة في مناطق محددة', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))
          else
            ...complaints.hotspotsByLocation.map(
              (h) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 18, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        h['location_name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${h['complaints_count']} شكوى',
                        style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
