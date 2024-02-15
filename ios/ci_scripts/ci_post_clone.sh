#!/bin/sh

# Fail this script if any subcommand fails.
set -e

# The default execution directory of this script is the ci_scripts directory.
cd $CI_PRIMARY_REPOSITORY_PATH # change working directory to the root of your cloned repo.

echo "API_HOST=$API_HOST" > .env

# Install Flutter using git.
git clone https://github.com/flutter/flutter.git $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

cd $HOME/flutter
git checkout 3.12.0

cd $CI_PRIMARY_REPOSITORY_PATH # change working directory to the root of your cloned repo.

# Install Flutter artifacts for iOS (--ios), or macOS (--macos) platforms.
flutter precache --ios

# Install Flutter dependencies.
flutter pub get

# Install CocoaPods using Homebrew.
HOMEBREW_NO_AUTO_UPDATE=1 # disable homebrew's automatic updates.
brew install cocoapods
pod --version

# Install CocoaPods dependencies.
cd $CI_PRIMARY_REPOSITORY_PATH/ios && pod install # run `pod install` in the `ios` directory.

exit 0
