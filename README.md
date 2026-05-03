# Sonoet
Training app for musicians.

Sonoet is a Flutter app for practicing note reading with real-time microphone
feedback. It generates a short sequence of notes, listens to the device
microphone, highlights the current note, and advances when the played pitch is
detected steadily enough.

## Stack

- Flutter for the Android/iOS app and custom staff UI.
- Riverpod for practice-session state.
- `record` for PCM16 microphone streaming.
- `pitch_detector_dart` for a first YIN-based pitch detector.

The audio code is deliberately isolated behind `PitchSource` so the detector can
be replaced later with native Android/iOS DSP or an FFI library without
rewriting the UI.

## Setup

Flutter is installed at `G:\Tools\Flutter`. If your current shell does not find
`flutter`, either open a new terminal after updating PATH or run it directly:

```powershell
& 'G:\Tools\Flutter\bin\flutter.bat' --version
& 'G:\Tools\Flutter\bin\flutter.bat' pub get
```

## Android Emulator Setup

Install Android Studio, then open it once and install:

- Android SDK Platform
- Android SDK Platform-Tools
- Android SDK Build-Tools
- Android Emulator
- An Android system image, for example a recent Pixel image

Then create an emulator in Android Studio:

```text
Android Studio > More Actions > Virtual Device Manager > Create Device
```

After the SDK exists, point Flutter at it if needed:

```powershell
& 'G:\Tools\Flutter\bin\flutter.bat' config --android-sdk "C:\Users\<you>\AppData\Local\Android\Sdk"
& 'G:\Tools\Flutter\bin\flutter.bat' doctor --android-licenses
& 'G:\Tools\Flutter\bin\flutter.bat' doctor -v
```

Start an emulator:

```powershell
& 'G:\Tools\Flutter\bin\flutter.bat' emulators
& 'G:\Tools\Flutter\bin\flutter.bat' emulators --launch <emulator_id>
```

Or start it from Android Studio's Device Manager.

## Run

```powershell
& 'G:\Tools\Flutter\bin\flutter.bat' devices
& 'G:\Tools\Flutter\bin\flutter.bat' run -d <android_device_id>
```

## Test

```powershell
& 'G:\Tools\Flutter\bin\flutter.bat' test
& 'G:\Tools\Flutter\bin\flutter.bat' analyze
```

## Build Android

Debug APK:

```powershell
& 'G:\Tools\Flutter\bin\flutter.bat' build apk --debug
```

Release APK:

```powershell
& 'G:\Tools\Flutter\bin\flutter.bat' build apk --release
```

## Current MVP

- Beginner treble range from C4 to C5.
- Random 12-note exercises.
- Real-time pitch stream using microphone PCM16 frames.
- Current/completed/upcoming note highlighting.
- Pitch readout in Hz and cents.
- Simulate-note button for UI testing without an instrument.
