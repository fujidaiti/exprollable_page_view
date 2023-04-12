[![Pub](https://img.shields.io/pub/v/exprollable_page_view.svg?logo=flutter&color=blue&style=flat-square)](https://pub.dev/packages/exprollable_page_view)

# ExprollablePageView

Yet another PageView widget that its viewport expands (shrinks) as it scrolls. **Exprollable** is a coined word combining the words expandable and scrollable. This project is an attemt to clone the modal sheet UI used in [Apple Books](https://www.apple.com/jp/apple-books/) app on iOS.

Here is what you can do with this widget: ([Youtube](https://youtube.com/shorts/L5xxO24UEzc?feature=share))

![demo](https://user-images.githubusercontent.com/68946713/231328800-03038dc6-19e8-4c7c-933b-7e7436ba6619.gif)


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

You can use `ExprollablePageView` just as built-in `PageView` as bellow. `ExprollablePageView` works with any scrollable widget that can accept a `ScrollController`. Note, however, that **it will not work as expected unless you use the `ScrollController` obtained from `PageContentScrollController.of`**.

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

Use `ExprollablePageController` to controll how the viewport changes along the scrolling. Below is an example controller for snapping to the three states:

1. The viewport is completely expanded (`viewportFraction == 1.0`)
2. The viewport is slightly smaller than the screen (`viewportFraction == 0.9`)
3. `viewportFraction == 0.9` and the PageView covers only half of the screen like BottomSheet.

```dart
const peekOffset = ViewportOffset.fractional(0.5);
controller = ExprollablePageController(
  minViewportFraction = 0.9,
  initialViewportOffset: peekOffset,
  maxViewportOffset: peekOffset,
  snapViewportOffsets: [
    ViewportOffset.expanded,
    ViewportOffset.shrunk,
    peekOffset,
  ],
);
```

### Slidable list items

One of the advantages of `ExprollablePageView` over built-in `PageView` is that widgets with horizontal slide action such as [flutter_slidable](https://pub.dev/packages/flutter_slidable) can be used within the each page. You can see an example that uses flutter_slidable in `example/lib/src/complex_example/album_details.dart`.

![SlideActionDemo](https://user-images.githubusercontent.com/68946713/231349155-aa6bb0a7-f85f-4bab-b7d0-30692338f61b.gif)

You can explore all the fuetures in the example app. See `example` directory for more details.

## Lisence

This library is licensed under the MIT license. See the LICENSE file for more details.

## Contributing

If you find any bugs or have suggestions for improvement, please create an issue or a pull request on the GitHub repository. Contributions are welcome and appreciated!
