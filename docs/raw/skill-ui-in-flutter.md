> Builds Flutter UI from a FigCraft design: tokens from variable.export dart wrapped in a ThemeExtension, Material or Cupertino only as a themed base, Semantics, dynamic type, safe areas, 48 dp targets, golden or integration screenshots compared with exported frames, and Flutter accessibility guideline tests. Load it from Skill — Build UI from a Design when the repository has a Flutter pubspec.yaml.

# UI in Flutter

Companion to [Skill — Build UI from a Design](skill-build-ui-from-a-design.md)). The core rules there still apply.

## Does this apply?

`pubspec.yaml` lists `flutter` under `dependencies` (`flutter: sdk: flutter`), with code in `lib/`. Check `lib/` for an existing theme folder, routing and state management first.

## Tokens
1. Export: `run_command {"command": "variable.export", "params": {"format": "dart", "path": "/tmp/design/<file-id>/tokens.dart"}}`. It writes `import 'dart:ui';` and one `abstract final class` of `static const Color ...` per collection and mode (for example `Fumika` for the default mode).
2. Save it as the generated tokens file (for example `lib/theme/tokens.dart`) and regenerate it from the design when tokens change.
3. Wrap it in a ThemeExtension:

```dart
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.bg, required this.accent, required this.danger});
  final Color bg, accent, danger;
  static const light = AppColors(bg: Fumika.colorBg, accent: Fumika.colorAccent, danger: Fumika.colorDanger);
  @override
  AppColors copyWith({Color? bg, Color? accent, Color? danger}) =>
      AppColors(bg: bg ?? this.bg, accent: accent ?? this.accent, danger: danger ?? this.danger);
  @override
  AppColors lerp(AppColors? other, double t) => other == null ? this : AppColors(
      bg: Color.lerp(bg, other.bg, t)!, accent: Color.lerp(accent, other.accent, t)!, danger: Color.lerp(danger, other.danger, t)!);
}
```

Add a `dark` instance from the dark-mode class, and register both: `ThemeData(extensions: const [AppColors.light])` for `theme`, the dark one for `darkTheme`.
1. Widgets read `Theme.of(context).extension<AppColors>()!`. No `Color(0xFF...)` in widgets.

## Base theme
- Material or Cupertino is only a base. Set `ColorScheme`, `TextTheme` and component themes (`FilledButtonThemeData`, `InputDecorationTheme`, `CardThemeData`) from the tokens so stock widgets match the design. Never `ColorScheme.fromSeed` with a default seed colour, and no stock purple or blue.
- Fonts as `pubspec.yaml` font assets, or the font package the project already uses; only the weights the design uses.
- `inspect.code` with `flutter` gives `Text` and `TextStyle` values with raw colours; use the numbers, replace colours with tokens.

## Widgets and platform rules
- Small stateless widgets per design element (`AppButton`, `StatusBadge`, `StoppedBanner`) with enums for variants.
- Safe areas: `SafeArea`, or `MediaQuery.paddingOf(context)` for custom layouts; primary actions in the thumb zone as the mobile frame shows.
- Dynamic type: respect `MediaQuery.textScalerOf(context)`; no fixed heights around text; check scale 2.0.
- Semantics: `Semantics(label: ..., button: true)` on custom tappables, `ExcludeSemantics` on decoration, `MergeSemantics` for composite rows, `Tooltip` for icon-only buttons.
- Targets: at least 48x48 dp; keep `MaterialTapTargetSize.padded`.
- Motion: skip or shorten animations when `MediaQuery.disableAnimationsOf(context)` is true.
- Status never by colour alone: icon plus text.

## Visual QA
- Golden tests at the frame size:

```dart
testWidgets('endpoints stopped, light', (tester) async {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const App(initialState: DemoState.stopped));
  await tester.pumpAndSettle();
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/endpoints_stopped_light.png'));
});
```

Create with `flutter test --update-goldens`, then compare each golden side by side with the exported frame PNG and fix differences. Load the real fonts in test setup (for example a `FontLoader` in `flutter_test_config.dart`), or goldens use the test font. Commit goldens only if the project already keeps them.
- On a device: `integration_test` with `IntegrationTestWidgetsFlutterBinding` and `binding.takeScreenshot('endpoints_stopped')`.
- Quick look: `flutter run -d web-server --web-port 8080` and a Playwright screenshot. Use it only for visuals; axe cannot read Flutter's canvas.

## Accessibility checks
- Guideline tests in widget tests:

```dart
final handle = tester.ensureSemantics();
await expectLater(tester, meetsGuideline(textContrastGuideline));
await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
handle.dispose();
```
- Text scaling: pump with `MediaQuery(data: MediaQueryData(textScaler: const TextScaler.linear(2.0)), child: ...)` and check for overflow errors.
- During development: `MaterialApp(showSemanticsDebugger: true)`; on devices, TalkBack and VoiceOver walk-throughs of the main flow.
- `flutter analyze` and the project's tests pass.
