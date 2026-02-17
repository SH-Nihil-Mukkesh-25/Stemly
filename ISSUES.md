# Codebase Health Checks

## HIGH PRIORITY (Security)
- [ ] **Hardcoded API Keys in Tests**: `backend/test_quiz.py` and `backend/test_openrouter.py` contain a hardcoded `OPENROUTER_API_KEY`.
  - *Mitigation*: Replace with `os.getenv("OPENROUTER_API_KEY")`.
- [ ] **Keystore Credentials**: `stemly_app/android/app/build.gradle.kts` contains hardcoded store/key passwords (`android`/`android`).
  - *Mitigation*: Move to `key.properties` or environment variables for release builds.

## MEDIUM PRIORITY (Code Quality & Cleanup)
- [ ] **Corrupted/Duplicate Configuration**: `stemly_app/pubspec.yaml` contains a large block of commented-out/duplicate YAML at the beginning.
  - *Action*: Clean up the file to only include the active configuration.
- [x] **Backup Files**: `stemly_app/lib/screens/scan_result_screen.dart.backup` should be removed from the repository.
- [x] **Unused Files**: `backend/test_output.txt` and `backend/test_image.png` appear to be artifacts from testing that should probably be ignored or removed.

## LOW PRIORITY (Technical Debt)
- [ ] **TODOs**:
  - `stemly_app/lib/services/firebase_auth_service.dart`: Replace Web Client ID.
  - `stemly_app/android/app/build.gradle.kts`: Specify unique Application ID.
  - `stemly_app/windows/flutter/CMakeLists.txt` & `stemly_app/linux/flutter/CMakeLists.txt`: Move configs to ephemeral files.
