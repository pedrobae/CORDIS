#!/bin/sh

# Fail this script if any subcommand fails.
set -e

# The default execution directory of this script is the ci_scripts directory.
cd $CORDIS 

# Install Flutter (if not already available in the environment)
if ! command -v flutter &> /dev/null
then
    echo "Flutter is not installed. Installing Flutter SDK..."
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
    export PATH="$PATH:$HOME/flutter/bin"
else
    echo "Flutter is already installed."
fi

# Install Flutter artifacts for iOS (--ios), or macOS (--macos) platforms.
flutter precache --ios

# Install Flutter dependencies.
flutter pub get

# Install CocoaPods using Homebrew.
HOMEBREW_NO_AUTO_UPDATE=1 # disable homebrew's automatic updates.
brew install cocoapods

# Install CocoaPods dependencies.
cd ios && pod install --repo-update
cd ..

exit 0
