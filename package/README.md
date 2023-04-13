[![Pub](https://img.shields.io/pub/v/exprollable_page_view.svg?logo=flutter&color=blue&style=flat-square)](https://pub.dev/packages/exprollable_page_view)

[English](https://github.com/fujidaiti/exprollable_page_view/blob/master/package/README.md)|[日本語](https://github.com/fujidaiti/exprollable_page_view/blob/master/package/res/README.jp.md)

# ExprollablePageView

Yet another PageView widget that expands its viewport as it scrolls. **Exprollable** is a coined word combining the words expandable and scrollable. This project is an attemt to clone a modal sheet UI used in [Apple Books](https://www.apple.com/jp/apple-books/) app on iOS.

Here is an example of what you can do with this widget: ([Youtube](https://youtube.com/shorts/L5xxO24UEzc?feature=share))

![demo](https://user-images.githubusercontent.com/68946713/231328800-03038dc6-19e8-4c7c-933b-7e7436ba6619.gif)

## Index

- [Try it](#try-it)
- [Install](#install)
- [Usage](#usage)
  - [ExprollablePageView](#exprollablepageview-1)
  - [ExprollablePageController](#exprollablepagecontroller)
    - [Viewport fraction and offset](#viewport-fraction-and-offset)
    - [Overshoot effect](#overshoot-effect)
  - [ModalExprollable](#modalexprollable)
  - [Slidable list items](#slidable-list-items)
- [How to](#how-to)
  - [get the curret page?](#get-the-curret-page)
  - [make the PageView like a BottomSheet?](#make-the-pageview-like-a-bottomsheet)
  - [observe the state of the viewport?](#observe-the-state-of-the-viewport)
    - [1. Listen `ExprollablePageController.viewport`](#1-listen-exprollablepagecontrollerviewport)
    - [2. Listen `PageViewportUpdateNotification`](#2-listen-pageviewportupdatenotification)
  - [add space between pages?](#add-space-between-pages)
  - [prevent my AppBar going off the screen when `overshootEffect` is true?](#prevent-my-appbar-going-off-the-screen-when-overshooteffect-is-true)
- [Questions](#questions)
- [Contributing](#contributing)


## Try it

Run the example application and explore the all features of this package.

```shell
git clone git@github.com:fujidaiti/exprollable_page_view.git
cd example
flutter pub get
flutter run
```

## Install

Add this package to your project using `pub` command.

```shell
flutter pub add exprollable_page_view
```

## Usage

See  [how-to](#how-to) section If you are looking for specific usages.


### ExprollablePageView

You can use `ExprollablePageView` just as built-in `PageView` as bellow. `ExprollablePageView` works with any scrollable widget that can accept a `ScrollController`. Note, however, that **it will not work as expected unless you use a `ScrollController` obtained from `PageContentScrollController.of`**.

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

The constructor of `ExprollablePageView` has almost the same signature as `PageView.builder`. All parameters except `itemBuilder` are passed to the internal `PageView`. See [PageView's docs](https://api.flutter.dev/flutter/widgets/PageView/PageView.builder.html) for more details on each parameter.

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
  });
```

### ExprollablePageController

A subclass of `PageController` that is used by the internal `PageView`. It also controlls how the `ExprollablePageView` changes its viewport as it scrolls.

```dart
  ExprollablePageController({
    super.initialPage,
    super.keepPage,
    double minViewportFraction = 0.9,
    bool overshootEffect = false,
    ViewportOffset initialViewportOffset = ViewportOffset.shrunk,
    ViewportOffset maxViewportOffset = ViewportOffset.shrunk,
    List<ViewportOffset> snapViewportOffsets = const [
      ViewportOffset.expanded,
      ViewportOffset.shrunk,
    ],
  });
```

- `initialPage`: The page to show when first creating the `ExprollablePageView`.

- `minViewportFraction`: The minimum fraction of the viewport that each page should occupy. It must be between 0.0 ~ 1.0.

- `initialViewportOffset`: The initial offset of the viewport. 

- `maxViewportOffset`: The maximum offset of the viewport. Typically used with custom `snapViewportOffsets`. 

- `snapViewportOffsets`: A list of offsets to snap the viewport to. An example of this feature can be found in [make the PageView like a BottomSheet](#make-the-pageview-like-a-bottomsheet) section.

- `overshootEffect`: Indicates if overshoot effect is enabled. See [Overshoot effect](#overshoot-effect) section for more details.

  

#### Viewport fraction and offset

The state of the viewport is described by the 2 mesurements: **fraction** and **offset**. A fraction indicates how much space each page should occupy in the viewport, and it must be between 0.0 and 1.0. An offset is the distance from the top of the viewport to the top of the current page.  

![viewport-fraction-offset](https://user-images.githubusercontent.com/68946713/231830114-f4d9bec4-cb85-41f8-a9fd-7b3f21ff336a.png)

`ViewportOffset` is a class that represents an offset. It has 2 pre-defined offsets, `ViewportOffset.expanded` and `ViewportOffset.shrunk`, at which the viewport fraction is 1.0 and the minimum, respectively. It also has a factory constructor `ViewportOffset.fractional` that creates an offset from a fractional value. For example, `ViewportOffset.fractional(1.0)` is equivalent to `ViewportOffset.shrunk`, and `ViewportOffset.fractional(0.0)` matches the bottom of the viewport. Some examples of the use of this class can be found in [make the PageView like a BottomSheet](#make-the-pageview-like-a-bottomsheet), [observe the state of the viewport](#observe-the-state-of-the-viewport).

![viewport-offsets](https://user-images.githubusercontent.com/68946713/231827251-fed9575c-980a-40b8-b01a-da984d58f3ec.png)



#### Overshoot effect

If `ExprollablePageController.overshootEffect` is enabled, the upper segment of the current page will slightly exceed the top of the viewport when it goes fullscreen. To be precise, this means that the viewport offset will take a negative value when the viewport fraction is 1.0. This trick creates a dynamic visual effect when the page goes fullscreen. The figure below is a demonstration of how the overshoot effect affects (disabled in the left, enabled in the right).

![overshoot-disabled](https://user-images.githubusercontent.com/68946713/231827343-155a750d-b21f-4a96-b81a-74c8873c46cb.gif) ![overshoot-enabled](https://user-images.githubusercontent.com/68946713/231827364-40843efc-5a91-49ff-ab74-c9af1e4b0c62.gif)

Overshoot effect will works correctly only if:

- `MediaQuery.padding.bottom` > 0
- Ther lower segment of `ExprollablePageView` is behind a widget such as `NavigationBar`, `BottomAppBar`

Perhaps the most common use is to wrap an `ExprollablePageView` with a `Scaffold`. In that case, do not forget to enable `Scaffold.extentBody` and then everything should be fine.

```dart
controller = ExprollablePageController(overshootEffect: true);

Widget build(BuildContext context) {
  return Scaffold(
    extendBody: true,
    bottomNavigationBar: BottomNavigationBar(...),
    body: ExprollablePageView(
      controller: controller,
      itemBuilder: (context, page) { ... },
    ),
  );
}
```



### ModalExprollable

Use `ModalExprollable` to create modal dialog style PageViews. This widget adds a traslucent background and *swipe down to dismiss* action to your `ExprollablePageView`. You can use `showModalExprollable` a convenience function that wraps your `ExprollablePageView` with `ModalExprollable` and display it as a dialog. If you want to customize reveal/dismiss behavior of the dialog, create your own `PageRoute` and use `ModalExprollable` in it.

```dart
showModalExprollable(
    context,
    builder: (context) {
      return ExprollablePageView(...);
    },
  );
```

![modal-exprollable](https://user-images.githubusercontent.com/68946713/231827874-71a0ea47-6576-4fcc-ae37-d1bc38825234.gif)


### Slidable list items

One of the advantages of `ExprollablePageView` over built-in `PageView` is that widgets with horizontal slide action such as [flutter_slidable](https://pub.dev/packages/flutter_slidable) can be used within each page. You can see an example that uses flutter_slidable in `example/lib/src/complex_example/album_details.dart`.

![SlideActionDemo](https://user-images.githubusercontent.com/68946713/231349155-aa6bb0a7-f85f-4bab-b7d0-30692338f61b.gif)



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

### make the PageView like a BottomSheet?

Use  `ExprollablePageController` . Below is an example controller for snapping to the three states:

1. The viewport is completely expanded (`viewportFraction == 1.0`)
2. The viewport is slightly smaller than the screen (`viewportFraction == 0.9`)
3. `viewportFraction == 0.9` and the PageView covers only half of the screen like BottomSheet.

For complete code, see [custom_snap_offsets_example.dart](https://github.com/fujidaiti/exprollable_page_view/blob/master/example/lib/src/custom_snap_offsets_example.dart).

```dart
const peekOffset = ViewportOffset.fractional(0.5);
controller = ExprollablePageController(
  minViewportFraction: 0.9,
  initialViewportOffset: peekOffset,
  maxViewportOffset: peekOffset,
  snapViewportOffsets: [
    ViewportOffset.expanded,
    ViewportOffset.shrunk,
    peekOffset,
  ],
);
```

### observe the state of the viewport?

There are 2 ways to observe changes of the viewport state.

#### 1. Listen `ExprollablePageController.viewport`

`ExprollablePageController.viewport` is a `ValueListenable<PageViewportMetrics>` and `PageViewportMetrics` contains the current state of the viewport. Thus, you can listen and use it to perfom some actions that depend on the viewport  state.

```dart
controller.viewport.addListener(() {
  final PageViewportMetrics vp = controller.viewport.value;
  final bool isShrunk = vp.offset >= vp.shrunkOffset;
  final bool isExpanded = vp.offset <= vp.expandedOffset;
});
```

#### 2. Listen `PageViewportUpdateNotification`

`ExprollablePageView` dispatches `PageViewportUpdateNotification` every time its state changes, and it contains a `PageViewportMetrics`. You can listen the notifications using `NotificationListener` widget. Make sure that the `NotificationListener` is an ancestor of the `ExprollablePageView` in your widget tree.

```dart
NotificationListener<PageViewportUpdateNotification>(
        onNotification: (notification) {
          final PageViewportMetrics vp = notification.metrics;
          return false;
        },
        child: child,
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

### prevent my AppBar going off the screen when `overshootEffect` is true?

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



## Questions

If you have any question, feel free to ask them on the [discussions page](https://github.com/fujidaiti/exprollable_page_view/discussions/categories/q-a).



## Contributing

If you find any bugs or have suggestions for improvement, please create an issue or a pull request on the GitHub repository. Contributions are welcome and appreciated!
