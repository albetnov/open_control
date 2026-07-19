# Architecture

## Core Principle

**Complexity must be earned.** Every layer, folder, and abstraction must solve a pain you can name today, not one you anticipate tomorrow. The architecture grows with the app — it does not arrive pre-built.

## Stack

- **get_it** — Service locator / dependency injection (`di<T>()`)
- **watch_it** — Reactive widgets (`WatchingWidget`, `watchValue`, `registerHandler`)
- **command_it** — Async operations as objects (`Command.createAsync`, `isRunning`, `errors`)
- **listen_it** — ValueListenable operators (`map`, `select`, `debounce`, `listen`)
- **go_router** — Declarative routing (`GoRouter`, `refreshListenable` for state-driven redirects)

## Folder Map

```
lib/
├── core/              # App infrastructure (would exist in any Flutter app)
│   ├── theme/         # Design system tokens and Material ThemeData
│   ├── router/        # Navigation (GoRouter, routes, guards)
│   ├── locator.dart   # get_it configuration (configureDependencies)
│   ├── platform/      # Platform channels, native interop
│   └── utils.dart     # Pure helpers with no domain knowledge
├── data/              # Domain data (knows what "manga" and "chapter" mean)
│   ├── models/        # Plain Dart classes (Manga, Chapter, ReadingProgress)
│   ├── sources/       # Concrete I/O classes (FileScanner, LocalDatabase)
│   ├── managers/      # Business logic: Commands, ValueNotifiers, state
│   ├── repositories/  # Thin coordinators between 2+ sources
│   └── exceptions.dart
├── presentation/      # What the user sees
│   ├── {screen}/      # One folder per screen
│   │   ├── {screen}_screen.dart
│   │   └── widgets/   # Widgets used ONLY by this screen
│   └── widgets/       # Shared widgets (promoted when 2+ screens use them)
└── main.dart
```

## Phases

### Phase 1 — Scaffold

The foundation. Flat structure, no abstractions, hardcoded data.

**Structure:**
```
lib/
├── core/
│   ├── theme/
│   ├── router/
│   └── locator.dart
├── data/
│   └── fake_data.dart
├── presentation/
│   └── home/
│       ├── home_screen.dart
│       └── widgets/
└── main.dart
```

**Data flow:** Widgets import data directly. No managers, no sources.

**DI:** `locator.dart` registers app-wide singletons (theme, router). No domain managers yet.

**Errors:** Global `FlutterError.onError` only. Fake data doesn't fail.

**Testing:** Widget tests. No data to mock.

**Promotion trigger:** `fake_data.dart` gets replaced with real I/O.

---

### Phase 2 — Real Data

Real file system access, real data shapes. Sources are concrete classes — no interfaces. Managers wrap sources and expose Commands + ValueListenables.

**Structure:**
```
lib/
├── core/
│   ├── theme/
│   ├── router/
│   ├── locator.dart
│   └── platform/
├── data/
│   ├── models/
│   ├── sources/
│   ├── managers/
│   └── exceptions.dart
├── presentation/
│   └── home/
│       ├── home_screen.dart
│       └── widgets/
└── main.dart
```

**Data flow:**
```
Source (I/O) → Manager (Command/ValueNotifier) → Widget (WatchingWidget)
```

**Managers** are the bridge between I/O and UI:
- Registered as lazy singletons in get_it
- Expose `ValueListenable<T>` for data state
- Expose `Command` for UI-triggered async operations (fetch, create, update, delete)
- `init()` calls sources directly (no Command for startup loads)

**Fetch pattern:**
```dart
class LibraryManager {
  final _mangaList = ValueNotifier<List<Manga>?>(null);
  ValueListenable<List<Manga>?> get mangaList => _mangaList;

  late final fetchCommand = Command.createAsyncNoParam<List<Manga>>(
    () async {
      final result = await di<MangaService>().fetchAll();
      _mangaList.value = result;
      return result;
    },
    initialValue: [],
    errorFilter: const GlobalIfNoLocalErrorFilter(),
  );

  Future<LibraryManager> init() async {
    await fetchCommand.run();
    return this;
  }
}
```

**Mutation pattern:**
```dart
late final createCommand = Command.createAsync<Manga, Manga>(
  (manga) async {
    final created = await di<MangaService>().create(manga);
    _mangaList.value = [...?_mangaList.value, created];
    return created;
  },
  initialValue: Manga.empty(),
  errorFilter: const GlobalIfNoLocalErrorFilter(),
);
```

