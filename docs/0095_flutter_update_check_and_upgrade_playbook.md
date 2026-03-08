# 0095 - Flutter Update Check and Upgrade Playbook (2026)


This guide shows:
1. How we checked if the old instruction was outdated.
2. How to decide if your project should update now.
3. A safe process you can reuse for future Flutter upgrades.

---

## What we checked (today)

### 1) Check your local Flutter version

```bash
flutter --version
```

Output from your machine:

```text
Flutter 3.35.7 • channel stable
Tools • Dart 3.9.2
```

### 2) Compare against official Flutter release docs

We checked Flutter’s official docs pages:
- Release notes index: https://docs.flutter.dev/release/release-notes
- Flutter 3.41.0 release notes (newer line): https://docs.flutter.dev/release/release-notes/release-notes-3.41.0
- Archive (historical context): https://docs.flutter.dev/release/archive-whats-new

### 3) Validate project health before changing SDK

```bash
flutter analyze
```

Result in this project: only minor lint/import issues (no major compilation blockers).

---

## How to check this yourself in the future

Use this quick decision flow every time:

1. **What am I using now?**
```bash
flutter --version
```

2. **What is latest stable now?**
- Open: https://docs.flutter.dev/release/release-notes
- Compare your version to latest stable line.

3. **Is my project currently healthy?**
```bash
flutter analyze
flutter test
flutter test integration_test
```

4. **Decision**
- If current version is stable and no urgent need: delay upgrade.
- If latest stable has important fixes/features you need: plan upgrade.

---

## Safe upgrade workflow (recommended)

### Step 0: Create a safety branch

```bash
git checkout -b chore/flutter-upgrade-<target-version>
```

### Step 1: Upgrade SDK (outside project or via your SDK manager)

Then verify:

```bash
flutter --version
flutter doctor -v
```

### Step 2: Refresh dependencies

```bash
flutter pub get
flutter pub outdated
flutter pub upgrade --major-versions
```

Tip: if `--major-versions` is too aggressive, upgrade key packages one-by-one.

### Step 3: Apply Flutter automatic fixes

```bash
dart fix --apply
```

### Step 4: Validate

```bash
flutter analyze
flutter test
flutter test integration_test
```

### Step 5: Run app manually

```bash
flutter run -d "iPhone 16"
```

Check important flows:
- App launch
- API call flow
- Theme toggle
- Error handling states

### Step 6: Commit with clear summary

Example commit message:

```text
chore: upgrade Flutter SDK to <version> and align dependencies
```

---

## Common pitfalls during upgrades

- **Pinned transitive versions**: some packages are locked by Flutter SDK.
- **Major package updates**: may include breaking API changes.
- **Integration test infra changes**: iOS/macOS Pod and workspace files may update.
- **Network/certificate surprises**: app can fail even if code compiles.

---

## Practical policy for this project

- Re-check official release notes before each planned upgrade.
- Upgrade in a branch, validate, then merge.

---

## Quick command cheat sheet

```bash
# Inspect
flutter --version
flutter doctor -v
flutter pub outdated

# Validate current project
flutter analyze
flutter test
flutter test integration_test

# Upgrade flow
flutter pub upgrade --major-versions
dart fix --apply
```
