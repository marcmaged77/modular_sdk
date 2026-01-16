# Flutter Modular LC (Lifecycle)

[![pub package](https://img.shields.io/pub/v/flutter_modular_lc.svg)](https://pub.dev/packages/flutter_modular_lc)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **A fork of [flutter_modular](https://pub.dev/packages/flutter_modular) with proper Dependency Injection lifecycle management.**

This package fixes critical singleton/binding disposal issues that occur during app restart, hot reload, module rebuild, and widget disposal.

---

## 🐛 The Problem

The original `flutter_modular` has a **DI disposal bug** where old dependency bindings and singletons are **NOT properly disposed** when:

- The app is restarted (hot restart)
- A module is rebuilt
- `ModularApp` widget is disposed and recreated
- Navigating away and back to a modular SDK/feature

### Symptoms

- **Stale State**: Old singleton instances persist, causing unexpected behavior
- **Memory Leaks**: Disposed widgets still hold references to old injector instances
- **State Corruption**: New modules reuse old instances instead of fresh ones
- **SDK Integration Issues**: Multiple SDKs with their own `ModularApp` instances conflict

### Root Cause

In the original `flutter_modular`, the injectors are declared as **top-level `final` variables**:

```dart
// ❌ PROBLEMATIC: These persist forever, even after dispose()
final _innerInjector = AutoInjector(tag: 'ModularApp', ...);
final injector = AutoInjector(tag: 'ModularCore', ...);
```

This means:
1. Injectors are created once when the library loads
2. They are **never recreated** even after `ModularApp` is disposed
3. `disposeRecursive()` clears bindings but the injector shell persists
4. New `ModularApp` instances reuse the same injector with potentially stale registrations

---

## ✅ The Fix

This package introduces `ModularInjectors` - a lifecycle-aware injector management system:

```dart
// ✅ FIXED: Injectors are created fresh and disposed properly
class ModularInjectors {
  static AutoInjector? _innerInjector;
  static AutoInjector? _injector;

  /// Initialize fresh injectors - called in ModularApp.initState
  static void initialize() {
    dispose(); // Clean up any existing injectors first
    _innerInjector = AutoInjector(tag: 'ModularApp', ...);
    _injector = AutoInjector(tag: 'ModularCore', ...);
  }

  /// Dispose all injectors - called in ModularApp.dispose
  static void dispose() {
    _innerInjector?.disposeRecursive();
    _injector?.disposeRecursive();
    _innerInjector = null;
    _injector = null;
  }
}
```

### How It Works

| Lifecycle Event | Before (Broken) | After (Fixed) |
|-----------------|-----------------|---------------|
| `ModularApp` created | Reuses existing global injector | Creates fresh injectors via `ModularInjectors.initialize()` |
| `ModularApp` disposed | Only clears some bindings | Fully disposes injectors and nulls references via `ModularInjectors.dispose()` |
| Hot restart | Old singletons persist | Fresh injectors, fresh singletons |
| Multiple SDKs | Injector conflicts | Each SDK lifecycle is isolated |

---

## 📦 Installation

```yaml
dependencies:
  flutter_modular_lc: ^6.5.0
```

Then run:
```bash
flutter pub get
```

---

## 🔄 Migration from flutter_modular

Simply replace your import:

```dart
// Before
import 'package:flutter_modular/flutter_modular.dart';

// After
import 'package:flutter_modular_lc/flutter_modular.dart';
```

**No other code changes required!** The API is 100% compatible.

---

## 🚀 Usage

### Basic Usage (Same as flutter_modular)

```dart
import 'package:flutter_modular_lc/flutter_modular.dart';

void main() {
  runApp(ModularApp(
    module: AppModule(),
    child: MaterialApp.router(
      routerConfig: Modular.routerConfig,
    ),
  ));
}

class AppModule extends Module {
  @override
  void binds(Injector i) {
    i.addSingleton<MyService>(MyService.new);
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => HomePage());
  }
}
```

### SDK/Feature Module Pattern

This package is especially useful when building SDKs or feature modules that have their own `ModularApp`:

```dart
class MySdkWrapper extends StatefulWidget {
  @override
  State<MySdkWrapper> createState() => _MySdkWrapperState();
}

class _MySdkWrapperState extends State<MySdkWrapper> {
  @override
  void initState() {
    super.initState();
    // Optional: Pre-initialize if needed before build
    ModularInjectors.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return ModularApp(
      module: MySdkModule(),
      child: MaterialApp.router(
        routerConfig: Modular.routerConfig,
      ),
    );
  }
}
```

### Manual Lifecycle Control

For advanced use cases, you can manually control injector lifecycle:

```dart
// Initialize fresh injectors
ModularInjectors.initialize();

// Check if initialized
if (ModularInjectors.isInitialized) {
  // Access injector
  final service = injector.get<MyService>();
}

// Dispose when done
ModularInjectors.dispose();
```

---

## 🔍 Verifying the Fix

To verify singletons are properly disposed:

```dart
class MyService implements Disposable {
  MyService() {
    print('MyService CREATED: ${identityHashCode(this)}');
  }

  @override
  void dispose() {
    print('MyService DISPOSED: ${identityHashCode(this)}');
  }
}
```

With this package, you'll see:
```
// First launch
MyService CREATED: 123456789

// After hot restart or ModularApp rebuild
MyService DISPOSED: 123456789  // ✅ Old instance disposed
MyService CREATED: 987654321   // ✅ Fresh instance created
```

---

## 📋 API Reference

### ModularInjectors

| Method | Description |
|--------|-------------|
| `ModularInjectors.initialize()` | Creates fresh injectors. Automatically disposes existing ones first. |
| `ModularInjectors.dispose()` | Disposes all injectors and clears references. |
| `ModularInjectors.isInitialized` | Returns `true` if injectors are ready. |
| `ModularInjectors.injector` | Access the main injector (throws if not initialized). |
| `ModularInjectors.innerInjector` | Access the inner injector for module bindings. |

### Backward Compatibility

The global `injector` getter still works:
```dart
// This still works (delegates to ModularInjectors.injector)
final service = injector.get<MyService>();
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

This is a fork of [flutter_modular](https://github.com/Flutterando/modular) by [Flutterando](https://github.com/Flutterando). All credit for the original architecture goes to them.

This fork specifically addresses the DI lifecycle management issue to provide proper singleton disposal.