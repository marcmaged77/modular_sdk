import 'package:flutter/material.dart';
import 'package:flutter_modular/src/domain/usecases/replace_instance.dart';
import 'package:modular_core/modular_core.dart';

import '../flutter_modular.dart';
import 'domain/services/bind_service.dart';
import 'domain/services/module_service.dart';
import 'domain/services/route_service.dart';
import 'domain/usecases/bind_module.dart';
import 'domain/usecases/dispose_bind.dart';
import 'domain/usecases/finish_module.dart';
import 'domain/usecases/get_arguments.dart';
import 'domain/usecases/get_bind.dart';
import 'domain/usecases/get_route.dart';
import 'domain/usecases/report_pop.dart';
import 'domain/usecases/report_push.dart';
import 'domain/usecases/set_arguments.dart';
import 'domain/usecases/start_module.dart';
import 'domain/usecases/unbind_module.dart';
import 'infra/services/bind_service_impl.dart';
import 'infra/services/module_service_impl.dart';
import 'infra/services/route_service_impl.dart';
import 'infra/services/url_service/url_service.dart';
import 'presenter/modular_base.dart';
import 'presenter/navigation/modular_route_information_parser.dart';
import 'presenter/navigation/modular_router_delegate.dart';

/// Holds the current active injectors for the ModularApp scope
class ModularInjectors {
  static AutoInjector? _innerInjector;
  static AutoInjector? _injector;

  /// The inner injector that holds user module bindings
  static AutoInjector get innerInjector {
    if (_innerInjector == null) {
      throw StateError(
          'ModularApp not initialized. Call ModularInjectors.initialize() first.');
    }
    return _innerInjector!;
  }

  /// The main injector that holds ModularCore services
  static AutoInjector get injector {
    if (_injector == null) {
      throw StateError(
          'ModularApp not initialized. Call ModularInjectors.initialize() first.');
    }
    return _injector!;
  }

  /// Check if injectors are initialized
  static bool get isInitialized => _injector != null && _innerInjector != null;

  /// Initialize fresh injectors - call this in ModularApp.initState
  static void initialize() {
    // Dispose old injectors if they exist
    dispose();

    // Create fresh inner injector
    _innerInjector = AutoInjector(
      tag: 'ModularApp',
      on: (i) {
        i.addInstance<AutoInjector>(i);
        i.commit();
      },
    );

    // Create fresh main injector
    _injector = AutoInjector(
      tag: 'ModularCore',
      on: (i) {
        //datasource
        i.addInstance<AutoInjector>(_innerInjector!);
        i.addSingleton<Tracker>(Tracker.new);
        //infra
        i.add<BindService>(BindServiceImpl.new);
        i.add<ModuleService>(ModuleServiceImpl.new);
        i.add<RouteService>(RouteServiceImpl.new);
        i.add<UrlService>(UrlService.create);
        //domain
        i.add<DisposeBind>(DisposeBindImpl.new);
        i.add<FinishModule>(FinishModuleImpl.new);
        i.add<GetBind>(GetBindImpl.new);
        i.add<GetRoute>(GetRouteImpl.new);
        i.add<StartModule>(StartModuleImpl.new);
        i.add<GetArguments>(GetArgumentsImpl.new);
        i.add<BindModule>(BindModuleImpl.new);
        i.add<ReportPop>(ReportPopImpl.new);
        i.add<SetArguments>(SetArgumentsImpl.new);
        i.add<UnbindModule>(UnbindModuleImpl.new);
        i.add<ReportPush>(ReportPushImpl.new);
        i.add<ReplaceInstance>(ReplaceInstanceImpl.new);
        //presenter
        i.addInstance(GlobalKey<NavigatorState>());
        i.addSingleton<ModularRouteInformationParser>(
            ModularRouteInformationParser.new);
        i.addSingleton<ModularRouterDelegate>(ModularRouterDelegate.new);
        i.add<IModularNavigator>(() => i<ModularRouterDelegate>());
        i.addLazySingleton<IModularBase>(ModularBase.new);

        i.commit();
      },
    );
  }

  /// Dispose all injectors - call this in ModularApp.dispose
  static void dispose() {
    _innerInjector?.disposeRecursive();
    _injector?.disposeRecursive();
    _innerInjector = null;
    _injector = null;
  }
}

/// Legacy accessor for backward compatibility
/// @deprecated Use ModularInjectors.injector instead
AutoInjector get injector => ModularInjectors.injector;
