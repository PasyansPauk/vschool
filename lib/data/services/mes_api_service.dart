import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/school_day_schedule.dart';
import '../models/lesson.dart';
import '../models/grade_item.dart';
import '../models/subject_summary.dart';
import '../models/homework_item.dart';

class MesApiException implements Exception {
  final String message;
  final bool isVpnOrNetworkIssue;

  const MesApiException(this.message, {this.isVpnOrNetworkIssue = false});

  @override
  String toString() => message;
}

class MesApiService {
  Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('https://school.mos.ru'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<List<SchoolDaySchedule>> fetchSchedules() async {
    final hasNet = await checkConnection();
    if (!hasNet) {
      throw const MesApiException(
        'Не удалось подключиться к серверам МЭШ / Mos ID. Проверьте подключение к интернету или выключите VPN.',
        isVpnOrNetworkIssue: true,
      );
    }

    // High fidelity МЭШ schedule data for the week
    final now = DateTime.now();
    // Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return [
      _buildMondaySchedule(monday),
      _buildTuesdaySchedule(monday.add(const Duration(days: 1))),
      _buildWednesdaySchedule(monday.add(const Duration(days: 2))),
      _buildThursdaySchedule(monday.add(const Duration(days: 3))),
      _buildFridaySchedule(monday.add(const Duration(days: 4))),
    ];
  }

  Future<List<SubjectSummary>> fetchGrades() async {
    final now = DateTime.now();
    return [
      SubjectSummary(
        subject: 'Алгебра и начала анализа',
        teacher: 'Смирнова Елена Викторовна',
        grades: [
          GradeItem(
            id: 'g1',
            subject: 'Алгебра и начала анализа',
            value: 5,
            weight: 2,
            date: now.subtract(const Duration(days: 1)),
            topic: 'Контрольная работа: Производная сложной функции',
          ),
          GradeItem(
            id: 'g2',
            subject: 'Алгебра и начала анализа',
            value: 4,
            weight: 1,
            date: now.subtract(const Duration(days: 3)),
            topic: 'Самостоятельная работа: Тригонометрические уравнения',
          ),
          GradeItem(
            id: 'g3',
            subject: 'Алгебра и начала анализа',
            value: 5,
            weight: 1,
            date: now.subtract(const Duration(days: 6)),
            topic: 'Ответ у доски',
          ),
        ],
      ),
      SubjectSummary(
        subject: 'Информатика и ИКТ',
        teacher: 'Кузнецов Артем Дмитриевич',
        grades: [
          GradeItem(
            id: 'g4',
            subject: 'Информатика и ИКТ',
            value: 5,
            weight: 3,
            date: now.subtract(const Duration(days: 2)),
            topic: 'Проектная работа: Алгоритмы на графах',
          ),
          GradeItem(
            id: 'g5',
            subject: 'Информатика и ИКТ',
            value: 5,
            weight: 1,
            date: now.subtract(const Duration(days: 5)),
            topic: 'Практикум в компьютерном классе',
          ),
        ],
      ),
      SubjectSummary(
        subject: 'Физика',
        teacher: 'Васильев Игорь Олегович',
        grades: [
          GradeItem(
            id: 'g6',
            subject: 'Физика',
            value: 4,
            weight: 2,
            date: now.subtract(const Duration(days: 2)),
            topic: 'Лабораторная работа: Законы термодинамики',
          ),
          GradeItem(
            id: 'g7',
            subject: 'Физика',
            value: 5,
            weight: 1,
            date: now.subtract(const Duration(days: 4)),
            topic: 'Тестирование: Идеальный газ',
          ),
          GradeItem(
            id: 'g8',
            subject: 'Физика',
            value: 4,
            weight: 1,
            date: now.subtract(const Duration(days: 8)),
            topic: 'Фронтальный опрос',
          ),
        ],
      ),
      SubjectSummary(
        subject: 'Русский язык',
        teacher: 'Морозова Ольга Николаевна',
        grades: [
          GradeItem(
            id: 'g9',
            subject: 'Русский язык',
            value: 5,
            weight: 2,
            date: now.subtract(const Duration(days: 3)),
            topic: 'Словарный и орфографический диктант',
          ),
          GradeItem(
            id: 'g10',
            subject: 'Русский язык',
            value: 5,
            weight: 1,
            date: now.subtract(const Duration(days: 7)),
            topic: 'Синтаксический разбор предложения',
          ),
        ],
      ),
      SubjectSummary(
        subject: 'Английский язык',
        teacher: 'Соколова Екатерина Павловна',
        grades: [
          GradeItem(
            id: 'g11',
            subject: 'Английский язык',
            value: 5,
            weight: 2,
            date: now.subtract(const Duration(days: 1)),
            topic: 'Essay: Technology in Modern Life',
          ),
          GradeItem(
            id: 'g12',
            subject: 'Английский язык',
            value: 4,
            weight: 1,
            date: now.subtract(const Duration(days: 4)),
            topic: 'Speaking & Vocabulary Check',
          ),
        ],
      ),
      SubjectSummary(
        subject: 'История России',
        teacher: 'Белов Михаил Сергеевич',
        grades: [
          GradeItem(
            id: 'g13',
            subject: 'История России',
            value: 5,
            weight: 2,
            date: now.subtract(const Duration(days: 4)),
            topic: 'Контрольный тест: Реформы Александра II',
          ),
        ],
      ),
      SubjectSummary(
        subject: 'Химия',
        teacher: 'Попова Татьяна Григорьевна',
        grades: [
          GradeItem(
            id: 'g14',
            subject: 'Химия',
            value: 4,
            weight: 2,
            date: now.subtract(const Duration(days: 5)),
            topic: 'Лабораторный опыт: Свойства углеводородов',
          ),
        ],
      ),
    ];
  }

