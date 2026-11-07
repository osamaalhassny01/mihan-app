import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mihan_app/controllers/customer_controller.dart';
import 'package:mihan_app/controllers/provider_controller.dart';
import 'package:mihan_app/models/request_and_provider_models.dart';
import 'package:mihan_app/views/widgets/request_workflow_widgets.dart';
import 'package:mihan_app/views/customer/customer_request_detail_view.dart';
import 'package:mihan_app/views/provider/provider_request_detail_view.dart';

ServiceRequestModel request(String status,
        {String? quoteStatus, int? quoteId}) =>
    ServiceRequestModel(
      id: 1,
      requestNumber: 'REQ-2026-000123',
      providerName: 'مقدم الخدمة المعتمد',
      providerProfession: 'صيانة عامة',
      providerExperienceYears: 12,
      providerAvgRating: 4.9,
      providerIsVerified: true,
      customerId: 1,
      providerId: 20,
      serviceId: 1,
      description: 'طلب صيانة',
      status: status,
      createdAt: '2026-11-07 09:00:00',
      workflowVersion: 2,
      quoteId: quoteId,
      quoteStatus: quoteStatus,
      quotedPrice: quoteId == null ? null : 1200,
      quoteDetails: quoteId == null ? null : 'أجرة العمل والمواد مشمولة بالسعر',
      completionNotes: 'تم إصلاح العطل واختبار التشغيل',
    );

class WorkflowProvider extends ProviderController {
  @override
  ServiceRequestModel get selectedRequest => request('awaiting_confirmation', quoteStatus: 'approved', quoteId: 5);
  @override
  Future<void> loadRequestDetails(int id) async {}
  int quotes = 0;
  double? price;
  @override
  Future<bool> submitQuote(int id, double price, String details,
      {String? visitAt}) async {
    quotes++;
    this.price = price;
    return true;
  }
}

class WorkflowCustomer extends CustomerController {
  @override
  ServiceRequestModel get selectedRequest => request('awaiting_confirmation', quoteStatus: 'approved', quoteId: 5);
  @override
  Future<void> loadRequestDetails(int id) async {}
  int confirmations = 0;
  int decisions = 0;
  String? rework;
  @override
  Future<bool> confirmCompletion(int id) async {
    confirmations++;
    return true;
  }

  @override
  Future<bool> requestRework(int id, String notes) async {
    rework = notes;
    return true;
  }

  @override
  Future<bool> decideQuote(int id, int quoteId, {required bool approve}) async {
    decisions++;
    return true;
  }
}

Widget panel(ServiceRequestModel req,
        {WorkflowProvider? provider, WorkflowCustomer? customer}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ProviderController>.value(
            value: provider ?? WorkflowProvider()),
        ChangeNotifierProvider<CustomerController>.value(
            value: customer ?? WorkflowCustomer())
      ],
      child: MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: ServiceWorkflowPanel(
                      request: req, isProvider: provider != null)))),
    );

void main() {
  testWidgets(
      'Provider prepares a scoped offer with Arabic digits before starting work',
      (tester) async {
    final provider = WorkflowProvider();
    await tester.pumpWidget(panel(request('accepted'), provider: provider));
    expect(find.text('إعداد عرض الخدمة'), findsOneWidget);
    await tester.tap(find.text('إعداد عرض الخدمة'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '١٢٠٠');
    await tester.enterText(
        find.byType(TextFormField).last, 'العمل والمواد ضمن السعر الإجمالي');
    await tester.tap(find.text('إرسال للعميل'));
    await tester.pumpAndSettle();
    expect(provider.quotes, 1);
    expect(provider.price, 1200);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Customer approval requires explicit confirmation',
      (tester) async {
    final customer = WorkflowCustomer();
    await tester.pumpWidget(panel(
        request('accepted', quoteStatus: 'pending', quoteId: 5),
        customer: customer));
    await tester.tap(find.text('الموافقة على العرض'));
    await tester.pumpAndSettle();
    expect(customer.decisions, 0);
    await tester.tap(find.text('أوافق على العرض'));
    await tester.pumpAndSettle();
    expect(customer.decisions, 1);
  });

  testWidgets(
      'Customer receipt requires confirmation before issuing the invoice',
      (tester) async {
    final customer = WorkflowCustomer();
    await tester.pumpWidget(panel(
        request('awaiting_confirmation', quoteStatus: 'approved', quoteId: 5),
        customer: customer));
    await tester.ensureVisible(find.text('تأكيد الاستلام وإصدار الفاتورة'));
    await tester.tap(find.text('تأكيد الاستلام وإصدار الفاتورة'));
    await tester.pumpAndSettle();
    expect(customer.confirmations, 0);
    await tester.tap(find.text('نعم، استلمت الخدمة'));
    await tester.pumpAndSettle();
    expect(customer.confirmations, 1);
  });

  testWidgets(
      'Rework asks for specific notes instead of accepting incomplete work',
      (tester) async {
    final customer = WorkflowCustomer();
    await tester.pumpWidget(panel(
        request('awaiting_confirmation', quoteStatus: 'approved', quoteId: 5),
        customer: customer));
    await tester.ensureVisible(find.text('توجد ملاحظات قبل الاستلام'));
    await tester.tap(find.text('توجد ملاحظات قبل الاستلام'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إرسال الملاحظات'));
    await tester.pumpAndSettle();
    expect(customer.rework, isNull);
    await tester.enterText(
        find.byType(TextFormField), 'لا يزال هناك تسرب بعد الإصلاح');
    await tester.tap(find.text('إرسال الملاحظات'));
    await tester.pumpAndSettle();
    expect(customer.rework, 'لا يزال هناك تسرب بعد الإصلاح');
  });

  testWidgets('Request details fit a small phone for both customer and provider', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final page in const [CustomerRequestDetailView(requestId: 1), ProviderRequestDetailView(requestId: 1)]) {
      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<CustomerController>(create: (_) => WorkflowCustomer()),
        ChangeNotifierProvider<ProviderController>(create: (_) => WorkflowProvider()),
      ], child: MaterialApp(home: Directionality(textDirection: TextDirection.rtl, child: page))));
      await tester.pumpAndSettle();
      expect(find.text('رحلة خدمتك'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  test('Old request payloads keep the legacy workflow', () {
    final old = ServiceRequestModel.fromJson({'id': 1, 'status': 'accepted'});
    expect(old.usesAgreement, false);
    expect(old.canStart, true);
    final current = ServiceRequestModel.fromJson({
      'id': 1,
      'status': 'accepted',
      'workflow_version': '2',
      'quote_id': '5',
      'quote_status': 'pending',
      'quoted_price': '1200.00'
    });
    expect(current.usesAgreement, true);
    expect(current.canStart, false);
    expect(current.quotedPrice, 1200);
  });
}
