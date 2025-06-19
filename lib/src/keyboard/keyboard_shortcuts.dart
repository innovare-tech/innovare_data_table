import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DataTableShortcuts {
  static Map<ShortcutActivator, Intent> shortcuts = {
    // Navigation
    SingleActivator(LogicalKeyboardKey.arrowUp): NavigateUpIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown): NavigateDownIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft): NavigateLeftIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight): NavigateRightIntent(),

    // Selection
    SingleActivator(LogicalKeyboardKey.space): SelectItemIntent(),
    SingleActivator(LogicalKeyboardKey.enter): ActivateItemIntent(),
    SingleActivator(LogicalKeyboardKey.keyA, control: true): SelectAllIntent(),
    SingleActivator(LogicalKeyboardKey.escape): ClearSelectionIntent(),

    // Pagination
    SingleActivator(LogicalKeyboardKey.pageUp): PreviousPageIntent(),
    SingleActivator(LogicalKeyboardKey.pageDown): NextPageIntent(),
    SingleActivator(LogicalKeyboardKey.home, control: true): FirstPageIntent(),
    SingleActivator(LogicalKeyboardKey.end, control: true): LastPageIntent(),

    // Sorting and Filtering
    SingleActivator(LogicalKeyboardKey.keyS, control: true): SortColumnIntent(),
    SingleActivator(LogicalKeyboardKey.keyF, control: true): FilterColumnIntent(),
    SingleActivator(LogicalKeyboardKey.keyR, control: true): RefreshDataIntent(),

    // Quick actions
    SingleActivator(LogicalKeyboardKey.delete): DeleteSelectedIntent(),
    SingleActivator(LogicalKeyboardKey.keyE, control: true): EditSelectedIntent(),
    SingleActivator(LogicalKeyboardKey.keyC, control: true): CopySelectedIntent(),

    // View
    SingleActivator(LogicalKeyboardKey.keyM, control: true): ToggleColumnManagerIntent(),
    SingleActivator(LogicalKeyboardKey.keyD, control: true): ToggleDensityIntent(),

    // Help
    SingleActivator(LogicalKeyboardKey.f1): ShowHelpIntent(),
  };

  static Map<Type, Action<Intent>> createActions({
    required VoidCallback? onNavigateUp,
    required VoidCallback? onNavigateDown,
    required VoidCallback? onNavigateLeft,
    required VoidCallback? onNavigateRight,
    required VoidCallback? onSelectItem,
    required VoidCallback? onActivateItem,
    required VoidCallback? onSelectAll,
    required VoidCallback? onClearSelection,
    required VoidCallback? onPreviousPage,
    required VoidCallback? onNextPage,
    required VoidCallback? onFirstPage,
    required VoidCallback? onLastPage,
    required VoidCallback? onSortColumn,
    required VoidCallback? onFilterColumn,
    required VoidCallback? onRefreshData,
    required VoidCallback? onDeleteSelected,
    required VoidCallback? onEditSelected,
    required VoidCallback? onCopySelected,
    required VoidCallback? onToggleColumnManager,
    required VoidCallback? onToggleDensity,
    required VoidCallback? onShowHelp,
  }) {
    return {
      NavigateUpIntent: CallbackAction<NavigateUpIntent>(
        onInvoke: (_) => onNavigateUp?.call(),
      ),
      NavigateDownIntent: CallbackAction<NavigateDownIntent>(
        onInvoke: (_) => onNavigateDown?.call(),
      ),
      NavigateLeftIntent: CallbackAction<NavigateLeftIntent>(
        onInvoke: (_) => onNavigateLeft?.call(),
      ),
      NavigateRightIntent: CallbackAction<NavigateRightIntent>(
        onInvoke: (_) => onNavigateRight?.call(),
      ),
      SelectItemIntent: CallbackAction<SelectItemIntent>(
        onInvoke: (_) => onSelectItem?.call(),
      ),
      ActivateItemIntent: CallbackAction<ActivateItemIntent>(
        onInvoke: (_) => onActivateItem?.call(),
      ),
      SelectAllIntent: CallbackAction<SelectAllIntent>(
        onInvoke: (_) => onSelectAll?.call(),
      ),
      ClearSelectionIntent: CallbackAction<ClearSelectionIntent>(
        onInvoke: (_) => onClearSelection?.call(),
      ),
      PreviousPageIntent: CallbackAction<PreviousPageIntent>(
        onInvoke: (_) => onPreviousPage?.call(),
      ),
      NextPageIntent: CallbackAction<NextPageIntent>(
        onInvoke: (_) => onNextPage?.call(),
      ),
      FirstPageIntent: CallbackAction<FirstPageIntent>(
        onInvoke: (_) => onFirstPage?.call(),
      ),
      LastPageIntent: CallbackAction<LastPageIntent>(
        onInvoke: (_) => onLastPage?.call(),
      ),
      SortColumnIntent: CallbackAction<SortColumnIntent>(
        onInvoke: (_) => onSortColumn?.call(),
      ),
      FilterColumnIntent: CallbackAction<FilterColumnIntent>(
        onInvoke: (_) => onFilterColumn?.call(),
      ),
      RefreshDataIntent: CallbackAction<RefreshDataIntent>(
        onInvoke: (_) => onRefreshData?.call(),
      ),
      DeleteSelectedIntent: CallbackAction<DeleteSelectedIntent>(
        onInvoke: (_) => onDeleteSelected?.call(),
      ),
      EditSelectedIntent: CallbackAction<EditSelectedIntent>(
        onInvoke: (_) => onEditSelected?.call(),
      ),
      CopySelectedIntent: CallbackAction<CopySelectedIntent>(
        onInvoke: (_) => onCopySelected?.call(),
      ),
      ToggleColumnManagerIntent: CallbackAction<ToggleColumnManagerIntent>(
        onInvoke: (_) => onToggleColumnManager?.call(),
      ),
      ToggleDensityIntent: CallbackAction<ToggleDensityIntent>(
        onInvoke: (_) => onToggleDensity?.call(),
      ),
      ShowHelpIntent: CallbackAction<ShowHelpIntent>(
        onInvoke: (_) => onShowHelp?.call(),
      ),
    };
  }
}

// Intent classes
class NavigateUpIntent extends Intent {}
class NavigateDownIntent extends Intent {}
class NavigateLeftIntent extends Intent {}
class NavigateRightIntent extends Intent {}
class SelectItemIntent extends Intent {}
class ActivateItemIntent extends Intent {}
class SelectAllIntent extends Intent {}
class ClearSelectionIntent extends Intent {}
class PreviousPageIntent extends Intent {}
class NextPageIntent extends Intent {}
class FirstPageIntent extends Intent {}
class LastPageIntent extends Intent {}
class SortColumnIntent extends Intent {}
class FilterColumnIntent extends Intent {}
class RefreshDataIntent extends Intent {}
class DeleteSelectedIntent extends Intent {}
class EditSelectedIntent extends Intent {}
class CopySelectedIntent extends Intent {}
class ToggleColumnManagerIntent extends Intent {}
class ToggleDensityIntent extends Intent {}
class ShowHelpIntent extends Intent {}