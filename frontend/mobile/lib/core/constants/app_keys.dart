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
  static const nutritionNavItem = Key('nutrition_nav_item');
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
  static const sleepLogEntryPage = Key('sleep_log_entry_page');
  static const sleepHistoryPage = Key('sleep_history_page');
  static const sleepQualitySelector = Key('sleep_quality_selector');
  static const sleepSaveButton = Key('sleep_save_button');
  static const sleepBedTimePicker = Key('sleep_bed_time_picker');
  static const sleepWakeTimePicker = Key('sleep_wake_time_picker');
  static const sleepNotesField = Key('sleep_notes_field');

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

  // Nutrition
  static const nutritionPage = Key('nutrition_page');
  static const mealLogPage = Key('meal_log_page');
  static const stomachPatternPage = Key('stomach_pattern_page');
  static const dailyMealsView = Key('daily_meals_view');
  static const mealTypeSelector = Key('meal_type_selector');
  static const mealDescriptionField = Key('meal_description_field');
  static const stomachFeelingSelector = Key('stomach_feeling_selector');
  static const stomachNotesField = Key('stomach_notes_field');
  static const saveMealButton = Key('save_meal_button');
  static const voiceInputButton = Key('voice_input_button');
  static const foodSearchField = Key('food_search_field');
  static const foodSearchResults = Key('food_search_results');
  static const foodItemsList = Key('food_items_list');
  static const macroTotalsRow = Key('macro_totals_row');
  static const nutritionDashboardPage = Key('nutrition_dashboard_page');

  // Progress
  static const progressPage = Key('progress_page');
  static const photoCaptureAngleGrid = Key('photo_capture_angle_grid');
  static const photoSaveButton = Key('photo_save_button');
  static const photoTimelinePage = Key('photo_timeline_page');

  // Journal
  static const journalEntryPage = Key('journal_entry_page');
  static const journalHistoryPage = Key('journal_history_page');
  static const reviewAutoCreatedPage = Key('review_auto_created_page');
  static const journalContentField = Key('journal_content_field');
  static const journalSaveButton = Key('journal_save_button');
  static const journalMicButton = Key('journal_mic_button');
  static const journalSkipButton = Key('journal_skip_button');
  static const journalSaveCreateButton = Key('journal_save_create_button');

  // Progression
  static const progressionSuggestionCard = Key('progression_suggestion_card');
  static const progressionDeloadCard = Key('progression_deload_card');
  static const progressionAcceptButton = Key('progression_accept_button');
  static const progressionDismissButton = Key('progression_dismiss_button');
  static const progressionSettingsPage = Key('progression_settings_page');
  static const progressionSaveButton = Key('progression_save_button');

  // Dashboard extras
  static const monthlyHeatMap = Key('monthly_heat_map');
  static const trackTodayGrid = Key('track_today_grid');
  static const quickActionLogJournal = Key('quick_action_log_journal');
  static const quickActionLogMeal = Key('quick_action_log_meal');
  static const quickActionLogSleep = Key('quick_action_log_sleep');
  static const quickActionProgressPhoto = Key('quick_action_progress_photo');

  // Calendar
  static const calendarPage = Key('calendar_page');
  static const calendarMonthGrid = Key('calendar_month_grid');
  static const calendarWeekStrip = Key('calendar_week_strip');
  static const calendarMonthToggle = Key('calendar_month_toggle');
  static const calendarWeekToggle = Key('calendar_week_toggle');
  static const daySessionsSheet = Key('day_sessions_sheet');
  static const startNewSessionButton = Key('start_new_session_button');
}
