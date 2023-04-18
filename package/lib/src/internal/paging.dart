/// Copied and modified from:
/// - https://github.com/flutter/flutter/tree/master/packages/flutter/lib/src/widgets/page_view.dart
/// - https://github.com/flutter/flutter/tree/master/packages/flutter/lib/src/rendering/sliver_fill.dart
///
/// Changes done:
/// - Replace [SliverFillViewport] with [_SliverFillViewport] in [_PageViewState.build]
/// - In [_RenderSliverFillViewport.performLayout], force the children to always occupy the parent viewport,
///   regardless of [_RenderSliverFillViewport.itemExtent].

// Copyright 2014 The Flutter Authors. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
// ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// The methods defined in this class are copied and modified from the following file:
// - https://github.com/flutter/flutter/tree/master/packages/flutter/lib/src/rendering/sliver_fill.dart
class _RenderSliverFillViewport extends RenderSliverFillViewport {
  _RenderSliverFillViewport({
    required super.childManager,
    super.viewportFraction,
  });

  int _calculateLeadingGarbage(int firstIndex) {
    RenderBox? walker = firstChild;
    int leadingGarbage = 0;
    while (walker != null && indexOf(walker) < firstIndex) {
      leadingGarbage += 1;
      walker = childAfter(walker);
    }
    return leadingGarbage;
  }

  int _calculateTrailingGarbage(int targetLastIndex) {
    RenderBox? walker = lastChild;
    int trailingGarbage = 0;
    while (walker != null && indexOf(walker) > targetLastIndex) {
      trailingGarbage += 1;
      walker = childBefore(walker);
    }
    return trailingGarbage;
  }

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final double itemExtent = this.itemExtent;

    final double scrollOffset =
        constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;

    // This is the only part that differs from the original implementation.
    // Ignore `itemExtent` and force each child to always fill the viewport.
    final BoxConstraints childConstraints = constraints.asBoxConstraints(
      minExtent: constraints.viewportMainAxisExtent,
      maxExtent: constraints.viewportMainAxisExtent,
    );

    final int firstIndex =
        getMinChildIndexForScrollOffset(scrollOffset, itemExtent);
    final int? targetLastIndex = targetEndScrollOffset.isFinite
        ? getMaxChildIndexForScrollOffset(targetEndScrollOffset, itemExtent)
        : null;

    if (firstChild != null) {
      final int leadingGarbage = _calculateLeadingGarbage(firstIndex);
      final int trailingGarbage = targetLastIndex != null
          ? _calculateTrailingGarbage(targetLastIndex)
          : 0;
      collectGarbage(leadingGarbage, trailingGarbage);
    } else {
      collectGarbage(0, 0);
    }

    if (firstChild == null) {
      if (!addInitialChild(
          index: firstIndex,
          layoutOffset: indexToLayoutOffset(itemExtent, firstIndex))) {
        final double max;
        if (firstIndex <= 0) {
          max = 0.0;
        } else {
          max = computeMaxScrollOffset(constraints, itemExtent);
        }
        geometry = SliverGeometry(
          scrollExtent: max,
          maxPaintExtent: max,
        );
        childManager.didFinishLayout();
        return;
      }
    }

    RenderBox? trailingChildWithLayout;

    for (int index = indexOf(firstChild!) - 1; index >= firstIndex; --index) {
      final RenderBox? child = insertAndLayoutLeadingChild(childConstraints);
      if (child == null) {
        geometry = SliverGeometry(scrollOffsetCorrection: index * itemExtent);
        return;
      }
      final SliverMultiBoxAdaptorParentData childParentData =
          child.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = indexToLayoutOffset(itemExtent, index);
      assert(childParentData.index == index);
      trailingChildWithLayout ??= child;
    }

    if (trailingChildWithLayout == null) {
      firstChild!.layout(childConstraints);
      final SliverMultiBoxAdaptorParentData childParentData =
          firstChild!.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset =
          indexToLayoutOffset(itemExtent, firstIndex);
      trailingChildWithLayout = firstChild;
    }

    double estimatedMaxScrollOffset = double.infinity;
    for (int index = indexOf(trailingChildWithLayout!) + 1;
        targetLastIndex == null || index <= targetLastIndex;
        ++index) {
      RenderBox? child = childAfter(trailingChildWithLayout!);
      if (child == null || indexOf(child) != index) {
        child = insertAndLayoutChild(childConstraints,
            after: trailingChildWithLayout);
        if (child == null) {
          estimatedMaxScrollOffset = index * itemExtent;
          break;
        }
      } else {
        child.layout(childConstraints);
      }
      trailingChildWithLayout = child;
      final SliverMultiBoxAdaptorParentData childParentData =
          child.parentData! as SliverMultiBoxAdaptorParentData;
      assert(childParentData.index == index);
      childParentData.layoutOffset =
          indexToLayoutOffset(itemExtent, childParentData.index!);
    }

