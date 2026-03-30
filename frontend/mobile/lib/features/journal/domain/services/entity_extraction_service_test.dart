import 'package:flutter_test/flutter_test.dart';

import 'package:way2move/features/journal/domain/services/entity_extraction_service.dart';

void main() {
  late EntityExtractionService service;

  setUp(() {
    service = const EntityExtractionService();
  });

  // ── Session extraction ────────────────────────────────────────────────────

  group('extractSessions', () {
    test('detects workout keyword', () {
      final sessions =
          service.extractSessions('I did a 30 minute workout this morning.');
      expect(sessions, isNotEmpty);
      expect(sessions.first.durationMinutes, 30);
    });

    test('detects "trained" keyword', () {
      final sessions = service.extractSessions('I trained legs for an hour.');
      expect(sessions, isNotEmpty);
      expect(sessions.first.durationMinutes, 60);
    });

    test('detects "session" keyword', () {
      final sessions =
          service.extractSessions('Had a great session at the gym.');
      expect(sessions, isNotEmpty);
    });

    test('detects "ran" keyword with body area', () {
      final sessions =
          service.extractSessions('I ran for 45 minutes, felt hip tightness.');
      expect(sessions, isNotEmpty);
      expect(sessions.first.durationMinutes, 45);
    });

    test('detects "lifted" keyword', () {
      final sessions = service.extractSessions('I lifted for 20 minutes.');
      expect(sessions, isNotEmpty);
      expect(sessions.first.durationMinutes, 20);
    });

    test('detects "practiced" keyword', () {
      final sessions = service.extractSessions('I practiced yoga.');
      expect(sessions, isNotEmpty);
    });

    test('returns empty list for unrelated text', () {
      final sessions = service.extractSessions('Had a nice breakfast today.');
      expect(sessions, isEmpty);
    });

    test('returns empty list for empty string', () {
      expect(service.extractSessions(''), isEmpty);
    });

    test('returns empty list for gibberish', () {
      expect(service.extractSessions('asdkjlhaksjdhakjsdhqwejh'), isEmpty);
    });

    test('extracts body area when mentioned', () {
      final sessions =
          service.extractSessions('I worked on my shoulders for 30 minutes.');
      expect(sessions, isNotEmpty);
      expect(sessions.first.bodyArea, isNotNull);
      expect(sessions.first.bodyArea, contains('shoulder'));
    });
  });

  // ── Meal extraction ───────────────────────────────────────────────────────

  group('extractMeals', () {
    test('detects "ate" keyword', () {
      final meals = service.extractMeals('I ate chicken and rice for lunch.');
      expect(meals, isNotEmpty);
    });

    test('detects "had breakfast" pattern', () {
      final meals =
          service.extractMeals('Had a big breakfast with eggs and toast.');
      expect(meals, isNotEmpty);
      expect(meals.first.guessedMealType, MealType.breakfast);
    });

    test('detects "dinner" keyword', () {
      final meals = service.extractMeals('For dinner I had pasta.');
      expect(meals, isNotEmpty);
      expect(meals.first.guessedMealType, MealType.dinner);
    });

    test('detects "lunch" keyword', () {
      final meals = service.extractMeals('Lunch was a salad.');
      expect(meals, isNotEmpty);
      expect(meals.first.guessedMealType, MealType.lunch);
    });

    test('detects "snack" keyword', () {
      final meals = service.extractMeals('Had a snack around 3pm.');
      expect(meals, isNotEmpty);
      expect(meals.first.guessedMealType, MealType.snack);
    });

    test('extracts stomach feeling when "bloated" mentioned', () {
      final meals =
          service.extractMeals('I ate lunch but felt bloated afterwards.');
      expect(meals, isNotEmpty);
      expect(meals.first.stomachFeeling, lessThan(3));
    });

    test('extracts stomach feeling when "pain" mentioned', () {
      final meals = service.extractMeals('Dinner gave me stomach pain.');
      expect(meals, isNotEmpty);
      expect(meals.first.stomachFeeling, lessThan(3));
    });

    test('extracts positive stomach feeling when "great" mentioned', () {
      final meals =
          service.extractMeals('I ate breakfast and my stomach felt great.');
      expect(meals, isNotEmpty);
      expect(meals.first.stomachFeeling, greaterThan(3));
    });

    test('defaults stomach feeling to 3 when not mentioned', () {
      final meals = service.extractMeals('I drank coffee this morning.');
      expect(meals, isNotEmpty);
      expect(meals.first.stomachFeeling, 3);
    });

    test('returns empty list for no food mentions', () {
      final meals = service.extractMeals('I did a workout today.');
      expect(meals, isEmpty);
    });

    test('returns empty list for empty string', () {
      expect(service.extractMeals(''), isEmpty);
    });
  });

  // ── Body awareness extraction ─────────────────────────────────────────────

  group('extractBodyMentions', () {
    test('detects "tight" as negative sentiment', () {
      final mentions = service.extractBodyMentions('My hips feel tight today.');
      expect(mentions, isNotEmpty);
      expect(mentions.first.sentiment, 'negative');
    });

    test('detects "sore" as negative sentiment', () {
      final mentions = service.extractBodyMentions('My lower back is sore.');
      expect(mentions, isNotEmpty);
      expect(mentions.first.sentiment, 'negative');
    });

    test('detects "pain" as negative sentiment', () {
      final mentions = service.extractBodyMentions('I have knee pain.');
      expect(mentions, isNotEmpty);
      expect(mentions.first.sentiment, 'negative');
    });

    test('detects "improved" as positive sentiment', () {
      final mentions =
          service.extractBodyMentions('My shoulder has improved a lot.');
      expect(mentions, isNotEmpty);
      expect(mentions.first.sentiment, 'positive');
    });

    test('detects "better" as positive sentiment', () {
      final mentions =
          service.extractBodyMentions('My neck feels better today.');
      expect(mentions, isNotEmpty);
      expect(mentions.first.sentiment, 'positive');
    });

    test('detects "stiff" as negative sentiment', () {
      final mentions =
          service.extractBodyMentions('Ankles were stiff this morning.');
      expect(mentions, isNotEmpty);
      expect(mentions.first.sentiment, 'negative');
    });

    test('returns empty list for no body mentions', () {
      final mentions = service.extractBodyMentions('Had a great day overall.');
      expect(mentions, isEmpty);
    });

    test('returns empty list for empty input', () {
      expect(service.extractBodyMentions(''), isEmpty);
    });

    test('returns empty list for gibberish', () {
      expect(service.extractBodyMentions('xyzqwrasdflkjhzxc'), isEmpty);
    });

    test('extracts body region from text', () {
      final mentions = service.extractBodyMentions('My hips are very tight.');
      expect(mentions.first.bodyRegion, contains('hip'));
    });
  });
}
