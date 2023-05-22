[![Pub](https://img.shields.io/pub/v/exprollable_page_view.svg?logo=flutter&color=blue)](https://pub.dev/packages/exprollable_page_view) [![Pub Popularity](https://img.shields.io/pub/popularity/exprollable_page_view)](https://pub.dev/packages/exprollable_page_view) [![Docs](https://img.shields.io/badge/-API%20Reference-orange)](https://pub.dev/documentation/exprollable_page_view/latest/)

# exprollable_page_view 🐦

スクロールに合わせてページが拡大（縮小）するPageViewです。 **Exprollable**はexpandableとscrollableを組み合わせた造語です。このパッケージはiOS版[Apple Books](https://www.apple.com/jp/apple-books/)アプリのセミモーダルUIを再現しようという試みです。

このWidgetを使えばこのようなUIを簡単に作成することができます:

<img width="260" src="https://user-images.githubusercontent.com/68946713/231328800-03038dc6-19e8-4c7c-933b-7e7436ba6619.gif"> <img width="260" src="https://user-images.githubusercontent.com/68946713/234313845-caa8dd75-c9e2-4fd9-b177-f4a6795c4802.gif">

## アナウンス

### 2023/05/17

バージョン1.0.0-rc.1がリリースされました 🎉！このバージョンはいくつかの破壊的な変更を含んでいます。もしベータ版（1.0.0-beta.xx）をすでに使用中の場合、コードの修正が必要になるかもしれません。詳しくは [マイグレーションガイド](#100-beta-to-100-rc1)をご覧ください。


## 目次

- [exprollable\_page\_view 🐦](#exprollable_page_view-)
  - [アナウンス](#アナウンス)
    - [2023/05/17](#20230517)
  - [目次](#目次)
  - [試してみる](#試してみる)
  - [インストール](#インストール)
  - [使い方](#使い方)
    - [ExprollablePageView](#exprollablepageview)
    - [ExprollablePageController](#exprollablepagecontroller)
      - [Viewport fraction と inset](#viewport-fraction-と-inset)
      - [Overshoot effect](#overshoot-effect)
    - [ViewportConfiguration](#viewportconfiguration)
    - [ModalExprollable](#modalexprollable)
    - [スライドアクションを持つリストアイテム](#スライドアクションを持つリストアイテム)
  - [How-to](#how-to)
    - [現在のページを取得する](#現在のページを取得する)
    - [PageViewをBottomSheetのように表示する](#pageviewをbottomsheetのように表示する)
    - [viewportの状態を監視する](#viewportの状態を監視する)
      - [1. `ExprollablePageController.viewport`を監視する](#1-exprollablepagecontrollerviewportを監視する)
      - [2. `ViewportUpdateNotification`を監視する](#2-viewportupdatenotificationを監視する)
      - [3. `onViewportChanged` コールバックを使用する](#3-onviewportchanged-コールバックを使用する)
    - [ページ間にスペースを追加する](#ページ間にスペースを追加する)
    - [overshoot effectが有効なときapp barが画面の外に飛び出してしまうのを防ぐ](#overshoot-effectが有効なときapp-barが画面の外に飛び出してしまうのを防ぐ)
    - [viewportの状態をアニメーションで動かす](#viewportの状態をアニメーションで動かす)
  - [マイグレーションガイド](#マイグレーションガイド)
    - [^1.0.0-beta から ^1.0.0-rc.1](#100-beta-から-100-rc1)
      - [PageViewportMetricsの変更](#pageviewportmetricsの変更)
      - [ViewportControllerの変更](#viewportcontrollerの変更)
      - [ViewportOffsetの変更](#viewportoffsetの変更)
      - [ExprollablePageControllerの変更](#exprollablepagecontrollerの変更)
      - [その他シンボル名の変更](#その他シンボル名の変更)

## 試してみる

サンプルアプリでこのパッケージが提供する全ての機能を試すことができます。

```shell
git clone git@github.com:fujidaiti/exprollable_page_view.git
cd example
flutter pub get
flutter run
```

また`ExprollablePageView`とGoogle Maps APIを統合するサンプルもあります。詳しくは [maps_example/README](https://github.com/fujidaiti/exprollable_page_view/blob/master/maps_example/README.md)をご覧ください。

## インストール

[pub.dev](https://pub.dev/packages/exprollable_page_view)上で公開されているので、`pub`コマンドからインストールできます。

```shell
flutter pub add exprollable_page_view
```

## 使い方

特定の使用方法をお探しの場合は[How-to](#how-to)セクションをご覧下さい。

### ExprollablePageView

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
          // これを忘れずに
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

`ExprollablePageView`のコンストラクタは`PageView.builder`コンストラクタとほとんど同じシグネチャを持ちます。各パラメータの詳細は[PageViewの公式ドキュメント](https://api.flutter.dev/flutter/widgets/PageView/PageView.builder.html)をご覧ください。

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

`PageView`の`PageController`と同様に、`ExprollablePageController`は`ExprollablePageView`の表示ページを制御するオブジェクトです。またviewportの振る舞いを制御するためにも使用されます。

```dart
final controller = ExprollablePageController(
  initialPage: 0,
  viewportConfiguration: ViewportConfiguration(
    minFraction: 0.9,
  ),
);
```

`ViewportConfiguration`のパラメータを調整することでviewportの振る舞いを細かく決めることができます。

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

- `minFraction`：viewportに対する各ページの最小縮小率
- `initialInset`：[viewport inset](#viewport-fraction-and-inset)の初期値
- `shrunkInset`： ページが完全に縮小されるときのviewport inset
- `extraSnapInsets`： ページをスナップさせるinsetのリスト（詳しくは[ページビューをボトムシートのようにする](#make-the-page-view like-a-bottomsheet) を参照）
- `overshootEffect`：overshoot effectが有効かどうか（詳しくは[オーバーシュート効果](#overshoot-effect)セクションを参照）

#### Viewport fraction と inset

viewportの状態は**fraction**と**inset**の２つによって表されます。fractionは各ページのサイズがviewportに対してどのくらいの割合であるかを示し、またinsetはviewportの上部から現在のページの上部までの距離を表します。これらの状態は`Viewport`クラスが管理しており、`ExprollablePageController`を通じて参照することができます。詳しくは[viewportの状態を監視する](#observe-the-viewport-state)をご覧ください。

![viewport-fraction-and-inset](https://github.com/fujidaiti/exprollable_page_view/assets/68946713/128a7788-112f-45fd-957f-626b0176b052)

`ViewportInset`はinset値を表現するためのクラスです。事前定義されたinsetは3種類あり、それぞれ定数として定義されています。

- `ViewportInset.expanded`: ページが完全に拡大されるデフォルトのinset
- `ViewportInset.shrunk` : ページが完全に縮小されるデフォルトのinset
- `ViewportInset.overshoot` : [overshoot effect](#overshoot-effect)を有効にする際に使用されるinset

ユーザー定義のinsetは`ViewportInset.fixed`や`ViewportInset.fractional`から作成できます。また`ViewportInset`を継承したクラスを作成することでより複雑な計算を実行することができます。これらのクラスの使用例は[make the PageView like a BottomSheet](#make-the-pageview-like-a-bottomsheet), [observe the state of the viewport](#observe-the-state-of-the-viewport)で見ることができます。

![viewport-insets](https://github.com/fujidaiti/exprollable_page_view/assets/68946713/23aa944c-61d4-4578-b194-cf4224fe757c)



#### Overshoot effect

overshoot effectはページが拡大される際の視覚効果です。これが有効になっている場合、ページがフルスクリーンになる時、ページの上部がviewportの上部を少しだけはみ出すような挙動をとります。より正確に言えば、fractionが1になる時insetが負の値をとるということです。これにより図のようなダイナミックな視覚効果が得られます（左：overshoot effectあり、真ん中：なし）。Apple BooksアプリのUIでもこのような挙動が実現されています（右図）。

 <img width="260" src="https://user-images.githubusercontent.com/68946713/231827364-40843efc-5a91-49ff-ab74-c9af1e4b0c62.gif"><img width="260" src="https://user-images.githubusercontent.com/68946713/231827343-155a750d-b21f-4a96-b81a-74c8873c46cb.gif"><img width="260" src="https://github.com/fujidaiti/exprollable_page_view/assets/68946713/ef450917-4339-4ae1-b149-bca1e4699c2a">

overshoot effectが正しく動作するには以下の条件を満たす必要があります。

- `MediaQuery.padding.bottom` > 0
- `NavigationBar`や`BottomAppBar`のようなwidgetが`ExprollablePageView`の下部を覆い隠している

おそらく最もよくある使用方法は`Scaffold`の中に`ExprollablePageView`を設置することでしょう。その場合`Scaffold.bottomNavigationBar`を指定し、`Scaffold.extentBody`を有効にしてください。これにより上記の条件が満たされます。

```dart
  controller = ExprollablePageController(
    viewportConfiguration: ViewportConfiguration(
     overshootEffect: true, // overshoot effectを有効にする
    ),
  );
  
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // これを忘れずに
      bottomNavigationBar: BottomNavigationBar(...),
      body: ExprollablePageView(
        controller: controller,
        itemBuilder: (context, page) { ... },
      ),
    );
  }
```

### ViewportConfiguration

`ViewportConfiguration` はviewportの動作をカスタマイズするための柔軟な方法を提供します。ほとんどのケースでは`ViewportConfiguration`の無名コンストラクタで十分だと思いますが、より細かい制御が必要な場合は、`ViewportConfiguration.raw`を使用してください。viewport fractionとinsetの範囲、またページが完全に拡大（縮小）する位置を指定することができます。以下のコードはページを4つの状態にスナップさせる`ExprollablePageController`の例です。

- Collapsed: ページがほとんど隠れた状態
- Shrunk: bottom sheetのような状態
- Expanded: Shrunkと似ているが、ページが拡大されている状態
- Fullscreen: 全画面状態

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

`ModalExprollable`を使用すれば、半透明の背景と「下にスワイプして閉じる」アクションを持つモーダルダイアログ形式の`ExprollablePageView`を簡単に作成することができます。`showModalExprollable`関数は、`ExprollablePageView`を`ModalExprollable`でラップし、ダイアログとして表示する便利な方法です。ダイアログの表示/非表示時の動作をカスタマイズする場合は、独自の`PageRoute`を作成し`ModalExprollable`その中で`ModalExprollable`を使用してください。

```dart
showModalExprollable(
    context,
    builder: (context) {
      return ExprollablePageView(...);
    },
  );
```

<img width="260" src="https://user-images.githubusercontent.com/68946713/231827874-71a0ea47-6576-4fcc-ae37-d1bc38825234.gif">


### スライドアクションを持つリストアイテム

組み込みの`PageView`に対する`ExprollablePageView`の利点の一つは、[flutter_slidable](https://pub.dev/packages/flutter_slidable)などの水平方向のスライドアクションを持つウィジットをページ内で使用できることです。より詳しい例は`example/lib/src/complex_example/album_details.dart`で見ることができます。

<img width="260" src="https://user-images.githubusercontent.com/68946713/231349155-aa6bb0a7-f85f-4bab-b7d0-30692338f61b.gif">



## How-to

### 現在のページを取得する

`ExprollablePageController.currentPage`から取得できます。

```dart
final page = pageController.currentPage.value;
```

 `currentPage` は`ValueListenable<int>` 型なので、リスナーを作成して変更を検知することもできます。

```dart
pageController.currentPage.addListener(() {
  final page = pageController.currentPage.value;
});
```

別の方法として、`ExprollablePageView.onPageChanged`コールバックを指定することでページの変更を監視することができます。これは内部的に上記のコードと等価なことをしています。

```dart
ExprollablePageView(
  onPageChanged: (page) { ... },
);
```

### PageViewをBottomSheetのように表示する

`ExprollablePageController`と`ViewportConfiguration`を使用してください。以下は、3つの状態にスナップするためのコントローラの例である：

1. ページが完全に展開されている (`Viewport.fraction == 1.0`)
2. ページがビューポートより少し小さい (`Viewport.fraction == 0.9`)
3. 3. `Viewport.fraction == 0.9`で、ページビューがボトムシートのように画面の半分だけをカバーする。

コードの詳細は、[custom_snap_offsets_example.dart](https://github.com/fujidaiti/exprollable_page_view/blob/master/example/lib/src/custom_snap_offsets_example.dart)を参照してください。

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

### viewportの状態を監視する

viewportの状態を監視する方法は3つあります。

#### 1. `ExprollablePageController.viewport`を監視する

`ExprollablePageController.viewport`は `ValueListenable<ViewportMetrics>` で、 `ViewportMetrics` にはビューポートの現在の状態が含まれます。したがって、ビューポートの状態に依存するアクションを実行するために、ビューポートをリッスンして使用することができます。

```dart
controller.viewport.addListener(() {
  final ViewportMetrics vp = controller.viewport.value;
  final bool isShrunk = vp.isPageShrunk;
  final bool isExpanded = vp.isPageExpanded;
});
```

#### 2. `ViewportUpdateNotification`を監視する

`ExprollablePageView`は、状態が変化するたびに `ViewportUpdateNotification` をディスパッチし、その中に `ViewportMetrics` が含まれます。この通知は `NotificationListener` ウィジェットを使って聞くことができます。ウィジェットツリーで `NotificationListener` が `ExprollablePageView` の祖先であることを確認してください。このメソッドは、状態依存のアクションを実行したいが、コントローラがない場合に便利です。


```dart
NotificationListener<ViewportUpdateNotification>(
        onNotification: (notification) {
          final ViewportMetrics vp = notification.metrics;
          return false;
        },
        child: ...,
```

#### 3. `onViewportChanged` コールバックを使用する

`ExprollablePageView`のコンストラクタは、ビューポートの状態が変化するたびに呼び出されるコールバックを受け取ります。

```dart
ExprollablePageView(
  onPageViewChanged: (ViewportMetrics vp) {...},
);
```


### ページ間にスペースを追加する

各ページを`PageGutter`で囲ってください。

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

### overshoot effectが有効なときapp barが画面の外に飛び出してしまうのを防ぐ

`AdaptivePagePadding`を使用します。このウィジェットは、現在のビューポートのオフセットに従って、子ウィジェットに適切なパディングを追加します。コードの例は [adaptive_padding_example.dart](https://github.com/fujidaiti/exprollable_page_view/blob/master/example/lib/src/adaptive_padding_example.dart) にあります。

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

### viewportの状態をアニメーションで動かす

 `ExprollablePageController.animateViewportInsetTo`を使用します。以下のコードは1秒かけてスクロールアニメーションと共にページを縮小する例です。

```dart
// Shrunk the current page with scroll animation in 1 second.
controller.animateViewportInsetTo(
  ViewportInset.shrunk,
  curve: Curves.easeInOutSine,
  duration: Duration(seconds: 1),
);
```

より具体的な例は[animation_example.dart](https://github.com/fujidaiti/exprollable_page_view/blob/master/example/lib/src/animation_example.dart)で見ることができます。

<img width="260" src="https://github.com/fujidaiti/fms/assets/68946713/63b2a875-3b54-4031-9817-a808bce2b3f8">

## マイグレーションガイド

### ^1.0.0-beta から ^1.0.0-rc.1

1.0.0-rc.1のリリースに伴い、いくつかの破壊的変更があります。

#### PageViewportMetricsの変更

`PageViewportMetrics`mixinは `ViewportMetrics` mixinに統合され、削除されました。またそれに伴い一部のプロパティ名も変更されています。以下に従ってコード内のシンボル名を置き換えてください：

- `PageViewportMetrics`  👉  `ViewportMetrics`
- `PageViewportMetrics.isShrunk`   👉 `ViewportMetrics.isPageShrunk`
- `PageViewportMetrics.isExpanded`   👉 `ViewportMetrics.isPageExpanded`
- `PageViewportMetrics.xxxOffset`   👉 `ViewportMetrics.xxxInset` （接尾辞`Offset`は`Inset`で置換）

また`PageViewportMetrics.overshootEffect` は削除されました。

#### ViewportControllerの変更

 `ViewportController` クラスは `PageViewport` に名前が変更されました。また`PageViewport`は`ViewportMetrics` を実装していません（削除されたため）。

#### ViewportOffsetの変更

For `ViewportOffset` and its inherited classes, the suffix `Offset` was replaced with the new suffix `Inset`, and 2 new inherited classes were introduced (see [Viewport fraction and inset](#viewport-fraction-and-inset)).

- `ViewportOffset`  👉  `ViewportInset`

- `ExpandedViewportOffset`  👉  `DefaultExpandedViewportinset`
- `ShrunkViewportOffset`  👉  `DefaultShrunkViewportInset`

#### ExprollablePageControllerの変更

`ViewportConfiguration`の導入に伴い、`ExprollablePageController`のコンストラクタのシグネチャも変更されました。

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

加えて`ExprollablePageController.withAdditionalSnapOffsets` も削除されたため、代わりに`ViewportConfiguration.extraSnapInsets`を使用してください。詳しくは[ExprollablePageController](#exprollablepagecontroller)をご覧ください。

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

#### その他シンボル名の変更

- `StaticPageViewportMetrics`  👉  `StaticViewportMetrics`
- `PageViewportUpdateNotification`  👉  `ViewportUpdateNotification`
- `PageViewport`  👉  `Viewport`
