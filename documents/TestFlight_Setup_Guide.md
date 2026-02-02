# iOS TestFlight Setup Guide for Cipher App

**Purpose**: Diagnose your macOS environment and install all dependencies needed to build and upload the Cipher App to TestFlight.

**Target**: Upload a production-ready iOS app build to App Store Connect and create a TestFlight beta.

---

## Phase 1: Environment Diagnosis

Run these commands in Terminal to check your current system state:

```bash
# Check current shell
echo $SHELL

# Check if Xcode is installed
xcode-select -p

# Check Ruby version
ruby --version

# Check CocoaPods installation
pod --version
```

### Expected Output:
- **macOS**: 12.0+ (Monterey or newer)
- **Shell**: `/bin/zsh` (default on Catalina+)
- **Xcode**: `/Applications/Xcode.app/Contents/Developer`
- **Ruby**: 3.0+ (required for modern CocoaPods)
- **CocoaPods**: 1.14+

---

## Phase 2: Install Prerequisites

**Location**: Run these commands from any directory (e.g., your home directory `cd ~`)  
**Purpose**: Install system-wide development tools

### Step 1: Install Xcode (If Not Already Installed)

#### Option A: Install via App Store (Recommended)
```bash
# Open App Store and search for "Xcode"
# Click "Get" and wait for installation (this is ~12-15 GB)
```

