// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:quick_parcel/admin/admin_login.dart';
import 'package:quick_parcel/services/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Admin login renders core controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const AdminLoginScreen()),
    );

    expect(find.text('Admin Portal'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in to dashboard'), findsOneWidget);
  });
}
