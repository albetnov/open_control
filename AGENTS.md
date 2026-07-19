# Agents

## Project Context

- **@PRODUCT.md** — Strategic direction: users, brand personality, anti-references, design principles. Read before any design or feature work.
- **@DESIGN.md** — Visual system: color palette, typography, elevation, components, do's and don'ts. Read before any UI work.
- **@ARCH.md** — Architecture: folder structure, phases, import rules, decision tree. Read before any structural or data-layer work.
- **Skills** — Skills live in `.agents/skills/` and are auto-discovered. This includes the flutter_it / `*-it` ecosystem skills (watch_it, get_it, listen_it, flutter_it, etc.), the design skill (`impeccable`: `craft`, `shape`, `document`, `polish`, `bolder`, …), the validasi ecosystem skills (validasi_ui, validasi, etc), and official Dart/Flutter skills (unit test, build CLI, coverage, mock testing, migrate to `checks` package, etc.). Load skills only when you need them — they are slow to load and distracting. Always load the design skill before design tasks.

## Rules

### Tooling & workflow

- **DO use Dart MCP** for all project interaction. It provides a unified interface for running commands, hot-reloading, and debugging. Avoid raw `flutter`/`dart` commands unless necessary. Hot-*restart* when adding/changing routes or app-wide lifecycle; use `hot_reload` for all other code changes. Use screenshot commands to capture visual changes for review (when designing UI, after task completion) and widget-inspect for precise layout debugging. List DTD first to check for connected devices (warn the user that checks are skipped if none). When in doubt, ask.
- **DO NOT run `flutter build`** to verify compilation. Use `flutter analyze` only. The app uses hot reload for visual verification; Flutter MCP tools can also be used for diagnostics.
- **DO NOT add packages to `pubspec.yaml`** without explicit confirmation from the developer. Always ask first. When adding packages, always do it via Dart MCP so latest versions resolve automatically.

### Imports & naming

- **DO NOT use relative imports.** Always use `package:open_control/...` imports (e.g. `import 'package:open_control/core/theme/app_colors.dart';`).
- **Use file name as class name convention.** The main exportable is named the same as the file — e.g. `lib/presentation/home/home_screen.dart` → `class HomeScreen extends StatelessWidget`. Improves discoverability and consistency.

### State & UI conventions (flutter_it / watch_it / get_it)

- **DO NOT create private stateless widgets** (`_FooWidget extends StatelessWidget`). Extract them to public widget files with a `detail_` (screen-scoped) or no prefix (shared). Private widgets are acceptable for StatefulWidget sub-widgets only when tightly coupled to their parent's state.
- **DO use `ValueListenableBuilder` for widgets that are not `WatchingWidget`/`WatchingStatefulWidget`.** `watchValue()`, `watchIt()`, `registerHandler()` and all other `watch_it` functions can only be called inside the `build()` of a `WatchingWidget`, `WatchingStatefulWidget`, or a widget mixing in `WatchItMixin`/`WatchItStatefulWidgetMixin`. Calling them from a plain `StatefulWidget`/`StatelessWidget` throws an assertion error. For a single `ValueListenable` that doesn't need the full watch_it lifecycle, prefer `ValueListenableBuilder`. Switch to `WatchingWidget`/`WatchingStatefulWidget` only when you need multiple watches, handlers, or lifecycle helpers in the same widget.
- **DO NOT wrap a `ListenableBuilder` around `di<Manager>()`** to rebuild on a `ChangeNotifier` manager. Inside a `WatchingWidget`/`WatchingStatefulWidget`: for a single plain getter use `watchPropertyValue((Manager m) => m.someGetter)`; for a single `ValueListenable` field use `watchValue((Manager m) => m.someValueListenable)`. For multiple `ValueListenable` fields off the same manager, call `watchValue` once per field rather than `Listenable.merge`-ing them. For multiple plain properties that all change via the manager's own `notifyListeners()`, prefer a single `watch(di<Manager>())` over stacking `watchPropertyValue` calls. `ListenableBuilder` remains fine for a `Listenable` that isn't get_it-registered (e.g. an `AnimationController`).
- **DO use `watchValue()` with a selector** for conditional checks, not `watch(notifier).value == value`. Use `watchValue((ThemeManager m) => m.mode)` to get the unwrapped value directly.
- **DO NOT extract single-use local variables** for values like colors or theme lookups. Inline them at the call site. Only extract a local if referenced more than once in the same scope.

### Theming

- **DO NOT manually check brightness to pick colors** when the theme already handles it. Use `Theme.of(context).textTheme.*` (colors are adaptive per theme). Only reach for `context.textColor` / `context.mutedColor` / `context.borderColor` from the `AppThemeColors` extension (`package:open_control/core/theme/app_theme_colors.dart`) or `app_colors.dart` directly when explicitly overriding the theme default.

### Navigation (GoRouter)

- **Prefer GoRouter navigation** over `Navigator.of(context).push()` for all app navigation. Use `context.push(AppRoute.path)` or `context.go(AppRoute.path)` with constants from the `AppRoute` enum (`lib/core/router/routes.dart`). Use `context.pop()` for dismissing dialogs/bottom sheets. Only use `Navigator` directly for a custom route (e.g. `SideSheetRoute`) or a route not registered in GoRouter. Never use raw string paths like `'/manage/edit'` — always access them via `AppRoute` constants or helper methods.
- **Use `refreshListenable` for state-driven router redirects, not callbacks.** GoRouter's `refreshListenable` accepts any `Listenable` (e.g. `ValueNotifier<bool>`, `ChangeNotifier`). Register a `ValueNotifier<bool>` in get_it and pass it to `GoRouter(refreshListenable: ...)`; the `redirect` callback reads the current value. Do not wire router refresh through managers — that creates circular awareness between data and routing layers.

### Data modeling

- **DO separate entity concerns per table.** A data entity stores only its intrinsic data — no user state. User-specific state (progress, favorite flags, status) lives in dedicated entities that reference the data entity via `ToOne`. Never mix user state into a data entity.

### Forms (validasi)

- **DO use validasi for all forms.** Never use bare `TextEditingController` + manual validation for form inputs. Create a model in the models directory with `@ValidateClass` annotations, run the generator (`build_runner` / `tool/sync.dart build`) to produce the schema, then use `ValidasiFormController` + `ValidasiForm` + `ValidasiAppTextField` / `ValidasiFormField` in the screen. Relevant packages: `validasi_ui`, `validasi`, `validasi_annotation` (+ dev: `validasi_gen`, `build_runner`).

### Error handling (Talker)

- **DO NOT silently catch exceptions.** Every `catch` block must log the error via `di<Talker>()` and/or rethrow. Empty catch clauses (`on Exception catch (_) {}`) hide bugs and make failures impossible to diagnose. When handling an exception gracefully (e.g. feature-unavailable-on-platform), log it before falling back.
