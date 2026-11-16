import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/checkout/presentation/widgets/slide_to_pay_widget.dart';

void main() {
  group('SlideToPayWidget', () {
    testWidgets('renders track, formatted total amount in label, and thumb',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: SlideToPayWidget(
                  totalAmount: 249.00,
                  onConfirmed: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('slide_to_pay_track')), findsOneWidget);
      expect(find.byKey(const Key('slide_to_pay_thumb')), findsOneWidget);
      expect(find.byKey(const Key('slide_to_pay_label')), findsOneWidget);
      expect(
        find.text('SLIDE TO CONFIRM ORDER (\$249.00)'),
        findsOneWidget,
      );
    });

    testWidgets('releasing before 85% threshold snaps thumb back without confirming',
        (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: SlideToPayWidget(
                  totalAmount: 199.20,
                  onConfirmed: () {
                    confirmed = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final thumb = find.byKey(const Key('slide_to_pay_thumb'));
      expect(thumb, findsOneWidget);

      // Drag partially (100px on a 360px width slider is ~32%, well below 85%)
      await tester.drag(thumb, const Offset(100, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(confirmed, isFalse);
    });

    testWidgets('dragging past 85% threshold triggers onConfirmed',
        (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: SlideToPayWidget(
                  totalAmount: 199.20,
                  onConfirmed: () {
                    confirmed = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final thumb = find.byKey(const Key('slide_to_pay_thumb'));
      expect(thumb, findsOneWidget);

      // Drag past threshold (300px on a 360px track is ~97% > 85%)
      await tester.drag(thumb, const Offset(300, 0));
      await tester.pump();

      expect(confirmed, isTrue);
    });

    testWidgets('shows loading spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: SlideToPayWidget(
                  totalAmount: 249.00,
                  isLoading: true,
                  onConfirmed: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows checkmark when isCompleted is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: SlideToPayWidget(
                  totalAmount: 249.00,
                  isCompleted: true,
                  onConfirmed: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });
}
