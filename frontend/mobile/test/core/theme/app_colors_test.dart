import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/core/theme/app_colors.dart';

void main() {
  group('AppColors — brand v1 palette', () {
    test('primary is Terracotta #C4622D', () {
      expect(AppColors.primary, const Color(0xFFC4622D));
    });

    test('accent is Sage #7A9B76 (body-awareness, not CTA)', () {
      expect(AppColors.accent, const Color(0xFF7A9B76));
    });

    test('reward is Soft Gold #D4A84B (milestones only)', () {
      expect(AppColors.reward, const Color(0xFFD4A84B));
    });

    test('light background is Warm Linen #FAF6F0 (never pure white)', () {
      expect(AppColors.background, const Color(0xFFFAF6F0));
      expect(AppColors.surface, const Color(0xFFFFFDFA));
      // Surface must never be pure white.
      expect(AppColors.surface, isNot(const Color(0xFFFFFFFF)));
    });

    test('dark background is Warm Charcoal #1A1612 (never pure black)', () {
      expect(AppColors.backgroundDark, const Color(0xFF1A1612));
      // Never pure black — keeps dark mode organic.
      expect(AppColors.backgroundDark, isNot(const Color(0xFF000000)));
    });

    test('compensation severity ramp is ordered mist → clay', () {
      expect(AppColors.severityResolved, const Color(0xFFC4D5BE));
      expect(AppColors.severityImproving, const Color(0xFF7A9B76));
      expect(AppColors.severityMild, const Color(0xFFD99434));
      expect(AppColors.severityModerate, const Color(0xFFC4622D));
      expect(AppColors.severitySignificant, const Color(0xFFBE4A3A));
    });

    test('gait-phase colors map to brand functional palette', () {
      expect(AppColors.gaitHeelStrike, AppColors.info);
      expect(AppColors.gaitMidStance, AppColors.accent);
      expect(AppColors.gaitToeOff, AppColors.primary);
      expect(AppColors.gaitSwing, AppColors.warning);
    });

    test('legacy aliases resolve to the new semantic tokens', () {
      expect(AppColors.secondary, AppColors.reward);
      expect(AppColors.accentGreen, AppColors.accent);
      expect(AppColors.accentRed, AppColors.error);
      expect(AppColors.surfaceVariant, AppColors.surfaceRaised);
      expect(AppColors.surfaceVariantDark, AppColors.surfaceRaisedDark);
    });
  });
}
