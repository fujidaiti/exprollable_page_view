[English](https://github.com/fujidaiti/exprollable_page_view/blob/master/package/README.md)|[日本語](https://github.com/fujidaiti/exprollable_page_view/blob/master/package/res/README.jp.md)

[![Pub](https://img.shields.io/pub/v/exprollable_page_view.svg?logo=flutter&color=blue)](https://pub.dev/packages/exprollable_page_view) [![Pub Popularity](https://img.shields.io/pub/popularity/exprollable_page_view)](https://pub.dev/packages/exprollable_page_view) [![Docs](https://img.shields.io/badge/-API%20Reference-orange)](https://pub.dev/documentation/exprollable_page_view/latest/)

# exprollable_page_view 🐦

Yet another PageView widget that expands the viewport of the current page while scrolling it. **Exprollable** is a coined word combining the words expandable and scrollable. This project is an attemt to clone a modal sheet UI used in [Apple Books](https://www.apple.com/jp/apple-books/) app on iOS.

Here is an example of what you can do with this widget:

<img width="260" src="https://user-images.githubusercontent.com/68946713/231328800-03038dc6-19e8-4c7c-933b-7e7436ba6619.gif"> <img width="260" src="https://user-images.githubusercontent.com/68946713/234313845-caa8dd75-c9e2-4fd9-b177-f4a6795c4802.gif">

## Announcement

### 17-05-2023

Version 1.0.0-rc.1 has been released 🎉. This version includes several breaking changes, so if you are already using ^1.0.0-beta, you may need to migrate according to [the migration guide](#100-beta-to-100-rc1).



## Index

- [exprollable\_page\_view 🐦](#exprollable_page_view-)
  - [Announcement](#announcement)
    - [17-05-2023](#17-05-2023)
  - [Index](#index)
  - [Background](#background)
  - [Try it](#try-it)
  - [Install](#install)
  - [Usage](#usage)
    - [ExprollablePageView](#exprollablepageview)
    - [ExprollablePageController](#exprollablepagecontroller)
      - [Viewport fraction and inset](#viewport-fraction-and-inset)
      - [Overshoot effect](#overshoot-effect)
    - [ViewportConfiguration](#viewportconfiguration)
    - [ModalExprollable](#modalexprollable)
    - [Slidable list items](#slidable-list-items)
  - [How to](#how-to)
    - [get the curret page?](#get-the-curret-page)
    - [make the page view like a BottomSheet?](#make-the-page-view-like-a-bottomsheet)
    - [observe the viewport state?](#observe-the-viewport-state)
      - [1. Listen `ExprollablePageController.viewport`](#1-listen-exprollablepagecontrollerviewport)
      - [2. Listen `ViewportUpdateNotification`](#2-listen-viewportupdatenotification)
      - [3. Use `onViewportChanged` callback](#3-use-onviewportchanged-callback)
    - [add space between pages?](#add-space-between-pages)
    - [prevent my app bar going off the screen when overshoote ffect is true?](#prevent-my-app-bar-going-off-the-screen-when-overshoote-ffect-is-true)
    - [animate the viewport state?](#animate-the-viewport-state)
  - [Migration guide](#migration-guide)
    - [^1.0.0-beta to ^1.0.0-rc.1](#100-beta-to-100-rc1)
      - [PageViewportMetrics update](#pageviewportmetrics-update)
      - [ViewportController update](#viewportcontroller-update)
      - [ViewportOffset update](#viewportoffset-update)
      - [ExprollablePageController update](#exprollablepagecontroller-update)
      - [Other renamed classes](#other-renamed-classes)
  - [Questions](#questions)
  - [Contributing](#contributing)


## Background

Books, an e-book reading application from Apple, has a unique user interface; tapping a book cover image displays its details page as a modal view, and the user can swpie the pages back and forth to explore the details of different books, and if the user scrolls vertically up the page, the width of the page gradually expands (or shrinks). The beauty of this UI is that:

- the user can see at a glance that they can move between content by swiping
- it does not reduce the horizontal space for the layout because it can go full-screen
- the page switching by swiping is disabled in fullscreen mode, which allows both horizontal swipe actions like flutter_slidable and page switching in the page view.

<img width="260" src="https://github.com/fujidaiti/exprollable_page_view/assets/68946713/daa8a72f-6904-4b45-ac2b-913e8fb9974a">

Unfortunately, `PageView` widget in flutter framework does not provide ways to dynamically change the size of each page, and this is why I created *exprollable_page_view*.

## Try it

Run the example application and explore the all features of this package.

```shell
git clone git@github.com:fujidaiti/exprollable_page_view.git
cd example
flutter pub get
flutter run
```

There is another example, which demonstrates how `ExprollablePageView` is able to work with Google Maps. See [maps_example/README](https://github.com/fujidaiti/exprollable_page_view/blob/master/maps_example/README.md) for more details.

## Install

Add this package to your project using `pub` command.

```shell
flutter pub add exprollable_page_view
```

## Usage

See  [how-to](#how-to) section if you are looking for specific usages.

### ExprollablePageView

You can use `ExprollablePageView` just as built-in `PageView` as bellow. `ExprollablePageView` works with any scrollable widgets that can accept a `ScrollController`. Note, however, that **it will not work as expected unless you use a `ScrollController` obtained from `PageContentScrollController.of`**.

```dart
import 'package:exprollable_page_view/exprollable_page_view.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: ExprollablePageView(
      itemCount: 5,
      itemBuilder: (context, page) {
        return ListView.builder(
          controller: PageContentScrollController.of(context),
          itemBuilder: (context, index) {
            return ListTile(title: Text('Item#$index'));
          },
        );
      },
    ),
  );
}
```

The constructor of `ExprollablePageView` has almost the same signature as `PageView.builder`. See [the document of PageView](https://api.flutter.dev/flutter/widgets/PageView/PageView.builder.html) for more details on each parameter.

```dart
  const ExprollablePageView({
    Key? key,
    IndexedWidgetBuilder itemBuilder,
    int? itemCount,
    ExprollablePageController? controller,
    bool reverse = false,
    ScrollPhysics? physics,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    bool allowImplicitScrolling = false,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
    ScrollBehavior? scrollBehavior,
    bool padEnds = true,
    void Function(PageViewportMetrics metrics)? onViewportChanged,
    void Function(int page)? onPageChanged,
  });
```

### ExprollablePageController

A subclass of `PageController` that will be attached to the internal `PageView`. It also controlls how the viewport of the current page changes along with vertical scrolling.

```dart
final controller = ExprollablePageController(
  initialPage: 0,
  viewportConfiguration: ViewportConfiguration(
    minFraction: 0.9,
  ),
);
```

Specify a `ViewportConfiguration` with the desired values to tweak the behavior of the page view.

```dart
factory ViewportConfiguration({
  bool overshootEffect = false,
  double minFraction = 0.9,
  double maxFraction = 1.0,
  ViewportInset shrunkInset = ViewportInset.shrunk,
  ViewportInset? initialInset,
  List<ViewportInset> extraSnapInsets = const [],
});
```

- `minFraction`: The fraction of the viewport that each page should occupy when it is shrunk by vertical scrolling.
- `initialInset`: The initial [viewport inset](#viewport-fraction-and-inset).
- `shrunkInset`: A viewport inset at which the current page is fully shrunk.
- `extraSnapInsets`: A list of extra insets the viewport will snap to. An example of the use of this feature can be found in [make the page view like a BottomSheet](#make-the-page-view-like-a-bottomsheet) section.
- `overshootEffect`: Indicates if overshoot effect is enabled. See [Overshoot effect](#overshoot-effect) section for more details.

#### Viewport fraction and inset

The state of the viewport is described by the 2 mesurements: **fraction** and **inset**. The fraction indicates how much space each page should occupy in the viewport, and the inset is the distance from the top of the viewport to the top of the current page viewport. These measurements are managed in `Viewport` class, and can be referenced through the controller. See [observe the vewport state](#observe-the-viewport-state) section for more details.

![viewport-fraction-and-inset](https://github.com/fujidaiti/exprollable_page_view/assets/68946713/128a7788-112f-45fd-957f-626b0176b052)

`ViewportInset` is a class that represents an inset. There are 3 predefined `ViewportInset`s:

- `ViewportInset.expanded`: The default inset at which the current page is fully expanded.
- `ViewportInset.shrunk` : The default inset at which the current page is fully shrunk.
- `ViewportInset.overshoot` : The default inset at which the current page is fully expanded and overshot (see [Overshoot effect](#overshoot-effect)).

User defined insets can be created using `ViewportInset.fixed` and `ViewportInset.fractional`, or you can extend `ViewportInset` to perform more complex calculations. Some examples of the use of this class can be found in [make the PageView like a BottomSheet](#make-the-pageview-like-a-bottomsheet), [observe the state of the viewport](#observe-the-state-of-the-viewport).

![viewport-insets](https://github.com/fujidaiti/exprollable_page_view/assets/68946713/23aa944c-61d4-4578-b194-cf4224fe757c)



#### Overshoot effect

  If the overshoot effect is enabled, the upper segment of the current page viewport will
  slightly exceed the top of the viewport when it goes fullscreen. To be precise, this means that the viewport inset will take a negative value when the viewport fraction is 1. This trick creates a dynamic visual effect when the page goes fullscreen. The 2 figures below are demonstrations of how the overshoot effect affects (enabled in the left, disabled in the middle). The same behavior can be seen in the apple books app (rightmost image).

 <img width="260" src="https://user-images.githubusercontent.com/68946713/231827364-40843efc-5a91-49ff-ab74-c9af1e4b0c62.gif"><img width="260" src="https://user-images.githubusercontent.com/68946713/231827343-155a750d-b21f-4a96-b81a-74c8873c46cb.gif"><img width="260" src="https://github.com/fujidaiti/exprollable_page_view/assets/68946713/ef450917-4339-4ae1-b149-bca1e4699c2a">

Overshoot effect will works correctly only if:

- `MediaQuery.padding.bottom` > 0
- Ther lower segment of `ExprollablePageView` is behind a widget such as `NavigationBar`, `BottomAppBar`

Perhaps the most common use is to wrap an `ExprollablePageView` with a `Scaffold`. In that case, do not forget to enable `Scaffold.extentBody` and then everything should be fine.

```dart
  controller = ExprollablePageController(
    viewportConfiguration: ViewportConfiguration(
     overshootEffect: true, // Enable the overshoot effect
    ),
  );
  
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Do not forget this line
      bottomNavigationBar: BottomNavigationBar(...),
      body: ExprollablePageView(
        controller: controller,
        itemBuilder: (context, page) { ... },
      ),
    );
  }
```

### ViewportConfiguration

`ViewportConfiguration` provides flexible ways to customize viewport behavior. For standard use cases, the unnamed constructor of `ViewportConfiguration` is sufficient. However, if you need more fine-grained control, you can use `ViewportConfiguration.raw` to specify the fraction range and the inset range of the viewport, as well as the position at which the page will shrink/expand. The following snippet is an example of a page view that snaps the current page to the 4 states:

- Collapsed: The page is almost hidden
- Shrunk: It's like a bottom sheet
- Expanded: It's still like a bottom sheet, but the page is expanded
- Fullscreen: The page completely covers the entire screen

```dart
const fullscreenInset = ViewportInset.fixed(0);
const expandedInset = ViewportInset.fractional(0.2);
const shrunkInset = ViewportInset.fractional(0.5);
const collapsedkInset = ViewportInset.fractional(0.9);
final controller = ExprollablePageController(
  viewportConfiguration: ViewportConfiguration.raw(
    minInset: fullscreenInset,
    expandedInset: expandedInset,
    shrunkInset: shrunkInset,
    maxInset: collapsedInset,
    initialInset: collapsedInset,
    snapInsets: [
      fullscreenInset,
      expandedInset,
      shrunkInset,
      collapsedInset,
    ],
  ),
);
```

<img width="260" src="https://github.com/fujidaiti/exprollable_page_view/assets/68946713/1e848ad0-5111-4d5a-8663-ee0b07d813c6">

### ModalExprollable

Use `ModalExprollable` to create modal dialog style page views. This widget adds a translucent background and *swipe down to dismiss* action to your `ExprollablePageView`. You can use `showModalExprollable` a convenience function that wraps your `ExprollablePageView` with `ModalExprollable` and display it as a dialog. If you want to customize reveal/dismiss behavior of the dialog, create your own `PageRoute` and use `ModalExprollable` in it.

```dart
showModalExprollable(
    context,
    builder: (context) {
      return ExprollablePageView(...);
    },
  );
```

<img width="260" src="https://user-images.githubusercontent.com/68946713/231827874-71a0ea47-6576-4fcc-ae37-d1bc38825234.gif">


### Slidable list items

One of the advantages of `ExprollablePageView` over the built-in `PageView` is that widgets with horizontal slide action such as [flutter_slidable](https://pub.dev/packages/flutter_slidable) can be used within a page. You can see an example that uses flutter_slidable in `example/lib/src/complex_example/album_details.dart`.

<img width="260" src="https://user-images.githubusercontent.com/68946713/231349155-aa6bb0a7-f85f-4bab-b7d0-30692338f61b.gif">



## How to

### get the curret page?

Use `ExprollablePageController.currentPage`.

```dart
final page = pageController.currentPage.value;
```

You can also observe changes in `currentPage` as it is type of `ValueListenable<int>` .

```dart
pageController.currentPage.addListener(() {
  final page = pageController.currentPage.value;
});
```

`ExprollablePageView.onPageChanged` is another option to track the current page, which is equivalent to the above solusion as it just listens `ExprollablePageController.currentPage` internally.

```dart
ExprollablePageView(
  onPageChanged: (page) { ... },
);
```



### make the page view like a BottomSheet?

Use  `ExprollablePageController`  and `ViewportConfiguration`. Below is an example controller for snapping to the three states:

1. The page is completely expanded (`Viewport.fraction == 1.0`)
2. The page is slightly smaller than the viewport (`Viewport.fraction == 0.9`)
3. `Viewport.fraction == 0.9` and the page view covers only half of the screen like a bottom sheet.

For complete code, see [custom_snap_offsets_example.dart](https://github.com/fujidaiti/exprollable_page_view/blob/master/example/lib/src/custom_snap_offsets_example.dart).

```dart
controller = ExprollablePageController(
  viewportConfiguration: ViewportConfiguration(
    minFraction: 0.9,
    extraSnapInsets: [
      ViewportInset.fractional(0.5),
    ],
  ),
);
```

### observe the viewport state?

There are 3 ways to observe changes of the viewport state.

#### 1. Listen `ExprollablePageController.viewport`

`ExprollablePageController.viewport` is a `ValueListenable<ViewportMetrics>` and `ViewportMetrics` contains the current state of the viewport. Thus, you can listen and use it to perfom some actions that depend on the viewport  state.

```dart
controller.viewport.addListener(() {
  final ViewportMetrics vp = controller.viewport.value;
  final bool isShrunk = vp.isPageShrunk;
  final bool isExpanded = vp.isPageExpanded;
});
```

#### 2. Listen `ViewportUpdateNotification`

`ExprollablePageView` dispatches `ViewportUpdateNotification` every time its state changes, and it contains a `ViewportMetrics`. You can listen the notifications using `NotificationListener` widget. Make sure that the `NotificationListener` is an ancestor of the `ExprollablePageView` in your widget tree. This method is useful when you want to perform a state dependent action, but do not have a controller.


```dart
NotificationListener<ViewportUpdateNotification>(
        onNotification: (notification) {
          final ViewportMetrics vp = notification.metrics;
          return false;
        },
        child: ...,
```

#### 3. Use `onViewportChanged` callback

The constructor of `ExprollablePageView` accepts a callback that is invoked whenever the viewport state changes.

```dart
ExprollablePageView(
  onPageViewChanged: (ViewportMetrics vp) {...},
);
```


### add space between pages?

Just wrap each page with `PageGutter`.

```dart
ExprollablePageView(
  itemBuilder: (context, page) {
    return PageGutter(
      gutterWidth: 12,
      child: ListView(...),
    );
  },
);
```

### prevent my app bar going off the screen when overshoote ffect is true?

Use `AdaptivePagePadding`. This widget adds appropriate padding to its child according to the current viewpor offset. An example code is found in [adaptive_padding_example.dart](https://github.com/fujidaiti/exprollable_page_view/blob/master/example/lib/src/adaptive_padding_example.dart).

```dart
Container(
  color: Colors.lightBlue,
  child: AdaptivePagePadding(
    child: SizedBox(
      height: height,
      child: const Placeholder(),
    ),
  ),
);
```

### animate the viewport state?

Use `ExprollablePageController.animateViewportInsetTo`.

```dart
// Shrunk the current page with scroll animation in 1 second.
controller.animateViewportInsetTo(
  ViewportInset.shrunk,
  curve: Curves.easeInOutSine,
  duration: Duration(seconds: 1),
);
```

A more concrete example can be seen in [animation_example.dart](https://github.com/fujidaiti/exprollable_page_view/blob/master/example/lib/src/animation_example.dart).

<img width="260" src="https://github.com/fujidaiti/fms/assets/68946713/63b2a875-3b54-4031-9817-a808bce2b3f8">

## Migration guide

### ^1.0.0-beta to ^1.0.0-rc.1

With the release of version 1.0.0-rc.1, there are several breaking changes.

#### PageViewportMetrics update

`PageViewportMetrics` mixin was merged into `ViewportMetrics` mixin and now deleted, and some properties were renamed. Replace the symbols in your code according to the table below:

- `PageViewportMetrics`  👉  `ViewportMetrics`
- `PageViewportMetrics.isShrunk`   👉 `ViewportMetrics.isPageShrunk`
- `PageViewportMetrics.isExpanded`   👉 `ViewportMetrics.isPageExpanded`
- `PageViewportMetrics.xxxOffset`   👉 `ViewportMetrics.xxxInset` (the all properties with suffix `Offset` was renamed with the new suffix `Inset`)
- `PageViewportMetrics.overshootEffect` was deleted

#### ViewportController update

 `ViewportController` class was renamed to `PageViewport` and no longer mixins `ViewportMetrics`.

#### ViewportOffset update

For `ViewportOffset` and its inherited classes, the suffix `Offset` was replaced with the new suffix `Inset`, and 2 new inherited classes were introduced (see [Viewport fraction and inset](#viewport-fraction-and-inset)).

- `ViewportOffset`  👉  `ViewportInset`

- `ExpandedViewportOffset`  👉  `DefaultExpandedViewportinset`
- `ShrunkViewportOffset`  👉  `DefaultShrunkViewportInset`

#### ExprollablePageController update

With the introduction of `ViewportConfiguration`, the signature of `ExprollablePageController`'s constructor was changed.

Before:

```dart
  final controller = ExprollablePageController(
    initialPage: 0,
    minViewportFraction: 0.9,
    overshootEffect: true,
    initialViewportOffset: ViewportOffset.shrunk,
  );
```

After:

```dart
final controller = ExprollablePageController(
  initialPage: 0,
  viewportConfiguration: ViewportConfiguration(
    minFraction: 0.9,
    overshootEffect: true,
    initialInset: ViewportInset.shrunk,
  ),
);
```

In addition, `ExprollablePageController.withAdditionalSnapOffsets` was removed, use `ViewportConfiguration.extraSnapInsets` instead. See [ExprollablePageController](#exprollablepagecontroller) section for more details.

Before:

```dart
final controller = ExprollablePageController.withAdditionalSnapOffsets([
  ViewportOffset.fractional(0.5),
]);
```

After:

```dart
final controller = ExprollablePageController(
  viewportConfiguration: ViewportConfiguration(
    extraSnapOffset: [ViewportInset.fractional(0.5)],
  ),
);
```

#### Other renamed classes

- `StaticPageViewportMetrics`  👉  `StaticViewportMetrics`
- `PageViewportUpdateNotification`  👉  `ViewportUpdateNotification`
- `PageViewport`  👉  `Viewport`



## Questions

If you have any question, feel free to ask them on the [discussions page](https://github.com/fujidaiti/exprollable_page_view/discussions/categories/q-a).



## Contributing

If you find any bugs or have suggestions for improvement, please create an issue or a pull request on the GitHub repository. Contributions are welcome and appreciated!