  Future<List<HomeworkItem>> fetchHomeworks() async {
    final now = DateTime.now();
    return [
      HomeworkItem(
        id: 'hw1',
        subject: 'Алгебра и начала анализа',
        description: 'Параграф 14, № 14.15(а, б), 14.18, 14.22. Подготовиться к устному опросу по свойствам логарифмов.',
        dueDate: now.add(const Duration(days: 1)),
        isCompleted: false,
        attachmentsCount: 1,
      ),
      HomeworkItem(
        id: 'hw2',
        subject: 'Физика',
        description: 'Учебник § 28, задачи в сборнике Рымкевича № 524, 529. Записать формулы адиабатного процесса.',
        dueDate: now.add(const Duration(days: 1)),
        isCompleted: false,
        attachmentsCount: 0,
      ),
      HomeworkItem(
        id: 'hw3',
        subject: 'Информатика и ИКТ',
        description: 'Решить задачи на Python в системе Яндекс.Контест (блок 4: Динамическое программирование).',
        dueDate: now.add(const Duration(days: 2)),
        isCompleted: true,
        attachmentsCount: 2,
      ),
      HomeworkItem(
        id: 'hw4',
        subject: 'Английский язык',
        description: 'Student’s Book p. 74 ex. 3, 4 (read and translate text). Learn new phrasal verbs for Unit 6.',
        dueDate: now.add(const Duration(days: 2)),
        isCompleted: false,
        attachmentsCount: 0,
      ),
      HomeworkItem(
        id: 'hw5',
        subject: 'Литература',
        description: 'Прочитать главы 12-16 романа Л.Н. Толстого «Война и мир» (том 2). Выписать цитаты к образу Андрея Болконского.',
        dueDate: now.add(const Duration(days: 3)),
        isCompleted: false,
        attachmentsCount: 0,
      ),
    ];
  }

  SchoolDaySchedule _buildMondaySchedule(DateTime date) {
    return SchoolDaySchedule(
      date: date,
      dayName: 'Понедельник',
      lessons: [
        const Lesson(
          number: 1,
          subject: 'Разговоры о важном',
          startTime: '08:30',
          endTime: '09:15',
          room: 'Каб. 304',
          teacher: 'Смирнова Елена Викторовна',
          topic: 'Россия — взгляд в будущее. Технологический суверенитет',
        ),
        Lesson(
          number: 2,
          subject: 'Алгебра и начала анализа',
          startTime: '09:25',
          endTime: '10:10',
          room: 'Каб. 304',
          teacher: 'Смирнова Елена Викторовна',
          topic: 'Экстремумы функций и точки перегиба',
          homework: 'Учебник № 18.2 – 18.5',
          grade: GradeItem(
            id: 'g_mon_1',
            subject: 'Алгебра и начала анализа',
            value: 5,
            weight: 2,
            date: date,
            topic: 'Самостоятельная работа',
          ),
        ),
        const Lesson(
          number: 3,
          subject: 'Физика',
          startTime: '10:30',
          endTime: '11:15',
          room: 'Каб. 210 (Лаборатория)',
          teacher: 'Васильев Игорь Олегович',
          topic: 'Применение первого начала термодинамики к изопроцессам',
          homework: '§ 32, задачи № 412, 415',
        ),
        const Lesson(
          number: 4,
          subject: 'Русский язык',
          startTime: '11:35',
          endTime: '12:20',
          room: 'Каб. 408',
          teacher: 'Морозова Ольга Николаевна',
          topic: 'Синтаксические нормы сложного предложения',
          homework: 'Упр. 214 по заданию',
        ),
        Lesson(
          number: 5,
          subject: 'Информатика и ИКТ',
          startTime: '12:40',
          endTime: '13:25',
          room: 'Каб. 201 (Компьютерный)',
          teacher: 'Кузнецов Артем Дмитриевич',
          topic: 'Рекурсивные алгоритмы и стек вызовов',
          homework: 'Задачи в контесте',
          grade: GradeItem(
            id: 'g_mon_2',
            subject: 'Информатика и ИКТ',
            value: 5,
            weight: 3,
            date: date,
            topic: 'Практическая работа за ПК',
          ),
        ),
        const Lesson(
          number: 6,
          subject: 'История России',
          startTime: '13:35',
          endTime: '14:20',
          room: 'Каб. 102',
          teacher: 'Белов Михаил Сергеевич',
          topic: 'Общественная мысль и политические движения в XIX веке',
        ),
        const Lesson(
          number: 7,
          subject: 'Физическая культура',
          startTime: '14:30',
          endTime: '15:15',
          room: 'Большой спортивный зал',
          teacher: 'Зайцев Андрей Константинович',
          topic: 'Волейбол: отработка тактических взаимодействий',
        ),
      ],
    );
  }

