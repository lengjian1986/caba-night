import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cabakura_frontend/main.dart';
import 'package:cabakura_frontend/services/home_api.dart';

void main() {
  testWidgets('home page renders main sections', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 980);
    tester.view.devicePixelRatio = 1;
    final searchController = TextEditingController();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(searchController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResponsiveHome(
            data: HomeViewData.mock(),
            onAreaSelected: (_) {},
            searchController: searchController,
            onSearch: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Caba Night'), findsOneWidget);
    expect(find.text('人気店舗'), findsOneWidget);
    expect(find.text('人気キャスト'), findsOneWidget);
    expect(find.text('おすすめキャンペーン'), findsOneWidget);
    expect(find.text('NEWS'), findsOneWidget);
  });
}
