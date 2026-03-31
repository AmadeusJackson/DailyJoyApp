# Daily Joy

Daily Joy is an iOS app with a Widget extension, focused on streaks, challenges, moments, and achievements.

## Project Structure

```text
Daily Joy/
├── Daily Joy/                         # Main app target
│   ├── App Core/
│   ├── Custom Views/
│   ├── Data/
│   ├── Hexagon/
│   ├── Intents/
│   ├── Logic/
│   └── Daily Joy.entitlements
├── Daily JoyTests/                    # Unit tests
├── DailyJoyWidget/                    # Widget extension target
├── DailyJoyWidgetExtension.entitlements
├── Tabs/
│   ├── Achievements/
│   ├── Momonts/
│   └── Challenges/
├── Assets 2.xcassets
├── Frameworks/
└── Products/
```

## Key Areas

- **Streaks & Progress**: Streak tracking and calendar-style heatmap views.
- **Challenges**: Daily challenge models and challenge UI.
- **Moments**: Personal memory/moment logging with media and audio support.
- **Achievements**: Badge unlocking, celebration UI, and sound feedback.
- **Widgets**: WidgetKit-based extension with app intent support.

## Notable Files

- `Daily Joy/Daily Joy/App Core/DailyJoyApp.swift`
- `Daily Joy/Daily Joy/Custom Views/ContentView .swift`
- `Daily Joy/Daily Joy/Logic/BadgeManager.swift`
- `Daily Joy/Daily Joy/Logic/ChallengeManager.swift`
- `Daily Joy/DailyJoyWidget/DailyJoyWidget.swift`
- `Daily Joy/Daily JoyTests/Daily_JoyTests.swift`

## Notes

- Some paths include spaces (for example, `Daily Joy/`).
- The `Momonts` folder name appears intentionally as currently present in the project.
