![Retargetly](https://github.com/retargetly/sdk-ios/blob/master/rely_artboard.png)

# Retargetly iOS SDK

*Retargetly iOS SDK* is a tracking library for iOS.

## Getting Started

These instructions will get you a copy of the project up for running on your local machine for development and testing purposes.

After a git clone, open 'Retargetly.xcodeproj' file to explore the project.

The main focus of the library is to track events, separately in four event-types:

```
open     -  for library initialization
geo      -  for when app uses GPS
deeplink -  for external deeplinks that opens the app
custom   -  for developer's choice
```

### Prerequisites

```
Cocoapods
Xcode - Swift 5
```

### Installing

In order to use the library, it must be included in the project via *cocoapods*, then install pods. You can install *cocoapods* by this way:

```
$ gem install cocoapods
```

Then, specify 'Retargetly' pod in *podfile*:

```
pod 'Retargetly'
```

Add the following sources in *podfile*:

```
 source 'https://github.com/CocoaPods/Specs.git'
 source 'https://github.com/retargetly/RetargetlyPodSpecs.git'
```

And finally, install the pods into project:

```
$ pod install
```


## Usage

After installing, you might do some changes in the project that has *Retargetly iOS SDK*, the first thing is initialize the library, below we can see two(2) ways to do this

The recommended place to initialize the library is 'AppDelegate' file:

```Swift
import Retargetly
...

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> {

    // initialization with full control 
    ...
    RManager.initiate(with: source_hash, sendGeoData: sendGeoData, forceGPS: forceGPS, sendLanguageEnabled: sendLanguageEnabled, sendManufacturerEnabled: sendManufacturerEnabled, sendDeviceNameEnabled: sendDeviceNameEnabled, sendWifiNameEnabled: sendWifiNameEnabled) { (error) in
    ...
    }
    ...
    
    
    // initialization with preset configuration
    ...
    RManager.initiate(sourceHash: sourceHash) { (error) in
    ...
    }
    ...

    return true
}
```

It will automatically track the 'open' event every time it initializes.

**Note:** In order to use 'sendGeoData' and 'forceGPS' with true values,  A key-value *NSLocationAlwaysAndWhenInUseUsageDescription* must be included in the 'info.plist' file. You can also use an instance of *CLLocationManager*, named 'locationManager' or a *RLocationManager* object named 'rLocationManager' in order to use the same object that controls location services within the library, like so:

```Swift
import Retargetly
...

class MyViewController: UIViewController, CLLocationManagerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Delegate to RLocationManager object from SDK
        RManager.default.rLocationManager?.delegate
        // Delegate to CLLocationManager object from RLocationManager on SDK
        RManager.default.rLocationManager?.locationManager.delegate = self
    }
    
    ...
}
```

In order to allow the SDK to fetch location values in background, you must set a key-value *UIBackgroundModes* with *location* subvalue in the 'info.plist'.

*Retargetly iOS SDK* is capable to track the 'deeplink' event every time an external URL opens the application using the SDK, in order to do so, you must make an inheritance from *RAppDelegate* class on your '@UIApplicationMain AppDelegate' class.

Also, *Retargetly iOS SDK* will send 'geo' events when the application has permissions and has all configuration, it follows an internal logic to track the device location only when needed.

Finally, an example how to track a 'custom' event:

```Swift
import Retargetly
...

func anAction() {

    ...
    let aJSONStyleValue = ["aCustomValueField": "someValue", "aCustomValueField2": 200]
    RManager.default.track(value: aJSONStyleValue) {(error) in
        print(error)
    }
    ...

}
```

The 'custom' event, allows you to have an complation callback, and it might have an 'error' object if it occurred. You can send an JSON style object like  [String: Any] on the 'value' param.

## Built With

* [Swift 5](https://swift.org/documentation/) - Programming language
* [Cocoapods](https://cocoapods.org/) - Dependency Management


## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/retargetly/sdk-ios/releases).

## Authors

* [**José Valderrama**](https://www.linkedin.com/in/josevalderrama92/)
---
###### Which is the information that the SDK sends to the DMP?

- Device ID: anonymous advertising identificator, the ones provided by Google and Apple.
- Type of event: which is the event that triggered the data reception, it may be application open, custom event (if configured), geo event (if activated), or deeplink (if configured).
- Custom Data: this is only for custom events. Custom events send custom data in key/value format.
- Lat/Long/Accuracy (if geo is active): when gps data is being tracked on the SDK, geo events are being sent to the DMP.
- Installed apps: only on open events. It sends a list of installed apps on the device (only works for android).
- Manufacturer: device manufacturer name.
- Device: celular model.
- Application: which is the current application that is sending the data.
- Language: which is the device configured language.
- Wifi Name: which is the name of the wifi that the user is connected to.
