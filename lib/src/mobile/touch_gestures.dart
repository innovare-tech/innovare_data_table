import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:innovare_data_table/src/data_table_theme.dart';

enum SwipeAction { edit, delete, share, archive, favorite }

class SwipeActionConfig {
  final SwipeAction action;
  final String label;
  final IconData icon;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;

  const SwipeActionConfig({
    required this.action,
    required this.label,
    required this.icon,
    required this.color,
    this.textColor,
    required this.onTap,
  });

  factory SwipeActionConfig.edit(VoidCallback onTap) {
    return SwipeActionConfig(
      action: SwipeAction.edit,
      label: 'Editar',
      icon: Icons.edit,
      color: Colors.blue,
      textColor: Colors.white,
      onTap: onTap,
    );
  }

  factory SwipeActionConfig.delete(VoidCallback onTap) {
    return SwipeActionConfig(
      action: SwipeAction.delete,
      label: 'Excluir',
      icon: Icons.delete,
      color: Colors.red,
      textColor: Colors.white,
      onTap: onTap,
    );
  }

  factory SwipeActionConfig.archive(VoidCallback onTap) {
    return SwipeActionConfig(
      action: SwipeAction.archive,
      label: 'Arquivar',
      icon: Icons.archive,
      color: Colors.orange,
      textColor: Colors.white,
      onTap: onTap,
    );
  }

  factory SwipeActionConfig.share(VoidCallback onTap) {
    return SwipeActionConfig(
      action: SwipeAction.share,
      label: 'Compartilhar',
      icon: Icons.share,
      color: Colors.green,
      textColor: Colors.white,
      onTap: onTap,
    );
  }
}

class TouchGesturesConfig<T> {
  final bool enableSwipeActions;
  final bool enablePullToRefresh;
  final bool enableLongPressSelection;
  final bool enablePinchToZoom;
  final List<SwipeActionConfig> Function(T item)? leftSwipeActions;
  final List<SwipeActionConfig> Function(T item)? rightSwipeActions;
  final Future<void> Function()? onRefresh;
  final Function(T item)? onLongPress;
  final Function(double scale)? onPinchZoom;
  final Duration swipeAnimationDuration;
  final double swipeThreshold;

  const TouchGesturesConfig({
    this.enableSwipeActions = true,
    this.enablePullToRefresh = true,
    this.enableLongPressSelection = true,
    this.enablePinchToZoom = false,
    this.leftSwipeActions,
    this.rightSwipeActions,
    this.onRefresh,
    this.onLongPress,
    this.onPinchZoom,
    this.swipeAnimationDuration = const Duration(milliseconds: 300),
    this.swipeThreshold = 0.3,
  });
}

class SwipeableCard<T> extends StatefulWidget {
  final T item;
  final Widget child;
  final List<SwipeActionConfig> leftActions;
  final List<SwipeActionConfig> rightActions;
  final TouchGesturesConfig<T> config;
  final DataTableColorScheme colors;

  const SwipeableCard({
    super.key,
    required this.item,
    required this.child,
    this.leftActions = const [],
    this.rightActions = const [],
    required this.config,
    required this.colors,
  });

  @override
  State<SwipeableCard<T>> createState() => _SwipeableCardState<T>();
}

