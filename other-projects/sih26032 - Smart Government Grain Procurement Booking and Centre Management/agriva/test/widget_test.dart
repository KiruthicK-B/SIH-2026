import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agriva/app/app.dart';

void main() {
  testWidgets('AgrivaApp builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AgrivaApp()));
    await tester.pump();
  });
}
