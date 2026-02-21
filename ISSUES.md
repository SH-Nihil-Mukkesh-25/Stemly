# Codebase Health Checks

## HIGH PRIORITY (Security)
- [x] **API Keys in Tests**: `backend/test_quiz.py` and `backend/test_openrouter.py` already use `os.getenv("OPENROUTER_API_KEY")` — no hardcoded keys found.
  - *Status*: Resolved. Both files load the key from the environment.
  - *Remaining*: Ensure `.env` is never committed (already covered by `.gitignore`) and CI injects the key via secrets.

## MEDIUM PRIORITY (Code Quality & Cleanup)
- [x] **Backup Files**: `stemly_app/lib/screens/scan_result_screen.dart.backup` should be removed from the repository.
- [x] **Unused Files**: `backend/test_output.txt` and `backend/test_image.png` appear to be artifacts from testing that should probably be ignored or removed.

## LOW PRIORITY (Technical Debt)
- [ ] **TODO — Firebase Web Client ID**: `stemly_app/lib/services/firebase_auth_service.dart:31` — Replace placeholder Web Client ID with the actual one from Firebase Console.