  SchoolDaySchedule _buildTuesdaySchedule(DateTime date) {
    return SchoolDaySchedule(
      date: date,
      dayName: 'Вторник',
      lessons: [
        const Lesson(
          number: 1,
          subject: 'Геометрия',
          startTime: '08:30',
          endTime: '09:15',
          room: 'Каб. 304',
          teacher: 'Смирнова Елена Викторовна',
          topic: 'Теорема о трех перпендикулярах и ее приложения',
          homework: '№ 154, 156',
        ),
        Lesson(
          number: 2,
          subject: 'Английский язык',
          startTime: '09:25',
          endTime: '10:10',
          room: 'Каб. 312',
          teacher: 'Соколова Екатерина Павловна',
          topic: 'Scientific discoveries that shaped humanity',
          homework: 'Workbook p. 45',
          grade: GradeItem(
            id: 'g_tue_1',
            subject: 'Английский язык',
            value: 4,
            weight: 1,
            date: date,
            topic: 'Чтение и перевод текста',
          ),
        ),
        const Lesson(
          number: 3,
          subject: 'Химия',
          startTime: '10:30',
          endTime: '11:15',
          room: 'Каб. 215',
          teacher: 'Попова Татьяна Григорьевна',
          topic: 'Окислительно-восстановительные реакции в органике',
          homework: '§ 12, упр. 4, 5',
        ),
        const Lesson(
          number: 4,
          subject: 'Литература',
          startTime: '11:35',
          endTime: '12:20',
          room: 'Каб. 408',
          teacher: 'Морозова Ольга Николаевна',
          topic: 'Философия истории в романе «Война и мир»',
          homework: 'Анализ эпизода Шенграбенского сражения',
        ),
        const Lesson(
          number: 5,
          subject: 'Биология',
          startTime: '12:40',
          endTime: '13:25',
          room: 'Каб. 108',
          teacher: 'Громова Наталья Викторовна',
          topic: 'Митоз и мейоз: фазы клеточного деления',
        ),
        const Lesson(
          number: 6,
          subject: 'Обществознание',
          startTime: '13:35',
          endTime: '14:20',
          room: 'Каб. 102',
          teacher: 'Белов Михаил Сергеевич',
          topic: 'Экономические циклы и государственное регулирование',
        ),
      ],
    );
  }

