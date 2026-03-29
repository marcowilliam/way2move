import 'package:flutter/widgets.dart';

abstract class AppKeys {
  // Auth
  static const emailField = Key('email_field');
  static const passwordField = Key('password_field');
  static const confirmPasswordField = Key('confirm_password_field');
  static const nameField = Key('name_field');
  static const submitButton = Key('submit_button');
  static const googleSignInButton = Key('google_sign_in_button');
  static const appleSignInButton = Key('apple_sign_in_button');
  static const createAccountButton = Key('create_account_button');
  static const signInLink = Key('sign_in_link');

  // Navigation
  static const homeScreen = Key('home_screen');
  static const bottomNav = Key('bottom_nav');
  static const homeNavItem = Key('home_nav_item');
  static const calendarNavItem = Key('calendar_nav_item');
  static const exercisesNavItem = Key('exercises_nav_item');
  static const progressNavItem = Key('progress_nav_item');
  static const profileNavItem = Key('profile_nav_item');

  // Exercise
  static const exerciseList = Key('exercise_list');
  static const exerciseSearchField = Key('exercise_search_field');
  static const addExerciseButton = Key('add_exercise_button');
  static const exerciseDetailPage = Key('exercise_detail_page');

  // Session
  static const sessionView = Key('session_view');
  static const completeSessionButton = Key('complete_session_button');
  static const sessionSummaryPage = Key('session_summary_page');

  // Assessment
  static const assessmentFlow = Key('assessment_flow');
  static const weeklyPulseDialog = Key('weekly_pulse_dialog');

  // Profile
  static const profilePage = Key('profile_page');
  static const signOutButton = Key('sign_out_button');

  // Program
  static const programBuilderPage = Key('program_builder_page');
  static const programDetailPage = Key('program_detail_page');

  // Sleep
  static const sleepEntryWidget = Key('sleep_entry_widget');
  static const sleepHistoryChart = Key('sleep_history_chart');
}