class _SwipeableCardState<T> extends State<SwipeableCard<T>>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _actionController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _actionOpacity;

  double _dragExtent = 0;
  bool _isDragging = false;
  bool _actionsRevealed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: widget.config.swipeAnimationDuration,
      vsync: this,
    );

    _actionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _actionOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _actionController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    if (!widget.config.enableSwipeActions) return;

    setState(() {
      _isDragging = true;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final delta = details.primaryDelta ?? 0;
    setState(() {
      _dragExtent += delta;
      _dragExtent = _dragExtent.clamp(-200.0, 200.0);
    });

    // Animate actions based on drag
    final progress = (_dragExtent.abs() / 200.0).clamp(0.0, 1.0);
    _actionController.value = progress;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    setState(() {
      _isDragging = false;
    });

    final threshold = 200.0 * widget.config.swipeThreshold;

    if (_dragExtent.abs() > threshold) {
      // Reveal actions
      _revealActions();
    } else {
      // Snap back
      _snapBack();
    }
  }

  void _revealActions() {
    setState(() {
      _actionsRevealed = true;
    });

    _slideController.forward();
    _actionController.forward();
    HapticFeedback.mediumImpact();
  }

  void _snapBack() {
    setState(() {
      _actionsRevealed = false;
      _dragExtent = 0;
    });

    _slideController.reverse();
    _actionController.reverse();
  }

  void _executeAction(SwipeActionConfig action) {
    _snapBack();

    // Delay para permitir animação
    Future.delayed(widget.config.swipeAnimationDuration, () {
      action.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final actions = _dragExtent > 0 ? widget.leftActions : widget.rightActions;

    return GestureDetector(
      onPanStart: _handleDragStart,
      onPanUpdate: _handleDragUpdate,
      onPanEnd: _handleDragEnd,
      onTap: () {
        if (_actionsRevealed) {
          _snapBack();
        }
      },
      child: Stack(
        children: [
          // Background actions
          if (actions.isNotEmpty)
            _buildActionsBackground(actions),

          // Main card
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_dragExtent, 0),
                child: widget.child,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionsBackground(List<SwipeActionConfig> actions) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _actionOpacity,
        builder: (context, child) {
          return Opacity(
            opacity: _actionOpacity.value,
            child: Row(
              mainAxisAlignment: _dragExtent > 0
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              children: actions.map((action) => _buildActionButton(action)).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(SwipeActionConfig action) {
    return GestureDetector(
      onTap: () => _executeAction(action),
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: action.color,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              action.icon,
              color: action.textColor ?? Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              action.label,
              style: TextStyle(
                color: action.textColor ?? Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class LongPressSelectionWrapper<T> extends StatefulWidget {
  final T item;
  final Widget child;
  final bool isSelected;
  final Function(T item) onSelectionToggle;
  final Function(T item)? onLongPress;
  final TouchGesturesConfig<T> config;
  final DataTableColorScheme colors;

  const LongPressSelectionWrapper({
    super.key,
    required this.item,
    required this.child,
    required this.isSelected,
    required this.onSelectionToggle,
    this.onLongPress,
    required this.config,
    required this.colors,
  });

  @override
  State<LongPressSelectionWrapper<T>> createState() => _LongPressSelectionWrapperState<T>();
}

class _LongPressSelectionWrapperState<T> extends State<LongPressSelectionWrapper<T>>
    with TickerProviderStateMixin {
  late AnimationController _selectionController;
  late Animation<double> _selectionScale;
  late Animation<double> _checkmarkOpacity;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _selectionScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _selectionController, curve: Curves.easeOut),
    );

    _checkmarkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _selectionController, curve: Curves.easeOut),
    );

    if (widget.isSelected) {
      _selectionController.forward();
    }
  }

  @override
  void didUpdateWidget(LongPressSelectionWrapper<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _selectionController.forward();
      } else {
        _selectionController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }

  void _handleLongPress() {
    if (!widget.config.enableLongPressSelection) return;

    HapticFeedback.heavyImpact();
    widget.onSelectionToggle(widget.item);
    widget.onLongPress?.call(widget.item);
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _handleLongPress,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _selectionController,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? 0.98 : _selectionScale.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: widget.isSelected
                    ? Border.all(
                  color: widget.colors.primary,
                  width: 2,
                )
                    : null,
              ),
              child: Stack(
                children: [
                  widget.child,

                  // Selection overlay
                  if (widget.isSelected)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                  // Checkmark
                  if (widget.isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: AnimatedBuilder(
                        animation: _checkmarkOpacity,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _checkmarkOpacity.value,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: widget.colors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PinchToZoomWrapper extends StatefulWidget {
  final Widget child;
  final Function(double scale)? onScaleChanged;
  final double minScale;
  final double maxScale;
  final bool enabled;

  const PinchToZoomWrapper({
    super.key,
    required this.child,
    this.onScaleChanged,
    this.minScale = 0.8,
    this.maxScale = 1.5,
    this.enabled = true,
  });

  @override
  State<PinchToZoomWrapper> createState() => _PinchToZoomWrapperState();
}

class _PinchToZoomWrapperState extends State<PinchToZoomWrapper>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  double _currentScale = 1.0;
  double _baseScale = 1.0;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (!widget.enabled) return;
    _baseScale = _currentScale;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!widget.enabled) return;

    setState(() {
      _currentScale = (_baseScale * details.scale).clamp(widget.minScale, widget.maxScale);
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (!widget.enabled) return;

    widget.onScaleChanged?.call(_currentScale);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      child: Transform.scale(
        scale: _currentScale,
        child: widget.child,
      ),
    );
  }
}
