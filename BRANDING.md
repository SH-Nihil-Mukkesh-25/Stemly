# Brand Guidelines

Visual identity guidelines for Stemly. Use these when creating screenshots, presentations, social media posts, or marketing materials.

## Name

- **Full name**: Stemly
- **Tagline**: Scan. Analyze. Visualize. Study.
- **Description (short)**: AI-powered STEM learning platform
- **Description (long)**: An AI-powered educational platform that transforms STEM diagrams and problems into interactive simulations, study notes, and quizzes

Do:
- Capitalize "Stemly" (not "stemly" or "STEMLY")
- Use the tagline when space allows

Don't:
- Abbreviate to "SL" or "Stm"
- Add suffixes like "Stemly.ai" or "StemlyApp"

## Color Palette

### Primary Colors

| Name | Hex | Usage |
|------|-----|-------|
| Stemly Blue | `#2196F3` | Primary actions, links, app bar |
| Deep Blue | `#1565C0` | Dark mode primary, headers |
| White | `#FFFFFF` | Backgrounds, text on dark |

### Secondary Colors

| Name | Hex | Usage |
|------|-----|-------|
| Success Green | `#4CAF50` | Correct answers, success states |
| Warning Amber | `#FF9800` | Warnings, pending states |
| Error Red | `#F44336` | Errors, incorrect answers |
| Purple | `#9C27B0` | AI-related features, badges |

### Neutrals

| Name | Hex | Usage |
|------|-----|-------|
| Dark | `#212121` | Dark mode background |
| Medium | `#757575` | Secondary text |
| Light | `#F5F5F5` | Light mode background |

## Typography

| Context | Font | Weight |
|---------|------|--------|
| App UI | Google Fonts (system default) | Regular / Medium / Bold |
| Code | Monospace (system) | Regular |
| Marketing | Sans-serif (Inter, Poppins, or similar) | Regular / Semibold |

## App Theming

Stemly uses Material 3 with a blue color seed:

```dart
ColorScheme.fromSeed(seedColor: Colors.blue)
```

Both light and dark themes are supported, following Material You guidelines.

## Screenshots

When taking screenshots for documentation or marketing:

- Use a clean emulator or device (no personal data visible)
- Use the default theme (light mode for primary screenshots)
- Include the status bar for full-device screenshots
- Crop to the relevant area for feature highlights
- Recommended resolution: 1080x1920 (mobile), 1280x720 (landscape)

Existing screenshots are in `docs/screenshots/`.

## Social Media

### Repository Description

> AI-powered STEM learning platform. Scan physics problems, get interactive simulations, study notes, and quizzes. Built with Flutter + FastAPI + Google Gemini.

### Repository Topics

```
stemly, education, stem, physics, flutter, fastapi, python, dart,
google-gemini, ai, machine-learning, simulations, quiz, open-source,
edtech, learning-platform
```

### Social Preview Image

Recommended dimensions: 1280x640 pixels.

Contents:
- Stemly name and tagline
- 1-2 app screenshots
- Key tech logos (Flutter, FastAPI, Gemini)
- Blue gradient background matching the brand palette

## Media Kit

For presentations, include:
- App screenshots from `docs/screenshots/`
- Architecture diagram from `ARCHITECTURE.md` (mermaid renders)
- Team photo or avatars
- Feature list with icons

## Attribution

When featuring Stemly:
- Link to the GitHub repository
- Credit: "Built by Team Mugiwara Coders at Amrita Vishwa Vidyapeetham"
- License: MIT
