import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mihan_app/controllers/customer_controller.dart';
import 'package:mihan_app/models/catalog_models.dart';
import 'package:mihan_app/views/customer/create_request_view.dart';

class CatalogController extends CustomerController {
  int submissions = 0;
  double? submittedBudget;
  String? submittedAddress;
  final loads = <String>[];
  @override
  List<ServiceModel> get services =>
      const [ServiceModel(id: 1, categoryId: 1, nameAr: 'صيانة الكهرباء')];
  @override
  List<LocationModel> get locations =>
      const [LocationModel(id: 1, nameAr: 'عدن')];
  @override
  Future<void> loadCatalog() async {
    loads.add('catalog');
  }

  @override
  Future<void> loadServicesForCategory(int categoryId) async {
    loads.add('category:$categoryId');
  }

  @override
  Future<bool> createRequest(
      {required int serviceId,
      int? locationId,
      int? providerId,
      required String description,
      String? preferredDate,
      String? preferredTime,
      double? budget,
      String? notes}) async {
    submissions++;
    submittedBudget = budget;
    submittedAddress = notes;
    return false;
  }
}

void main() {
  testWidgets(
      'Request requires service, location, and description before submitting',
      (tester) async {
    final controller = CatalogController();
    await tester.pumpWidget(ChangeNotifierProvider<CustomerController>.value(
      value: controller,
      child:
          const MaterialApp(home: CreateRequestView(preselectedCategoryId: 1)),
    ));
    await tester.pumpAndSettle();
    expect(controller.loads, ['catalog', 'category:1']);
    expect(find.text('التالي'), findsOneWidget);
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('اختر الخدمة المطلوبة'), findsOneWidget);
    expect(find.text('اختر منطقة تنفيذ الخدمة'), findsOneWidget);
    expect(find.text('اكتب وصفًا للمشكلة من 5 أحرف على الأقل'), findsOneWidget);
    expect(controller.submissions, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Three-step request preserves details and requires final review before sending',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = CatalogController();
    await tester.pumpWidget(ChangeNotifierProvider<CustomerController>.value(
      value: controller,
      child: const MaterialApp(home: CreateRequestView()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('صيانة الكهرباء').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('عدن').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).first, 'إنارة المطبخ لا تعمل');
    await tester.enterText(find.byType(TextFormField).last,
        'حي المنصورة، شارع السوق، المبنى الثاني');
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('متى يناسبك؟'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '٢٥٠٠');
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('راجع طلبك قبل إرساله'), findsOneWidget);
    expect(find.text('ميزانيتك المقترحة: 2500 ريال'), findsOneWidget);
    expect(controller.submissions, 0);
    await tester.tap(find.text('تأكيد وإرسال الطلب'));
    await tester.pumpAndSettle();
    expect(controller.submissions, 1);
    expect(controller.submittedBudget, 2500);
    expect(controller.submittedAddress, contains('حي المنصورة'));
    expect(tester.takeException(), isNull);
  });
}
