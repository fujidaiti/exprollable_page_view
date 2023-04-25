# maps_example

An example app which integrates `ExprollablePageView` with [google_maps_flutter](https://pub.dev/packages/google_maps_flutter). This example is based on the tutorial [Adding Goggle Maps to a Flutter app](https://codelabs.developers.google.com/codelabs/google-maps-in-flutter) by Google. Only Android and iOS are supported.

![demo](https://user-images.githubusercontent.com/68946713/234313845-caa8dd75-c9e2-4fd9-b177-f4a6795c4802.gif)

## Prerequirement

A Google Maps API key is required to run this example app. Get your own API key and modify some files as the following instruction.

### 1.Get API key

Go to [Google Maps Platform](https://cloud.google.com/maps-platform/) and get your API key.

### 2. Modify `AndroidManifest.xml` for Android

Open `maps_example/android/app/src/main/AndroidManifest.xml` with your editor and specify your API key in the specific location.

```xml
<meta-data android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_API_KEY"/>
```

### 3. Modify `AppDelegate.swift` for iOS

Open `maps_example/ios/Runner/AppDelegate.swift` and do the same for iOS.

```Swift
GMSServices.provideAPIKey("YOUR_API_KEY")
```

### 4. Build the project

Run the app just as usual, everthing should be fine!

```shell
flutter run
```