**Widget pattern:**
```dart
class LibraryScreen extends WatchingWidget {
  @override
  Widget build(BuildContext context) {
    final mangaList = watchValue((LibraryManager m) => m.mangaList);
    final isLoading = watchValue((LibraryManager m) => m.fetchCommand.isRunning);

    registerHandler(
      select: (LibraryManager m) => m.fetchCommand.errors,
      handler: (context, error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${error!.error}')),
        );
      },
    );

    if (isLoading && mangaList == null) return CircularProgressIndicator();
    if (mangaList == null) return ErrorWidget();
    return ListView(...);
  }
}
```

**Errors:**
- Sources throw typed exceptions (`data/exceptions.dart`)
- Commands catch errors automatically — no try/catch in widgets
- `ErrorFilter` routes errors to local `.errors` listeners or global handler
- Widget uses `registerHandler` for side effects (snackbar, dialog)
- Widget reads `isRunning` + nullable data for render state

**Testing:**
- Push get_it scope with fake sources, pop in tearDown
- No interfaces, no mockito
- `test/fakes/` holds in-memory fake sources
- `test/helpers/` holds `pumpApp()` with pre-configured get_it scope

```dart
setUp(() {
  GetIt.I.pushNewScope(
    init: (getIt) {
      getIt.registerSingleton<MangaService>(FakeMangaService());
    },
  );
});
tearDown(() async {
  await GetIt.I.popScope();
});
```

**Promotion trigger:** Second screen appears, or a manager is consumed by 2+ screens.

---

### Phase 3 — Shared State

Multiple screens, navigation, shared widgets and managers.

**Structure:**
```
lib/
├── core/
│   ├── theme/
│   ├── router/
│   ├── locator.dart
│   ├── platform/
│   └── lifecycle/
├── data/
│   ├── models/
│   ├── sources/
│   ├── managers/
│   └── exceptions.dart
├── presentation/
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── widgets/
│   ├── reader/
│   │   ├── reader_screen.dart
│   │   └── widgets/
│   └── widgets/       # Promoted shared widgets
└── main.dart
```

**Data flow:** Same as Phase 2. Managers consume sources. Shared widgets handle display concerns.

**Errors:**
- Shared error display widgets promoted to `presentation/widgets/`
- Error types promoted to `data/exceptions.dart` if consumed by multiple screens
- `Command.globalExceptionHandler` for catch-all logging (Sentry, crashlytics)

**Mutations (optimistic updates):**
- Override fields on proxies (not copyWith on DTOs)
- Update state immediately → fire Command → rollback on error
- `UndoableCommand` for automatic rollback via undo stack

**Streams:**
- Data source exposes `Stream<T>` instead of `Future<T>`
- Manager uses `watchStream()` or `listen_it` operators to bridge to ValueListenable
- Widget watches the resulting ValueListenable as usual

**Router state:**
- GoRouter's `refreshListenable` accepts any `Listenable`
- Register a `ValueNotifier<bool>` (e.g., `isLocked`) in get_it
- Pass to `GoRouter(refreshListenable: di<AuthManager>().isLocked)`
- `redirect` callback reads current value — no widget involved

**Testing:**
- Widget tests with get_it scope overrides
- Integration tests use fake sources from `test/fakes/`

**Promotion trigger:** Caching, multiple data sources for same data, or testability demands a coordination layer.

---

### Phase 4 — Earned Complexity

Repositories exist only when coordination logic is real. This is the ceiling.

**Structure:**
```
lib/
├── core/
│   ├── theme/
│   ├── router/
│   ├── locator.dart
│   ├── platform/
│   └── lifecycle/
├── data/
│   ├── models/
│   ├── sources/
│   ├── managers/
│   ├── repositories/
│   └── exceptions.dart
├── presentation/
│   ├── home/
│   ├── reader/
│   └── widgets/
└── main.dart
```

**Data flow:**
```
Source (I/O) → Repository (coordination) → Manager (Command/ValueNotifier) → Widget (UI)
```

**Repositories are thin coordinators, not DDD aggregates.** They exist only when:
- Multiple sources serve the same data (cache + DB)
- There's real coordination logic (stale-while-revalidate, conflict resolution)
- A source needs to be swappable for testing

**Proxies** wrap DTOs with reactive behavior:
- Computed properties over raw data
- Commands for entity-level operations (toggleLike, updateAvatar)
- Override fields for optimistic UI (getter returns `_override ?? _target.field`)
- `DataRepository` with reference counting when same entity appears in multiple places

**Errors:**
- Repositories unify errors from multiple sources into a single type
- UI never sees source-specific exceptions

**Testing:**
- Repositories tested with real (in-memory) sources, not mocks
- Fake sources in `test/fakes/`

**No further layers without extraordinary justification.**

---

## Folder Breakdown

### `core/` — App Infrastructure

**Litmus test:** *would this exist in any Flutter app, regardless of domain?*

