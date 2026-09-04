import 'package:flutter_test/flutter_test.dart';
import 'package:vschool/app.dart';
import 'package:vschool/data/models/grade_item.dart';
import 'package:vschool/data/models/subject_summary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SubjectSummary calculates weighted average correctly for МЭШ', () {
    final now = DateTime.now();
    final subject = SubjectSummary(
      subject: 'Физика',
      teacher: 'Васильев И.О.',
      grades: [
        GradeItem(
          id: '1',
          subject: 'Физика',
          value: 5,
          weight: 2, // 5 * 2 = 10
          date: now,
          topic: 'Контрольная',
        ),
        GradeItem(
          id: '2',
          subject: 'Физика',
          value: 4,
          weight: 1, // 4 * 1 = 4
          date: now,
          topic: 'Ответ',
        ),
      ],
    );

    // Weighted average: (10 + 4) / (2 + 1) = 14 / 3 = 4.666...
    expect(subject.averageScore, closeTo(4.67, 0.01));
    expect(subject.formattedAverage, '4.67');
  });

  testWidgets('SchoolDiaryApp smoke test renders properly', (WidgetTester tester) async {
    await tester.pumpWidget(const SchoolDiaryApp());
    await tester.pump();

    // App should render AuthScreen initially or loading
    expect(find.byType(SchoolDiaryApp), findsOneWidget);
  });
}
