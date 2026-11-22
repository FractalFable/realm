import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart';
import 'package:material_ui/material_ui.dart';

/// App-neutral Flutter host for declarative A2UI surfaces.
///
/// Renders [A2uiSurface] using the ambient Realm Material theme when
/// [aiEnabled] is `true`, and gracefully degrades to [disabledPlaceholder]
/// when AI capabilities are unconfigured.
class RealmA2uiHost extends StatefulWidget {
  /// Creates a [RealmA2uiHost] widget.
  const RealmA2uiHost({
    super.key,
    required this.aiEnabled,
    this.surfaceId = 'main',
    this.initialMessages,
    this.onAction,
    this.onError,
    this.disabledPlaceholder,
  });

  /// Published A2UI v1.0 basic catalog identifier.
  static String get basicCatalogId => BasicCatalog.v1_0Id;

  /// Whether AI/A2UI generation is enabled for this deployment.
  final bool aiEnabled;

  /// Identifier of the target A2UI surface to display.
  final String surfaceId;

  /// Optional initial A2UI v1.0 envelope payload to process.
  final List<Map<String, Object?>>? initialMessages;

  /// Callback invoked when a rendered A2UI component dispatches an action.
  final void Function(A2uiRendererAction action)? onAction;

  /// Callback invoked when the A2UI processor reports a surface/payload error.
  final void Function(A2uiRendererError error)? onError;

  /// Optional widget displayed when [aiEnabled] is `false`.
  final Widget? disabledPlaceholder;

  @override
  State<RealmA2uiHost> createState() => _RealmA2uiHostState();
}

class _RealmA2uiHostState extends State<RealmA2uiHost> {
  MessageProcessor<ComponentImplementation>? _processor;
  SurfaceModel<ComponentImplementation>? _surface;
  Subscription? _createdSub;
  Subscription? _deletedSub;

  @override
  void initState() {
    super.initState();
    if (widget.aiEnabled) {
      _attachProcessor();
    }
  }

  @override
  void didUpdateWidget(RealmA2uiHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.aiEnabled) {
      _detachProcessor();
      _surface = null;
      return;
    }
    final needsReattach =
        !oldWidget.aiEnabled ||
        oldWidget.surfaceId != widget.surfaceId ||
        oldWidget.initialMessages != widget.initialMessages;
    if (needsReattach) {
      _detachProcessor();
      _attachProcessor();
    }
  }

  @override
  void dispose() {
    _detachProcessor();
    super.dispose();
  }

  void _attachProcessor() {
    final processor = MessageProcessor<ComponentImplementation>(
      catalogs: [basicCatalog()],
      onAction: widget.onAction,
      onError: widget.onError,
      reportErrorsOnly: true,
    );
    _processor = processor;
    _createdSub = processor.model.onSurfaceCreated.subscribe((surface) {
      if (surface.id == widget.surfaceId && mounted) {
        setState(() => _surface = surface);
      }
    });
    _deletedSub = processor.model.onSurfaceDeleted.subscribe((deletedId) {
      if (deletedId == widget.surfaceId && mounted) {
        setState(() => _surface = null);
      }
    });

    final messages = widget.initialMessages;
    if (messages != null && messages.isNotEmpty) {
      processor.processMessages(messages);
      _surface = processor.model.getSurface(widget.surfaceId);
    } else {
      _surface = null;
    }
  }

  void _detachProcessor() {
    _createdSub?.unsubscribe();
    _createdSub = null;
    _deletedSub?.unsubscribe();
    _deletedSub = null;
    _processor?.dispose();
    _processor = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.aiEnabled) {
      return widget.disabledPlaceholder ??
          const Card.outlined(
            key: ValueKey('realm_a2ui_disabled_card'),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'AI generative UI is disabled. Configure an AI provider to '
                'enable A2UI surfaces.',
              ),
            ),
          );
    }

    final surface = _surface;
    if (surface == null) {
      return const Card.outlined(
        key: ValueKey('realm_a2ui_empty_card'),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Ready for A2UI surface output.'),
        ),
      );
    }

    return Semantics(
      identifier: 'realm_a2ui_surface',
      label: 'Generative UI surface',
      child: A2uiSurface(
        key: ValueKey('realm_a2ui_surface_${surface.id}'),
        surface: surface,
      ),
    );
  }
}