    final int lastIndex = indexOf(lastChild!);
    final double leadingScrollOffset =
        indexToLayoutOffset(itemExtent, firstIndex);
    final double trailingScrollOffset =
        indexToLayoutOffset(itemExtent, lastIndex + 1);

    assert(firstIndex == 0 ||
        childScrollOffset(firstChild!)! - scrollOffset <=
            precisionErrorTolerance);
    assert(debugAssertChildListIsNonEmptyAndContiguous());
    assert(indexOf(firstChild!) == firstIndex);
    assert(targetLastIndex == null || lastIndex <= targetLastIndex);

    estimatedMaxScrollOffset = min(
      estimatedMaxScrollOffset,
      estimateMaxScrollOffset(
        constraints,
        firstIndex: firstIndex,
        lastIndex: lastIndex,
        leadingScrollOffset: leadingScrollOffset,
        trailingScrollOffset: trailingScrollOffset,
      ),
    );

    final double paintExtent = calculatePaintOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    final double targetEndScrollOffsetForPaint =
        constraints.scrollOffset + constraints.remainingPaintExtent;
    final int? targetLastIndexForPaint = targetEndScrollOffsetForPaint.isFinite
        ? getMaxChildIndexForScrollOffset(
            targetEndScrollOffsetForPaint, itemExtent)
        : null;
    geometry = SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      hasVisualOverflow: (targetLastIndexForPaint != null &&
              lastIndex >= targetLastIndexForPaint) ||
          constraints.scrollOffset > 0.0,
    );

    if (estimatedMaxScrollOffset == trailingScrollOffset) {
      childManager.setDidUnderflow(true);
    }
    childManager.didFinishLayout();
  }
}

// This class was copied from:
// - https://github.com/flutter/flutter/tree/master/packages/flutter/lib/src/widgets/sliver_fill.dart
class _SliverFillViewportRenderObjectWidget
    extends SliverMultiBoxAdaptorWidget {
  const _SliverFillViewportRenderObjectWidget({
    required super.delegate,
    this.viewportFraction = 1.0,
  }) : assert(viewportFraction > 0.0);

  final double viewportFraction;

  @override
  RenderSliverFillViewport createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element =
        context as SliverMultiBoxAdaptorElement;
    return _RenderSliverFillViewport(
        childManager: element, viewportFraction: viewportFraction);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSliverFillViewport renderObject) {
    renderObject.viewportFraction = viewportFraction;
  }
}

class _SliverFillViewport extends SliverFillViewport {
  const _SliverFillViewport({
    required super.delegate,
    super.padEnds,
    super.viewportFraction,
  });

  @override
  Widget build(BuildContext context) {
    return _SliverFractionalPadding(
      viewportFraction:
          padEnds ? clampDouble(1 - viewportFraction, 0, 1) / 2 : 0,
      sliver: _SliverFillViewportRenderObjectWidget(
        delegate: delegate,
        viewportFraction: viewportFraction,
      ),
    );
  }
}

class _SliverFractionalPadding extends SingleChildRenderObjectWidget {
  const _SliverFractionalPadding({
    this.viewportFraction = 0,
    Widget? sliver,
  })  : assert(viewportFraction >= 0),
        assert(viewportFraction <= 0.5),
        super(child: sliver);

  final double viewportFraction;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSliverFractionalPadding(viewportFraction: viewportFraction);

  @override
  void updateRenderObject(
      BuildContext context, _RenderSliverFractionalPadding renderObject) {
    renderObject.viewportFraction = viewportFraction;
  }
}

// This class was copied from:
// - https://github.com/flutter/flutter/tree/master/packages/flutter/lib/src/widgets/sliver_fill.dart
class _RenderSliverFractionalPadding extends RenderSliverEdgeInsetsPadding {
  _RenderSliverFractionalPadding({
    double viewportFraction = 0,
  })  : assert(viewportFraction <= 0.5),
        assert(viewportFraction >= 0),
        _viewportFraction = viewportFraction;

  SliverConstraints? _lastResolvedConstraints;

  double get viewportFraction => _viewportFraction;
  double _viewportFraction;
  set viewportFraction(double newValue) {
    if (_viewportFraction == newValue) {
      return;
    }
    _viewportFraction = newValue;
    _markNeedsResolution();
  }

  @override
  EdgeInsets? get resolvedPadding => _resolvedPadding;
  EdgeInsets? _resolvedPadding;

  void _markNeedsResolution() {
    _resolvedPadding = null;
    markNeedsLayout();
  }

  void _resolve() {
    if (_resolvedPadding != null && _lastResolvedConstraints == constraints) {
      return;
    }
    final double paddingValue =
        constraints.viewportMainAxisExtent * viewportFraction;
    _lastResolvedConstraints = constraints;
    switch (constraints.axis) {
      case Axis.horizontal:
        _resolvedPadding = EdgeInsets.symmetric(horizontal: paddingValue);
        break;
      case Axis.vertical:
        _resolvedPadding = EdgeInsets.symmetric(vertical: paddingValue);
        break;
    }

    return;
  }