#### Option B: Download from Developer Site
Visit [developer.apple.com/download](https://developer.apple.com/download) and download Xcode.

### Step 2: Verify Xcode Installation
```bash
# Ensure Xcode tools are set to the correct path
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Accept Xcode license
sudo xcodebuild -license accept

# Verify
xcode-select -p
# Should return: /Applications/Xcode.app/Contents/Developer
```

### Step 3: Install Homebrew (Dependency Manager)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installation, find your Homebrew installation location:

```bash
# Check where Homebrew installed
which brew
```

Add Homebrew to PATH based on output:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Verify:
```bash
brew --version
which brew
```

### Step 4: Install/Update Ruby (Required for CocoaPods)

Check your current Ruby version:
```bash
ruby --version
```

If it's below 3.0, install a newer version via Homebrew:

```bash
brew install ruby
```

Find where Homebrew Ruby was installed:

```bash
which ruby
# Will show something like /opt/homebrew/opt/ruby/bin/ruby
```

Then find your gems directory:

```bash
gem environment | grep "EXECUTABLE DIRECTORY"
# Will show something like /opt/homebrew/lib/ruby/gems/3.3.0/bin
```

Add both paths to your PATH using the actual locations from above:

```bash
# Example for Apple Silicon (adjust paths based on your `which ruby` and `gem environment` output)
echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zshrc
echo 'export PATH="/opt/homebrew/lib/ruby/gems/3.3.0/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Verify:
```bash
ruby --version
# Should show 3.0+
which ruby
gem --version
```

### Step 5: Install CocoaPods (iOS Dependency Manager)

```bash
# First, verify gem version
gem --version

# Install CocoaPods
gem install cocoapods

# Verify installation
pod --version
which pod
```

If you encounter "Gemfile not found" or other errors, check your gem paths:

```bash
# Find where gems are installed
gem environment | grep "EXECUTABLE DIRECTORY"
# Example output: /opt/homebrew/lib/ruby/gems/3.3.0/bin

# Verify pod is in that directory
ls -la /opt/homebrew/lib/ruby/gems/3.3.0/bin/pod

# If pod is not there, check all gem locations
gem environment

# Add the correct directory to PATH if needed
echo 'export PATH="/opt/homebrew/lib/ruby/gems/3.3.0/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Final verification:
```bash
pod --version
which pod
pod repo update
```

---

### Step 3: Install Flutter


## Phase 4: Prepare & Build Your App

**Location**: Run these commands from your project directory  
**Purpose**: Set up and build your specific app

### Step 2: Get Flutter Dependencies
```bash
cd ~/development/CORDIS
flutter clean
flutter pub get
```

### Step 3: Resolve CocoaPods Dependencies

```bash
cd ios

# Verify CocoaPods is in PATH
which pod
pod --version

# Update the local CocoaPods repository (takes 2-5 minutes)
pod repo update

# Check iOS deployment target in Podfile
grep "platform" Podfile
# Should show: platform :ios, '13.0' or higher

# If iOS version is too low, edit Podfile:
nano Podfile
# Find: platform :ios, '12.0' (or lower)
# Change to: platform :ios, '13.0'
# Save: Ctrl+O, Enter, Ctrl+X

# Install pods
pod install

# If installation fails, try comprehensive clean:
pod deintegrate
rm Podfile.lock
pod install --repo-update
```

### Step 4: Verify Pods Installation
```bash
# Check that Pods were installed
ls Pods
# Should show Firebase and other dependencies

cd ..
```

### Step 5: Build for iOS Release
```bash
flutter build ios --release
# This takes 5-15 minutes depending on your Mac speed
```

---

## Phase 5: Archive & Upload to TestFlight

### Step 1: Open Xcode Workspace

```bash
# IMPORTANT: Always open .xcworkspace, NOT .xcodeproj
open ios/Runner.xcworkspace
```

### Step 2: Configure Signing

In Xcode:
1. Select **Runner** in the left panel
2. Go to **Signing & Capabilities** tab
3. Select your **Team** (your Apple Developer account)
4. Bundle identifier should auto-populate
5. Ensure all targets have a **Team** selected

### Step 3: Archive Your App

In Xcode:
1. Select **"Any iOS Device (arm64)"** in the top toolbar
2. **Product** → **Archive**
3. Wait for build to complete (5-10 minutes)
4. Xcode should auto-open the Organizer showing your archive

### Step 4: Distribute to App Store Connect

In the Organizer window:
1. Select your latest archive
2. Click **Distribute App**
3. Select **App Store Connect**
4. Choose **Upload**
5. Deselect "Manage Version" (unless you're updating an existing version)
6. Sign in with **your Apple ID** (the developer account owner)
7. Select your app from the list
8. Accept any prompts and wait for upload to complete

### Step 5: Verify in App Store Connect

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Select your app
3. Go to **TestFlight** tab
4. Verify your build appears under "Builds"
5. If it shows "Processing", wait 5-15 minutes
6. Once ready, add testers and invite them via email

---

## Troubleshooting Common Issues

### Issue: "Command PhaseScriptExecution failed"
**Solution**: 
```bash
flutter clean
flutter pub get
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

### Issue: "Generated.xcconfig not found"
**Solution**:
```bash
flutter pub get
flutter precache --ios
cd ios
pod install
cd ..
```

### Issue: CocoaPods dependency resolution fails
**Solution**:
```bash
cd ios
pod repo update
pod deintegrate
pod install --repo-update
```

### Issue: "xcode-select: error: unable to get active developer directory"
**Solution**:
```bash
sudo xcode-select --reset
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### Issue: Ruby/Gem version conflicts
**Solution**:
```bash
# Check current Ruby
ruby --version
# Should be 3.0+

# Check gems directory
gem environment | grep "EXECUTABLE DIRECTORY"

# Make sure PATH includes that directory
echo $PATH | grep "gems"
```

---

## Verification Checklist

Before attempting to build, verify all these pass:

- [ ] `xcode-select -p` returns `/Applications/Xcode.app/Contents/Developer`
- [ ] `ruby --version` shows 3.0+
- [ ] `pod --version` shows 1.14+
- [ ] `flutter --version` works
- [ ] `flutter doctor` shows mostly green checkmarks
- [ ] `cd CORDIS && flutter pub get` completes without errors
- [ ] `cd ios && pod install` completes without errors
- [ ] `flutter build ios --release` completes without errors
- [ ] `open ios/Runner.xcworkspace` opens in Xcode without errors

---

## Quick Reference: Full Build & Upload Workflow

```bash
# 1. Navigate to project
cd ~/development/CORDIS

# 2. Get dependencies
flutter pub get
flutter precache --ios

# 3. Install iOS pods
cd ios
pod repo update
pod install
cd ..

# 4. Build release
flutter build ios --release

# 5. Archive in Xcode
open ios/Runner.xcworkspace
# Then: Product → Archive → Distribute App → App Store Connect → Upload

# 6. Clean up (optional, to free space)
rm -rf build
```

---

## Support

If you encounter issues not listed here:

1. Share the **exact error message** from Terminal or Xcode
2. Run `flutter doctor -v` and share output
3. Run `pod install -v` (verbose) to see detailed CocoaPods logs
4. Check `~/Library/Developer/Xcode/DerivedData/` folder size (delete if >10GB to save space)

---

**Last Updated**: January 14, 2026
**For**: Cipher App iOS TestFlight Release
