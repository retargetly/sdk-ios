![Retargetly](http://beta.retargetly.com/wp-content/uploads/2015/07/Logo.png)

# Retargetly iOS SDK

*Retargetly iOS SDK* is a tracking library for iOS.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

After a git clone, open 'Retargetly.xcodeproj' file to explore the project.

The main focus of the library is to track events, separately in four event-types:

```
open    -  for library initialization
active  -  for when apps become active
change  -  for front view changed
custom  -  for developer's choice
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
    RManager.initiate(with: ios_hash, pid: pid, sid: sid, forceGPS: true)
    ...

return true
}
```

It will automatically track the 'open' event every time it initializes.

**Note:** In order to use 'forceGPS' with true value,  A key-value *NSLocationWhenInUseUsageDescription* must be included in the 'info.plist' file.

*Retargetly iOS SDK* is capable to track the 'change' event every time an 'UIViewController' subclass or inheritance is presented, by its 'viewDidAppear' method overrided.

Also, the library will track the 'active' event every time the app becomes active (that means when is in foreground), by its 'UIApplicationDidBecomeActive' notification.

Finally, in order to track an 'custom' event, you need to do so:

```Swift
import Retargetly
...

func anAction() {

    ...
    let aJSONstyleValue = ["aCustomValueField": "someValue", "aCustomValueField2": 200]
    RManager.default.track(value: aJSONstyleValue) {(error) in
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
