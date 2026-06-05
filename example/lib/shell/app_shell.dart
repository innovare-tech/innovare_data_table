import 'package:flutter/material.dart';
import 'package:innovare_design/innovare_design.dart';

/// Inherited holder that lets every showcase page (a) read the
/// currently selected [InnvPreset] / [Brightness] and (b) ask the shell
/// to flip them. The shell wraps the entire `MaterialApp` so a single
/// `setState` rebuilds everything — including the `InnovareDataTable`
/// theme adapter that we shipped in Wave 1.
class AppShellScope extends InheritedWidget {
  final InnvPreset preset;
  final Brightness brightness;
  final ValueChanged<InnvPreset> onPresetChanged;
  final ValueChanged<Brightness> onBrightnessChanged;

  const AppShellScope({
    super.key,
    required this.preset,
    required this.brightness,
    required this.onPresetChanged,
    required this.onBrightnessChanged,
    required super.child,
  });

  static AppShellScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppShellScope>();
    assert(scope != null, 'AppShellScope is missing above this widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppShellScope old) =>
      old.preset != preset || old.brightness != brightness;
}

class AppShell extends StatefulWidget {
  final Widget Function(BuildContext) builder;
  const AppShell({super.key, required this.builder});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  InnvPreset _preset = InnvPreset.aurora;
  Brightness _brightness = Brightness.light;

  @override
  Widget build(BuildContext context) {
    final designTheme = InnvPresets.resolve(_preset, _brightness);
    return AppShellScope(
      preset: _preset,
      brightness: _brightness,
      onPresetChanged: (p) => setState(() => _preset = p),
      onBrightnessChanged: (b) => setState(() => _brightness = b),
      child: MaterialApp(
        title: 'innovare_data_table — showcase',
        debugShowCheckedModeBanner: false,
        theme: designTheme.toThemeData(),
        builder: (context, child) => child ?? const SizedBox.shrink(),
        home: Builder(builder: widget.builder),
      ),
    );
  }
}

/// Top bar widget used by every showcase page. Lives outside the
/// `Scaffold` of the page so each page can compose its own body, but
/// shares the preset+brightness controls in one place.
class ShellHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget> trailing;

  const ShellHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final scope = AppShellScope.of(context);
    final theme = Theme.of(context);
    return AppBar(
      toolbarHeight: 72,
      titleSpacing: 16,
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          ...trailing,
          const SizedBox(width: 12),
          _PresetSelector(scope: scope),
          const SizedBox(width: 12),
          IconButton(
            tooltip: scope.brightness == Brightness.light
                ? 'Switch to dark'
                : 'Switch to light',
            icon: Icon(
              scope.brightness == Brightness.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            onPressed: () => scope.onBrightnessChanged(
              scope.brightness == Brightness.light
                  ? Brightness.dark
                  : Brightness.light,
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetSelector extends StatelessWidget {
  final AppShellScope scope;
  const _PresetSelector({required this.scope});

  static const _labels = {
    InnvPreset.aurora: 'Aurora',
    InnvPreset.vibe: 'Vibe',
    InnvPreset.slate: 'Slate',
    InnvPreset.lumen: 'Lumen',
  };

  @override
  Widget build(BuildContext context) {
    return DropdownButton<InnvPreset>(
      value: scope.preset,
      underline: const SizedBox.shrink(),
      onChanged: (p) => p == null ? null : scope.onPresetChanged(p),
      items: [
        for (final entry in _labels.entries)
          DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value),
          ),
      ],
    );
  }
}
