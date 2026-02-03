# GratefulMoments — App Overview

## Purpose
GratefulMoments is a SwiftUI-based iOS application designed to help users cultivate gratitude by capturing and reflecting on moments, notes, and photos. The app encourages daily journaling of positive experiences, offering a rich, motivating interface with gamification features.

## Key Features
- **Moment Collection:** Users can add new 'moments' by writing notes and attaching photos. Each moment records a timestamp, title, optional note, and optional image.
- **Search & Organization:** Searchable list of all moments, with support for keyword filtering and sorting by date.
- **Streak & Calendar:** Tracks daily streaks of gratitude entries and provides a heatmap calendar for visualizing activity over time.
- **Celebration Animations:** Celebratory overlays (spinning heart, confetti) appear after new entries to positively reinforce journaling habits.
- **Locking:** Some moments can be marked as 'locked' for privacy, shown as blurred/locked UI until unlocked.
- **Achievements:** Badges are awarded for milestones and displayed in a dedicated Achievements screen.
- **Daily Challenges:** Prompts and challenges for daily gratitude practice to help users build a consistent habit.
- **Memory Lane:** The app surfaces memories from previous years to encourage reflection.
- **First Launch Experience:** Gentle onboarding and notification prompt on initial use.
- **Widget Deep Links:** Binding integration for navigation via widgets or external actions.

## Technical Highlights
- **SwiftUI** for all views and navigation
- **SwiftData** for model persistence/query
- **Environment-based dependency injection** (e.g., DataContainer)
- **Modern toolbar/searchable APIs**
- **Confetti and celebration animations** using SwiftUI
- **Accessibility and VoiceOver labeling**
- **Preview and sample data support** for development

## Developer Notes
- Celebration overlays use local confetti code (see MomentsView) and spinning heart animation.
- Badge celebration effect uses similar confetti but may be visually distinct for achievements.
- Code is modular, with reusable components and extensions for overlays.
- Ensure type names for confetti/celebration are unique to avoid SwiftUI ambiguity.

## Future AI Assistance
- When updating celebration logic, check both MomentsView and Achievements/Badge celebration overlays.
- For new moments, achievements, or search logic, refer to MomentsView as the primary entry point.
- For onboarding or notification logic, see handleFirstLaunchPrompt in MomentsView.
- For issues with confetti or overlays, confirm type names and imports are not ambiguous.

---
