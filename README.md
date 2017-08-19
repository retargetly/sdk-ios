![Retargetly](https://www.google.com.ar/url?sa=i&rct=j&q=&esrc=s&source=images&cd=&cad=rja&uact=8&ved=0ahUKEwjdoou_0ePVAhUGFpAKHZffB5sQjRwIBw&url=http%3A%2F%2Fretargetly.com%2Fblog%2F&psig=AFQjCNEshWp0HgH2sUkuCKZVzm5ke7fWLg&ust=1503243735626480)

# Retargetly

Retargetly is a tracking library for iOS.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

After a git clone, open 'Retargetly.xcodeproj' file to explore the project.

The main focus of the library is to track events, separately in three event-types:

```
open    - for Library Initialization
change  - for front view changed
custom  - for developer's choice
```

### Prerequisites

```
Cocoapods
Xcode - Swift 3
```

### Installing

In order to use the library, it must be included in the project via cocoapods, then install pods. You can install cocoapods by this way:

```
$ gem install cocoapods
```

Then, specify 'Retargerlty' pod in podfile:

```
pod 'Retargetly'
```

And finally, install the pods into project:

```
$ pod install
```


## Usage

After installing, you my do some changes in the project that has Retargetly, the first thing is initialize the library, like so:

The recommended place to initialize the library is 'AppDelegate'

```Swift
import Retargetly
...

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> {

    ...
    RManager.initiate(with: an_ios_hash, pid: an_pid, sid: an_sid)
    ...

return true
}
```

The library will automatically track the 'open' event every time it initializes. In order track an 'change' event, you need to inherit from the class that tracks that event

```Swift
import Retargetly
...

class MyViewController: RViewController {
    ...
}
```

RViewController automatically tracks the 'change' event with its 'viewDidAppear' method.

Finally, in order to track an 'custom' event, you need to do so:

```Swift
import Retargetly
...

func anAction() {

    ...
    RManager.track(value: aValue) {(error) in
        print(error)
    }
    ...

}
```

The 'custom' event, allows you to have an complation callback, and it might have an 'error' object if it ocurred.

## Built With

* [Swift 3](https://swift.org/documentation/) - Programming language
* [Cocoapods](https://cocoapods.org/) - Dependency Management


## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://bitbucket.org/nextdotsjolivieri/retargetly-ios/src#tags).

## Authors

* [**Jos� Valderrama**](mailto:josevalderrama18@gmail.com) - [NextDots](http://nextdots.com/)

