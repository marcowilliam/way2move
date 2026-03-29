# Phase 5 — Social & Coaching: Implementation Checklist

> **Depends on:** Phase 1 (Users, programs, sessions)
> **Can run parallel with:** Phase 2, Phase 3, Phase 4
> **Blocks:** nothing

---

## Block 0 — Coach Role and Permissions

- [ ] Domain: CoachRelationship entity (coachId, athleteId, status, createdAt)
- [ ] Firestore security rules for coach access to athlete data (read-only, athlete-initiated)
- [ ] Invite flow: athlete sends coach invite by email or link
- [ ] Coach accepts/declines invite
- [ ] Coach dashboard: list of connected athletes with quick stats
- [ ] Tests: unit tests for invite logic, security rules tests

---

## Block 1 — Coach Creates Programs for Athletes

- [ ] Coach can view athlete's assessment results and current program
- [ ] Coach creates/edits program on behalf of athlete (uses same ProgramBuilder)
- [ ] Athlete receives notification when coach assigns new program
- [ ] Athlete can accept or request modifications to coach-assigned program
- [ ] Coach sees athlete session completion and progression data
- [ ] Tests: integration tests for coach program assignment flow

---

## Block 2 — Sharing Workouts and Programs

- [ ] Share a completed session as a card (image or link)
- [ ] Share a program template (anyone with link can clone it)
- [ ] Deep link handling for shared programs (open in app or web preview)
- [ ] Privacy controls: choose what is visible when sharing (exercises only, or include sets/reps)
- [ ] Tests: unit tests for share link generation

---

## Block 3 — Community Exercise Library

- [ ] Users can submit custom exercises for community review
- [ ] Moderation queue (admin-only initially, coach-reviewed later)
- [ ] Community exercises appear in search with "community" badge
- [ ] Upvote/save exercises to personal library
- [ ] Tests: integration tests for submission and moderation flow

---

## Block 4 — Progress Sharing

- [ ] Generate progress report (assessment improvements, consistency stats, program completion)
- [ ] Share progress report as image card or PDF
- [ ] Coach can view athlete progress timeline
- [ ] Leaderboards (opt-in): consistency streaks, sessions completed
- [ ] Tests: widget tests for progress report generation
