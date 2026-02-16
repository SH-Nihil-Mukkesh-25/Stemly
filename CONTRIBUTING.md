# Contributing to Stemly

First off, thank you for considering contributing to Stemly! Whether you're a fellow student, an educator, or a developer passionate about STEM education, your contributions make a real difference.

This guide will help you get started. Don't worry if you're new to open source — we were all beginners once, and we're here to help.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Branch Naming](#branch-naming)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Code Style Guidelines](#code-style-guidelines)
- [Testing](#testing)
- [Reporting Issues](#reporting-issues)
- [Getting Help](#getting-help)

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## Getting Started

Stemly is an AI-powered STEM learning platform with two main components:

| Component | Tech Stack | Location |
|-----------|-----------|----------|
| **Frontend** | Flutter / Dart | `stemly_app/` |
| **Backend** | FastAPI / Python | `backend/` |

Before diving in, we recommend:

1. Reading the [README](README.md) to understand what Stemly does
2. Exploring the app to understand the user experience
3. Browsing open [issues](../../issues) to find something that interests you

**Good first issues** are labeled with `good first issue` — these are great starting points for new contributors!

## Development Setup

### Prerequisites

- **Git** (latest)
- **Flutter** 3.x+ and Dart SDK 3.10.1+
- **Python** 3.10+
- **MongoDB** (local or Atlas)
- **Firebase** account and project (see `stemly_app/FIREBASE_SETUP.md`)

### Frontend (Flutter)

```bash
# Clone the repo
git clone https://github.com/SH-Nihil-Mukkesh-25/Stemly.git
cd stemly/stemly_app

# Install dependencies
flutter pub get

# Set up Firebase
# Follow instructions in FIREBASE_SETUP.md

# Run the app
flutter run
```

### Backend (FastAPI)

```bash
cd stemly/backend

# Create and activate virtual environment
python -m venv .venv

# On Windows
.venv\Scripts\activate
# On macOS/Linux
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
# Copy .env.example to .env and fill in your API keys
cp .env.example .env

# Run the development server
uvicorn main:app --reload
```

### Verify Your Setup

- Frontend: App launches on emulator/device without errors
- Backend: API docs available at `http://localhost:8000/docs`

## How to Contribute

### Types of Contributions

We welcome all kinds of contributions:

- **Bug fixes** — Found something broken? Fix it!
- **New features** — Have an idea? Build it!
- **Documentation** — Help others understand the project
- **Tests** — Improve our test coverage
- **UI/UX improvements** — Make Stemly more beautiful and intuitive
- **Physics simulations** — Add new STEM visualizations
- **Translations** — Help make Stemly accessible in more languages

### Workflow

1. **Fork** the repository
2. **Create a branch** from `master` (see [Branch Naming](#branch-naming))
3. **Make your changes** following our [code style guidelines](#code-style-guidelines)
4. **Write/update tests** as needed
5. **Commit** using [conventional commits](#commit-messages)
6. **Push** your branch and open a **Pull Request**

## Branch Naming

Use the following prefixes for your branches:

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feat/` | New features | `feat/add-chemistry-sim` |
| `fix/` | Bug fixes | `fix/login-crash-android` |
| `docs/` | Documentation | `docs/update-api-guide` |
| `refactor/` | Code refactoring | `refactor/quiz-service` |
| `test/` | Adding or updating tests | `test/ai-tutor-unit-tests` |
| `chore/` | Build, CI, dependencies | `chore/update-flutter-deps` |

Keep branch names short, lowercase, and use hyphens to separate words.

## Commit Messages

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>(<scope>): <short description>

[optional body]

[optional footer]
```

### Types

| Type | Description |
|------|-------------|
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation changes |
| `style` | Formatting, missing semicolons, etc. (no code change) |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or updating tests |
| `chore` | Build process, dependency updates, CI changes |
| `perf` | Performance improvements |

### Examples

```
feat(visualiser): add pendulum motion simulation

fix(auth): resolve Google Sign-In crash on Android 14

docs(api): add endpoint documentation for quiz routes

chore(deps): update Flutter to 3.24
```

### Scope (optional)

Use the component or module name: `auth`, `quiz`, `visualiser`, `ai-tutor`, `notes`, `api`, `db`, `ui`.

## Pull Request Process

1. **Fill out the PR template** completely
2. **Link related issues** using keywords (`Closes #123`, `Fixes #456`)
3. **Ensure all checks pass** (linting, tests, build)
4. **Request a review** from at least one maintainer
5. **Respond to feedback** — we review PRs regularly and provide constructive feedback
6. Once approved, a maintainer will **merge your PR**

### PR Tips

- Keep PRs focused — one feature or fix per PR
- Write a clear description of what changed and why
- Include screenshots for UI changes
- Update documentation if your change affects user-facing behavior

## Code Style Guidelines

### Flutter / Dart

- Follow the official [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter analyze` to check for issues before committing
- Format code with `dart format .`
- Use meaningful widget and variable names
- Keep widgets small and composable
- Use `const` constructors wherever possible
- Organize imports: dart, flutter, packages, local (in that order)

```dart
// Good
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quiz_model.dart';
import '../services/api_service.dart';
```

### Python / FastAPI

- Follow [PEP 8](https://pep8.org/)
- Use type hints for function parameters and return types
- Format code with a formatter (e.g., `black` or `ruff format`)
- Use `async/await` for I/O-bound operations
- Keep route handlers thin — delegate logic to service modules
- Use Pydantic models for request/response validation

```python
# Good
async def get_quiz(quiz_id: str) -> QuizResponse:
    quiz = await quiz_service.get_by_id(quiz_id)
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")
    return QuizResponse(**quiz)
```

### General

- No hardcoded secrets or API keys — use environment variables
- Write self-documenting code with clear naming
- Remove dead code and unused imports before committing

## Testing

### Frontend

```bash
cd stemly_app
flutter test
```

### Backend

```bash
cd backend
python -m pytest
```

### Before Submitting

- All existing tests must pass
- New features should include tests where practical
- Bug fixes should include a test that reproduces the bug

## Reporting Issues

Found a bug? Have a feature idea? Please [open an issue](../../issues/new/choose)!

We have templates for:
- **Bug Reports** — Something isn't working
- **Feature Requests** — You have an idea for improvement
- **Questions** — Need help or clarification

### Bug Report Tips

- Include steps to reproduce the issue
- Mention your environment (OS, Flutter version, Python version)
- Include screenshots or error logs if possible
- Check if the issue already exists before creating a new one

## Getting Help

Stuck? Need guidance? Here's how to get help:

- **Open a Question issue** — We're happy to help
- **Comment on an issue** — Ask for clarification on any open issue
- **Read the docs** — Check `README.md` and `docs/` for existing documentation

We believe that **no question is a dumb question**. If something in the codebase is confusing, that's a sign we need better documentation — and you can help with that too!

---

Thank you for being part of Stemly. Together, we're making STEM education more accessible and engaging for everyone.
