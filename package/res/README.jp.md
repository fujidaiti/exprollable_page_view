[![Pub](https://img.shields.io/pub/v/exprollable_page_view.svg?logo=flutter&color=blue&style=flat-square)](https://pub.dev/packages/exprollable_page_view)

# ExprollablePageView

スクロールに合わせてviewportが拡大（縮小）するPageViewです。 **Exprollable**はexpandableとscrollableを組み合わせた造語です。このパッケージはiOS版[Apple Books](https://www.apple.com/jp/apple-books/)アプリのセミモーダルUIを再現しようという試みです。

このWidgetを使えばこのようなUIを簡単に作成することができます: ([Youtube](https://youtube.com/shorts/L5xxO24UEzc?feature=share))

![demo](https://user-images.githubusercontent.com/68946713/231328800-03038dc6-19e8-4c7c-933b-7e7436ba6619.gif)


## 試してみる

サンプルアプリでこのパッケージが提供する全ての機能を試すことができます。

```shell
git clone git@github.com:fujidaiti/exprollable_page_view.git
cd example
flutter pub get
flutter run
```

## インストール

[pub.dev](https://pub.dev/packages/exprollable_page_view)上で公開されているので、`pub`コマンドからインストールできます。

```shell
flutter pub add exprollable_page_view
```

## 使い方

`ExprollablePageView`は通常の`PageView`と同じように使うことができます。各ページには`ScrollController`を取り付けることができるスクロール可能なWidget（例えば`ListView`）を配置してください。**ただし、必ず`PageContentScrollController.of`経由で取得した`ScrollController`を使用してください**。

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

`ExprollablePageController`を使用することでスクロールに伴いviewportがどのように変化するのかを制御することができます。下記のコードは、次の３つの状態にviewportをスナップするコントローラーの例です。

1. 全画面状態(`viewportFraction == 1.0`)
2. viewportが画面横幅より少し小さい状態(`viewportFraction == 0.9`)
3. `viewportFraction == 0.9`で、PageViewがBottom Sheetのように画面の半分だけを覆った状態

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

### スライドアクション

`ExprollablePageView`の利点の一つは、[flutter_slidable](https://pub.dev/packages/flutter_slidable)のような水平方向のスライドアクションを持つWidgetを各ページで使用できることです。`example/lib/src/complex_example/album_details.dart`にflutter_slidableを使用した例があります。

サンプルアプリでその他すべての機能を確認することができます。詳しくは `example` ディレクトリを参照してください。
