# webapp_components

dart pub global activate mono_repo
dart pub global run mono_repo


mono_repo pub get

# Generate Json serializable classes
dart pub add dev:build_runner
dart run build_runner build