| Path | What | Phase |
|------|------|-------|
| `core/theme/` | Color constants, `ThemeData` config, `BuildContext` color extensions | 1 |
| `core/router/` | GoRouter setup, route definitions, `refreshListenable` redirects | 1 |
| `core/locator.dart` | `configureDependencies()` — get_it registration | 1 |
| `core/platform/` | Platform channels, file picker, permissions | 2+ |
| `core/lifecycle/` | `AppLifecycleListener`, deep link handling | 3+ |
| `core/utils.dart` | Pure helpers: date formatting, string utils. No domain knowledge | 2+ |

**NOT in core:** Repositories, models, sources, managers (domain concerns), settings like reading direction (domain-specific), widgets.

### `data/` — Domain Data

**Litmus test:** *does this know what "manga", "chapter", or "reading progress" means?*

| Path | What | Phase |
|------|------|-------|
| `data/models/` | Plain Dart classes: `Manga`, `Chapter`, `ReadingProgress`. No I/O, no get_it | 2 |
| `data/sources/` | Concrete I/O classes: `FileScanner`, `LocalDatabase`, `ImageLoader`. Each does one thing | 2 |
| `data/managers/` | Business logic: `ChangeNotifier` subclasses with Commands, ValueNotifiers. Registered in get_it | 2 |
| `data/repositories/` | Thin coordinators between 2+ sources. Only when coordination logic is real | 4 |
| `data/exceptions.dart` | Typed exceptions: `MangaNotFoundException`, `StorageException` | 2 |

**NOT in data:** Widgets, navigation logic, theme/design tokens.

### `presentation/` — What the User Sees

**Litmus test:** *does this render pixels?*

| Path | What | Phase |
|------|------|-------|
| `presentation/{screen}/` | One folder per screen. Screen file + `widgets/` subfolder | 1 |
| `presentation/{screen}/widgets/` | Widgets used ONLY by this screen. Co-located | 1 |
| `presentation/widgets/` | Shared widgets promoted when 2+ screens use them | 3 |

**Promotion rule:** A widget moves out of its screen folder only when a second screen imports it. Not before.

**Widget types:**
- `WatchingWidget` / `WatchingStatefulWidget` — when watching ValueListenables via `watchValue()` or `watch()`
- Plain `StatelessWidget` / `StatefulWidget` — when using only local `setState` (no get_it lookups)

### `test/` — Test Infrastructure

| Path | What | Phase |
|------|------|-------|
| `test/fakes/` | Fake data sources: `FakeFileScanner`, `FakeLocalDatabase`. In-memory implementations | 2 |
| `test/helpers/` | Test utilities: `pumpApp()` with get_it scope setup, golden test helpers | 2 |

Fakes live outside `lib/`. Production code never knows they exist.

## Import Rules

```
presentation/  →  core/, data/                   (UI can use everything)
data/          →  core/                          (data can use app infra)
data/          ↛  presentation/                  (data never knows about UI)
core/          →  core/                          (self-contained)
core/          ↛  data/, presentation/           (infra never knows about domain or UI)
                                                   ⚠ exception: core/router/ may
                                                     import presentation/ screens
                                                     (router is the path→screen bridge)
```

**Exception:** The router (`core/router/`) is the sole file in `core/` that may
import from `presentation/`. This is intentional — the router maps paths to
screens. It also hosts core-level concerns (guards, `refreshListenable`,
redirects) that belong in `core/`. No other `core/` file may import `data/`
or `presentation/`.

Dependency direction:
```
presentation/
    ↓
data/
    ↓
core/
```

## Decision Tree

When you have a new piece of code and don't know where it goes:

1. **Does it render pixels?** → `presentation/{screen}/`
2. **Does it touch I/O?** → `data/sources/`
3. **Is it a data shape?** → `data/models/`
4. **Is it business logic / state?** → `data/managers/`
5. **Is it a visual token?** → `core/theme/`
6. **Would it exist in any Flutter app?** → `core/`

If none of these fit, you probably don't need it yet.

## Anti-patterns

- **Feature-scoped folders.** Organizing by feature (`manga/`, `reader/`, `library/`) creates decision fatigue about where shared code lives. Folders by role, always.
- **Premature abstraction.** Interfaces, repositories, use cases before there's real pain. "Service" is not a concept — everything is a source, a manager, or core infrastructure.
- **Barrel files that hide structure.** `export 'everything.dart'` makes it impossible to see what a folder actually contains.
- **Layers for the sake of "clean architecture."** Every layer must solve a named problem. If you can't articulate the pain, you don't need the layer.
- **Mocking at the class level.** Override at the get_it scope level. Interfaces are earned when scope overrides aren't enough.
- **Watching without WatchingWidget.** Always extend `WatchingWidget` or `WatchingStatefulWidget` when using `watchValue()`, `watch()`, or `registerHandler`. Never call watch functions in plain widgets.
- **Nested commands.** Don't call `command.run()` inside another command body. Call the source API directly.
