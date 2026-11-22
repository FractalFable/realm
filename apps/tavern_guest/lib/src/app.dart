import 'package:material_ui/material_ui.dart';
import 'package:realm_ui/realm_ui.dart';
import 'package:tavern_core/tavern_core.dart';

/// Root Flutter web shell for Tavern guests ordering from a table QR link.
class TavernGuestApp extends StatefulWidget {
  /// Creates a [TavernGuestApp] configured from runtime [bootstrap].
  const TavernGuestApp({super.key, this.bootstrap, this.themeMode = .system});

  /// Runtime venue branding and capability flags; defaults to `Example Venue`.
  final VenueBootstrap? bootstrap;

  /// Theme brightness mode used by [MaterialApp].
  final ThemeMode themeMode;

  @override
  State<TavernGuestApp> createState() => _TavernGuestAppState();
}

class _TavernGuestAppState extends State<TavernGuestApp> {
  int _cartCount = 0;

  @override
  Widget build(BuildContext context) {
    final bootstrap =
        widget.bootstrap ??
        VenueBootstrap(
          branding: VenueBranding(
            name: 'Example Venue',
            primaryColorArgb: 0xFF6B2D5C,
          ),
        );

    return MaterialApp(
      title: bootstrap.branding.name,
      theme: buildRealmTheme(bootstrap.branding),
      darkTheme: buildRealmTheme(bootstrap.branding, brightness: .dark),
      themeMode: widget.themeMode,
      home: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return Scaffold(
            key: const ValueKey('tavern_guest_scaffold'),
            appBar: AppBar(
              title: Text(
                bootstrap.branding.name,
                key: const ValueKey('tavern_guest_title'),
              ),
              actions: [
                Semantics(
                  identifier: 'tavern_guest_cart_button',
                  label: 'Open cart ($_cartCount items)',
                  button: true,
                  child: IconButton(
                    key: const ValueKey('tavern_guest_cart_button'),
                    tooltip: 'Open cart',
                    icon: Badge.count(
                      count: _cartCount,
                      child: const Icon(Icons.shopping_bag_outlined),
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: isWide
                  ? Row(
                      crossAxisAlignment: .start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _MenuPreviewCard(
                            bootstrap: bootstrap,
                            onAddSample: () => setState(() => _cartCount++),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _OrderStatusCard(cartCount: _cartCount),
                        ),
                      ],
                    )
                  : ListView(
                      children: [
                        _MenuPreviewCard(
                          bootstrap: bootstrap,
                          onAddSample: () => setState(() => _cartCount++),
                        ),
                        const SizedBox(height: 16),
                        _OrderStatusCard(cartCount: _cartCount),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuPreviewCard extends StatelessWidget {
  const _MenuPreviewCard({required this.bootstrap, required this.onAddSample});

  final VenueBootstrap bootstrap;
  final VoidCallback onAddSample;

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        children: [
          Text('Menu', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            bootstrap.capabilities.aiAssistantEnabled
                ? 'A2UI pairing assistant ready'
                : 'Browse drinks and kitchen items',
          ),
          const SizedBox(height: 12),
          Semantics(
            identifier: 'tavern_guest_add_item_button',
            label: 'Add sample item to cart',
            button: true,
            child: FilledButton.icon(
              key: const ValueKey('tavern_guest_add_item_button'),
              onPressed: onAddSample,
              icon: const Icon(Icons.add),
              label: const Text('Add item'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard({required this.cartCount});

  final int cartCount;

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        children: [
          Text('Your Order', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Items in cart: $cartCount',
            key: const ValueKey('tavern_guest_cart_summary'),
          ),
        ],
      ),
    ),
  );
}
