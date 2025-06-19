import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:innovare_data_table/src/data_table_theme.dart';

class PullToRefreshWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function()? onRefresh;
  final String refreshText;
  final String releaseText;
  final String loadingText;
  final DataTableColorScheme colors;

  const PullToRefreshWrapper({
    super.key,
    required this.child,
    this.onRefresh,
    this.refreshText = 'Puxe para atualizar',
    this.releaseText = 'Solte para atualizar',
    this.loadingText = 'Atualizando...',
    required this.colors,
  });

  @override
  State<PullToRefreshWrapper> createState() => _PullToRefreshWrapperState();
}

class _PullToRefreshWrapperState extends State<PullToRefreshWrapper>
    with TickerProviderStateMixin {
  late AnimationController _indicatorController;
  late Animation<double> _indicatorOpacity;
  late Animation<double> _iconRotation;

  bool _isRefreshing = false;
  bool _canRefresh = false;
  double _pullDistance = 0;
  final double _triggerDistance = 80;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _indicatorOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _indicatorController, curve: Curves.easeOut),
    );

    _iconRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _indicatorController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (widget.onRefresh == null || _isRefreshing) return false;

    if (notification is ScrollUpdateNotification) {
      final scrollPosition = notification.metrics.pixels;

      if (scrollPosition < 0) {
        setState(() {
          _pullDistance = -scrollPosition;
          _canRefresh = _pullDistance >= _triggerDistance;
        });

        if (_pullDistance > 10) {
          _indicatorController.forward();
        } else {
          _indicatorController.reverse();
        }
      }
    }

    if (notification is ScrollEndNotification && _canRefresh && !_isRefreshing) {
      _triggerRefresh();
    }

    return false;
  }

  Future<void> _triggerRefresh() async {
    if (widget.onRefresh == null) return;

    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.mediumImpact();

    try {
      await widget.onRefresh!();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _canRefresh = false;
          _pullDistance = 0;
        });
        _indicatorController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Stack(
        children: [
          widget.child,

          // Pull indicator
          AnimatedBuilder(
            animation: _indicatorController,
            builder: (context, child) {
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _indicatorOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, -60 + (_pullDistance * 0.5)),
                    child: _buildRefreshIndicator(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshIndicator() {
    return Container(
      height: 60,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: widget.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.colors.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRefreshing)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(widget.colors.primary),
                ),
              )
            else
              AnimatedBuilder(
                animation: _iconRotation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _iconRotation.value * 3.14159, // 180 degrees
                    child: Icon(
                      _canRefresh ? Icons.arrow_upward : Icons.arrow_downward,
                      color: widget.colors.primary,
                      size: 16,
                    ),
                  );
                },
              ),

            const SizedBox(width: 8),

            Text(
              _isRefreshing
                  ? widget.loadingText
                  : _canRefresh
                  ? widget.releaseText
                  : widget.refreshText,
              style: TextStyle(
                color: widget.colors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