  @override
  void performLayout() {
    _resolve();
    super.performLayout();
  }
}

/// A page view that forces the pages to occupy the viewport
/// regardless of [PageController.viewportFraction].
class AlwaysFillViewportPageView extends PageView {
  AlwaysFillViewportPageView.builder({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.physics,
    super.pageSnapping,
    super.onPageChanged,
    required super.itemBuilder,
    super.findChildIndexCallback,
    super.itemCount,
    super.dragStartBehavior,
    super.allowImplicitScrolling,
    super.restorationId,
    super.clipBehavior,
    super.scrollBehavior,
    super.padEnds,
  }) : super.builder();

  @override
  State<PageView> createState() => _PageViewState();
}

const PageScrollPhysics _kPagePhysics = PageScrollPhysics();

/// This class was copied and modified from:
/// - https://github.com/flutter/flutter/tree/master/packages/flutter/lib/src/widgets/page_view.dart
class _PageViewState extends State<PageView> {
  int _lastReportedPage = 0;

  @override
  void initState() {
    super.initState();
    _lastReportedPage = widget.controller.initialPage;
  }

  AxisDirection _getDirection(BuildContext context) {
    switch (widget.scrollDirection) {
      case Axis.horizontal:
        assert(debugCheckHasDirectionality(context));
        final TextDirection textDirection = Directionality.of(context);
        final AxisDirection axisDirection =
            textDirectionToAxisDirection(textDirection);
        return widget.reverse
            ? flipAxisDirection(axisDirection)
            : axisDirection;
      case Axis.vertical:
        return widget.reverse ? AxisDirection.up : AxisDirection.down;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AxisDirection axisDirection = _getDirection(context);
    final ScrollPhysics physics = _ForceImplicitScrollPhysics(
      allowImplicitScrolling: widget.allowImplicitScrolling,
    ).applyTo(
      widget.pageSnapping
          ? _kPagePhysics.applyTo(widget.physics ??
              widget.scrollBehavior?.getScrollPhysics(context))
          : widget.physics ?? widget.scrollBehavior?.getScrollPhysics(context),
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.depth == 0 &&
            widget.onPageChanged != null &&
            notification is ScrollUpdateNotification) {
          final PageMetrics metrics = notification.metrics as PageMetrics;
          final int currentPage = metrics.page!.round();
          if (currentPage != _lastReportedPage) {
            _lastReportedPage = currentPage;
            widget.onPageChanged!(currentPage);
          }
        }
        return false;
      },
      child: Scrollable(
        dragStartBehavior: widget.dragStartBehavior,
        axisDirection: axisDirection,
        controller: widget.controller,
        physics: physics,
        restorationId: widget.restorationId,
        scrollBehavior: widget.scrollBehavior ??
            ScrollConfiguration.of(context).copyWith(scrollbars: false),
        viewportBuilder: (BuildContext context, ViewportOffset position) {
          return Viewport(
            cacheExtent: widget.allowImplicitScrolling ? 1.0 : 0.0,
            cacheExtentStyle: CacheExtentStyle.viewport,
            axisDirection: axisDirection,
            offset: position,
            clipBehavior: widget.clipBehavior,
            slivers: <Widget>[
              _SliverFillViewport(
                viewportFraction: widget.controller.viewportFraction,
                delegate: widget.childrenDelegate,
                padEnds: widget.padEnds,
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description
        .add(EnumProperty<Axis>('scrollDirection', widget.scrollDirection));
    description.add(
        FlagProperty('reverse', value: widget.reverse, ifTrue: 'reversed'));
    description.add(DiagnosticsProperty<PageController>(
        'controller', widget.controller,
        showName: false));
    description.add(DiagnosticsProperty<ScrollPhysics>(
        'physics', widget.physics,
        showName: false));
    description.add(FlagProperty('pageSnapping',
        value: widget.pageSnapping, ifFalse: 'snapping disabled'));
    description.add(FlagProperty('allowImplicitScrolling',
        value: widget.allowImplicitScrolling,
        ifTrue: 'allow implicit scrolling'));
  }
}

/// This class was copied from:
/// - https://github.com/flutter/flutter/tree/master/packages/flutter/lib/src/widgets/page_view.dart
class _ForceImplicitScrollPhysics extends ScrollPhysics {
  const _ForceImplicitScrollPhysics({
    required this.allowImplicitScrolling,
    super.parent,
  });

  @override
  _ForceImplicitScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ForceImplicitScrollPhysics(
      allowImplicitScrolling: allowImplicitScrolling,
      parent: buildParent(ancestor),
    );
  }

  @override
  final bool allowImplicitScrolling;
}
