# Firebase Setup Guide for Stemly

## Quick Fix for Google Sign-In Error (ApiException: 10)

This error means your Android app is not properly configured in Firebase Console.

## Step-by-Step Setup

### 1. Install FlutterFire CLI

```bash
flutter pub global activate flutterfire_cli
```

### 2. Configure Firebase for Your Project

```bash
cd stemly_app
flutterfire configure
```

This will:
- Connect to your Firebase project
- Generate `lib/firebase_options.dart` with real credentials
- Optionally download `google-services.json` for Android

### 3. Android-Specific Setup

#### 3.1. Get SHA-1 and SHA-256 Keys

```bash
cd android
./gradlew signingReport
```

Look for the `debug` variant and copy:
- **SHA1**: `XX:XX:XX:...`
- **SHA-256**: `XX:XX:XX:...`

#### 3.2. Add SHA Keys to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** (gear icon)
4. Scroll to **Your apps** → Select your **Android app**
5. Under **SHA certificate fingerprints**, click **Add fingerprint**
6. Paste your **SHA-1** and **SHA-256** keys
7. Click **Save**

#### 3.3. Download google-services.json

1. Still in Firebase Console → Project Settings → Your Android app
2. Click **Download google-services.json**
3. Place it at: `stemly_app/android/app/google-services.json`

**Important:** The package name in Firebase must match: `com.example.stemly_app`

### 4. Verify Configuration

Check that:
- ✅ `lib/firebase_options.dart` has real values (not "ANDROID_API_KEY", etc.)
- ✅ `android/app/google-services.json` exists
- ✅ SHA keys are added in Firebase Console
- ✅ Package name matches: `com.example.stemly_app`

### 5. Clean and Rebuild

```bash
cd stemly_app
flutter clean
flutter pub get
flutter run
```

## Troubleshooting

### Error: "ApiException: 10" or "DEVELOPER_ERROR"

**Cause:** Firebase configuration mismatch

**Fix:**
1. Verify package name in `android/app/build.gradle.kts` matches Firebase
2. Ensure SHA keys are added in Firebase Console
3. Download fresh `google-services.json`
4. Run `flutterfire configure` again
5. Clean rebuild: `flutter clean && flutter run`

### Error: "Missing google-services.json"

**Fix:**
1. Download `google-services.json` from Firebase Console
2. Place at: `android/app/google-services.json`
3. Rebuild the app

### Error: "Firebase is using placeholder values"

**Fix:**
```bash
flutterfire configure
```

This regenerates `firebase_options.dart` with real credentials.

## Backend Setup

Don't forget to configure the backend `.env` file:

```env
MONGO_URI=mongodb://...
GEMINI_API_KEY=...
FIREBASE_CREDENTIALS_FILE=path/to/service-account.json
# OR
FIREBASE_CREDENTIALS_JSON={"type":"service_account",...}
```

## Testing

After setup, test Google Sign-In:
1. Run the app
2. Tap "Continue with Google"
3. Select your Google account
4. Should successfully sign in

If errors persist, check the console logs for detailed error messages.

