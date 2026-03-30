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
  static const goalsNavItem = Key('goals_nav_item');
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
  static const standaloneSessionPage = Key('standalone_session_page');
  static const startWorkoutButton = Key('start_workout_button');
  static const sessionNotesField = Key('session_notes_field');
  static const sessionDoneButton = Key('session_done_button');
  static const addExerciseToSessionButton =
      Key('add_exercise_to_session_button');

  // Assessment
  static const assessmentFlow = Key('assessment_flow');
  static const weeklyPulseDialog = Key('weekly_pulse_dialog');

  // Profile & Onboarding
  static const profilePage = Key('profile_page');
  static const profileEditPage = Key('profile_edit_page');
  static const signOutButton = Key('sign_out_button');
  static const onboardingFlow = Key('onboarding_flow');
  static const onboardingNextButton = Key('onboarding_next_button');
  static const onboardingBackButton = Key('onboarding_back_button');
  static const onboardingSkipButton = Key('onboarding_skip_button');
  static const onboardingDoneButton = Key('onboarding_done_button');
  static const onboardingNameField = Key('onboarding_name_field');
  static const onboardingAgeField = Key('onboarding_age_field');
  static const onboardingHeightField = Key('onboarding_height_field');
  static const onboardingWeightField = Key('onboarding_weight_field');

  // Program
  static const programBuilderPage = Key('program_builder_page');
  static const programDetailPage = Key('program_detail_page');

  // Sleep
  static const sleepEntryWidget = Key('sleep_entry_widget');
  static const sleepHistoryChart = Key('sleep_history_chart');

  // Compensation
  static const compensationProfilePage = Key('compensation_profile_page');
  static const compensationDetailPage = Key('compensation_detail_page');
  static const compensationBodyMap = Key('compensation_body_map');
  static const compensationAddButton = Key('compensation_add_button');
  static const compensationMarkImprovingButton =
      Key('compensation_mark_improving_button');
  static const compensationMarkResolvedButton =
      Key('compensation_mark_resolved_button');

  // Goals
  static const goalListPage = Key('goal_list_page');
  static const goalDetailPage = Key('goal_detail_page');
  static const goalSetupPage = Key('goal_setup_page');
  static const addGoalDialog = Key('add_goal_dialog');
  static const goalNameField = Key('goal_name_field');
  static const goalTargetValueField = Key('goal_target_value_field');
  static const goalUnitField = Key('goal_unit_field');
  static const goalSaveButton = Key('goal_save_button');
  static const goalMarkAchievedButton = Key('goal_mark_achieved_button');
  static const goalAddButton = Key('goal_add_button');
  static const goalSetupDoneButton = Key('goal_setup_done_button');

  // Progress
  static const progressPage = Key('progress_page');
  static const photoCaptureAngleGrid = Key('photo_capture_angle_grid');
  static const photoSaveButton = Key('photo_save_button');
  static const photoTimelinePage = Key('photo_timeline_page');

  // Calendar
  static const calendarPage = Key('calendar_page');
  static const calendarMonthGrid = Key('calendar_month_grid');
  static const calendarWeekStrip = Key('calendar_week_strip');
  static const calendarMonthToggle = Key('calendar_month_toggle');
  static const calendarWeekToggle = Key('calendar_week_toggle');
  static const daySessionsSheet = Key('day_sessions_sheet');
  static const startNewSessionButton = Key('start_new_session_button');
}
