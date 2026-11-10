import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ipsubnettingcalculator/main.dart';

void main() {
  testWidgets('shows subnet results for the default IPv4 address', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const SubnetApp());

    expect(find.text('IP & SUBNETTING'), findsOneWidget);
    expect(find.text('192.168.1.0/24'), findsWidgets);
    expect(
      find.byKey(const ValueKey('subnet-summary-carousel')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('network-detail-swiper')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('summary-page-indicator-0')),
      findsOneWidget,
    );
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('shows validation feedback for an invalid IPv4 address', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const SubnetApp());

    await tester.enterText(
      find.byKey(const ValueKey('ip-address-field')),
      '192.168.1.999',
    );
    await tester.tap(find.byKey(const ValueKey('calculate-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('validation-error')), findsOneWidget);
    expect(find.byKey(const ValueKey('network-result')), findsNothing);
  });

  testWidgets('recalculates the network address for a new IP', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const SubnetApp());

    await tester.enterText(
      find.byKey(const ValueKey('ip-address-field')),
      '10.20.30.40',
    );
    await tester.tap(find.byKey(const ValueKey('calculate-button')));
    await tester.pumpAndSettle();

    expect(find.text('10.20.30.0/24'), findsWidgets);
    expect(find.text('10.20.30.255'), findsOneWidget);
  });

  testWidgets('calculates /31 point-to-point networks', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const SubnetApp());

    await tester.enterText(
      find.byKey(const ValueKey('ip-address-field')),
      '10.0.0.1',
    );
    final prefixDropdown = tester.widget<DropdownButton<int>>(
      find.byKey(const ValueKey('prefix-dropdown')),
    );
    prefixDropdown.onChanged!(31);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calculate-button')));
    await tester.pumpAndSettle();

    expect(find.text('10.0.0.0/31'), findsWidgets);
    expect(find.text('10.0.0.1'), findsWidgets);
  });

  testWidgets('summary carousel advances to the next subnet metric', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const SubnetApp());

    final carousel = find.byKey(const ValueKey('subnet-summary-carousel'));
    await tester.ensureVisible(carousel);
    await tester.drag(carousel, const Offset(-260, 0));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('summary-page-indicator-1')),
      findsOneWidget,
    );
    expect(find.text('192.168.1.255'), findsOneWidget);
  });

  testWidgets('detail cards advance through the card swiper', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const SubnetApp());

    final swiperFinder = find.byKey(const ValueKey('network-detail-swiper'));
    await tester.ensureVisible(swiperFinder);
    final swiper = tester.widget<CardSwiper>(swiperFinder);
    swiper.controller!.swipe(CardSwiperDirection.left);
    await tester.pumpAndSettle();

    expect(find.text('2 / 3'), findsOneWidget);
  });
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
