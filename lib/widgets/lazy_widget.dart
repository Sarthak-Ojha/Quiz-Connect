// lib/widgets/lazy_widget.dart

import 'package:flutter/material.dart';

/// Lazy loading widget that only builds when visible
class LazyWidget extends StatefulWidget {
  final Widget Function() builder;
  final Widget? placeholder;
  final double threshold;

  const LazyWidget({
    super.key,
    required this.builder,
    this.placeholder,
    this.threshold = 100.0,
  });

  @override
  State<LazyWidget> createState() => _LazyWidgetState();
}

class _LazyWidgetState extends State<LazyWidget> {
  bool _isVisible = false;
  Widget? _cachedWidget;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: widget.key ?? UniqueKey(),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0 && !_isVisible) {
          setState(() {
            _isVisible = true;
            _cachedWidget = widget.builder();
          });
        }
      },
      child: _isVisible
          ? _cachedWidget!
          : widget.placeholder ?? const SizedBox.shrink(),
    );
  }
}

/// Simple visibility detector for lazy loading
class VisibilityDetector extends StatefulWidget {
  @override
  final Key key;
  final Widget child;
  final Function(VisibilityInfo) onVisibilityChanged;

  const VisibilityDetector({
    required this.key,
    required this.child,
    required this.onVisibilityChanged,
  }) : super(key: key);

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final size = renderBox.size;
      final position = renderBox.localToGlobal(Offset.zero);
      final screenSize = MediaQuery.of(context).size;

      // Simple visibility check
      final isVisible =
          position.dy < screenSize.height && position.dy + size.height > 0;

      if (isVisible) {
        widget.onVisibilityChanged(VisibilityInfo(visibleFraction: 1.0));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class VisibilityInfo {
  final double visibleFraction;

  const VisibilityInfo({required this.visibleFraction});
}

/// Optimized list item with automatic keep alive
class OptimizedListItem extends StatefulWidget {
  final Widget child;
  final bool keepAlive;

  const OptimizedListItem({
    super.key,
    required this.child,
    this.keepAlive = false,
  });

  @override
  State<OptimizedListItem> createState() => _OptimizedListItemState();
}

class _OptimizedListItemState extends State<OptimizedListItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(child: widget.child);
  }
}