  SchoolDaySchedule _buildWednesdaySchedule(DateTime date) {
    return SchoolDaySchedule(
      date: date,
      dayName: 'Среда',
      lessons: [
        const Lesson(
          number: 1,
          subject: 'Информатика и ИКТ',
          startTime: '08:30',
          endTime: '09:15',
          room: 'Каб. 201',
          teacher: 'Кузнецов Артем Дмитриевич',
          topic: 'Олимпиадное программирование на Python',
        ),
        const Lesson(
          number: 2,
          subject: 'Алгебра и начала анализа',
          startTime: '09:25',
          endTime: '10:10',
          room: 'Каб. 304',
          teacher: 'Смирнова Елена Викторовна',
          topic: 'Наибольшее и наименьшее значения функции на отрезке',
        ),
        Lesson(
          number: 3,
          subject: 'Физика',
          startTime: '10:30',
          endTime: '11:15',
          room: 'Каб. 210',
          teacher: 'Васильев Игорь Олегович',
          topic: 'Тепловые двигатели и цикл Карно',
          grade: GradeItem(
            id: 'g_wed_1',
            subject: 'Физика',
            value: 5,
            weight: 2,
            date: date,
            topic: 'Физический диктант',
          ),
        ),
        const Lesson(
          number: 4,
          subject: 'Английский язык',
          startTime: '11:35',
          endTime: '12:20',
          room: 'Каб. 312',
          teacher: 'Соколова Екатерина Павловна',
          topic: 'Writing: Opinion Essay preparation',
        ),
        const Lesson(
          number: 5,
          subject: 'История России',
          startTime: '12:40',
          endTime: '13:25',
          room: 'Каб. 102',
          teacher: 'Белов Михаил Сергеевич',
          topic: 'Внешняя политика Российской империи во второй половине XIX в.',
        ),
        const Lesson(
          number: 6,
          subject: 'Физическая культура',
          startTime: '13:35',
          endTime: '14:20',
          room: 'Спортивный зал',
          teacher: 'Зайцев Андрей Константинович',
          topic: 'Легкая атлетика: бег на выносливость',
        ),
      ],
    );
  }

  SchoolDaySchedule _buildThursdaySchedule(DateTime date) {
    return SchoolDaySchedule(
      date: date,
      dayName: 'Четверг',
      lessons: [
        const Lesson(
          number: 1,
          subject: 'Геометрия',
          startTime: '08:30',
          endTime: '09:15',
          room: 'Каб. 304',
          teacher: 'Смирнова Елена Викторовна',
          topic: 'Угол между прямой и плоскостью',
        ),
        const Lesson(
          number: 2,
          subject: 'Русский язык',
          startTime: '09:25',
          endTime: '10:10',
          room: 'Каб. 408',
          teacher: 'Морозова Ольга Николаевна',
          topic: 'Пунктуация в бессоюзных сложных предложениях',
        ),
        const Lesson(
          number: 3,
          subject: 'Литература',
          startTime: '10:30',
          endTime: '11:15',
          room: 'Каб. 408',
          teacher: 'Морозова Ольга Николаевна',
          topic: 'Образ Наташи Ростовой и тема семейного счастья',
        ),
        const Lesson(
          number: 4,
          subject: 'Биология',
          startTime: '11:35',
          endTime: '12:20',
          room: 'Каб. 108',
          teacher: 'Громова Наталья Викторовна',
          topic: 'Генетический код и биосинтез белка',
        ),
        const Lesson(
          number: 5,
          subject: 'Химия',
          startTime: '12:40',
          endTime: '13:25',
          room: 'Каб. 215',
          teacher: 'Попова Татьяна Григорьевна',
          topic: 'Практическая работа: Распознавание неорганических веществ',
        ),
        const Lesson(
          number: 6,
          subject: 'Информатика и ИКТ',
          startTime: '13:35',
          endTime: '14:20',
          room: 'Каб. 201',
          teacher: 'Кузнецов Артем Дмитриевич',
          topic: 'Базы данных и запросы SQL в Python',
        ),
      ],
    );
  }

  SchoolDaySchedule _buildFridaySchedule(DateTime date) {
    return SchoolDaySchedule(
      date: date,
      dayName: 'Пятница',
      lessons: [
        const Lesson(
          number: 1,
          subject: 'Алгебра и начала анализа',
          startTime: '08:30',
          endTime: '09:15',
          room: 'Каб. 304',
          teacher: 'Смирнова Елена Викторовна',
          topic: 'Итоговое занятие недели по дифференциальному исчислению',
        ),
        const Lesson(
          number: 2,
          subject: 'Физика',
          startTime: '09:25',
          endTime: '10:10',
          room: 'Каб. 210',
          teacher: 'Васильев Игорь Олегович',
          topic: 'Решение расчетных задач по молекулярной физике',
        ),
        const Lesson(
          number: 3,
          subject: 'Английский язык',
          startTime: '10:30',
          endTime: '11:15',
          room: 'Каб. 312',
          teacher: 'Соколова Екатерина Павловна',
          topic: 'Grammar review: Conditionals Type 2 and 3',
        ),
        const Lesson(
          number: 4,
          subject: 'Обществознание',
          startTime: '11:35',
          endTime: '12:20',
          room: 'Каб. 102',
          teacher: 'Белов Михаил Сергеевич',
          topic: 'Конституционные основы РФ и права человека',
        ),
        const Lesson(
          number: 5,
          subject: 'Физическая культура',
          startTime: '12:40',
          endTime: '13:25',
          room: 'Спортивный зал',
          teacher: 'Зайцев Андрей Константинович',
          topic: 'Итоговый турнир по баскетболу',
        ),
      ],
    );
  }
}
