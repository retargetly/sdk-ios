![Retargetly](http://www.retargetly.com/retargetly-logo.svg)

# Retargetly iOS SDK

*Retargetly iOS SDK* is a tracking library for iOS.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

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
Xcode - Swift 3
```

### Installing

In order to use the library, it must be included in the project via *cocoapods*, then install pods. You can install *cocoapods* by this way:

```
$ gem install cocoapods
```

Then, specify 'Retargerlty' pod in *podfile*:

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

After installing, you might do some changes in the project that has *Retargetly iOS SDK*, the first thing is initialize the library, like so:

The recommended place to initialize the library is 'AppDelegate' file:

```Swift
import Retargetly
...

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> {

    ...
    RManager.initiate(with: source_hash, sendGeoData: sendGeoData, forceGPS: forceGPS) { (error) in
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

Finally, in order to track an 'custom' event, you need to do so:

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

* [Swift 3](https://swift.org/documentation/) - Programming language
* [Cocoapods](https://cocoapods.org/) - Dependency Management


## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/retargetly/sdk-ios/releases).

## Authors

* [**José Valderrama**](mailto:josevalderrama18@gmail.com) - [NextDots](http://nextdots.com/)
