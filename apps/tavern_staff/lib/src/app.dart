import 'package:material_ui/material_ui.dart';
import 'package:realm_ui/realm_ui.dart';
import 'package:tavern_core/tavern_core.dart';

/// Root Flutter web shell for Tavern staff and venue managers.
class TavernStaffApp extends StatefulWidget {
  /// Creates a [TavernStaffApp] configured from runtime [bootstrap].
  const TavernStaffApp({super.key, this.bootstrap, this.themeMode = .system});

  /// Runtime venue branding and capability flags; defaults to `Example Venue`.
  final VenueBootstrap? bootstrap;

  /// Theme brightness mode used by [MaterialApp].
  final ThemeMode themeMode;

  @override
  State<TavernStaffApp> createState() => _TavernStaffAppState();
}

class _TavernStaffAppState extends State<TavernStaffApp> {
  int _selectedSection = 0;

  static const _sections = <({String key, String label, IconData icon})>[
    (key: 'orders', label: 'Orders', icon: Icons.receipt_long_outlined),
    (key: 'bills', label: 'Bills', icon: Icons.point_of_sale_outlined),
    (key: 'menu', label: 'Menu', icon: Icons.restaurant_menu_outlined),
    (key: 'settings', label: 'Settings', icon: Icons.tune_outlined),
  ];

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
      title: '${bootstrap.branding.name} Staff',
      theme: buildRealmTheme(bootstrap.branding),
      darkTheme: buildRealmTheme(bootstrap.branding, brightness: .dark),
      themeMode: widget.themeMode,
      home: _StaffShell(
        bootstrap: bootstrap,
        sections: _sections,
        selectedIndex: _selectedSection,
        onSelectSection: (index) => setState(() => _selectedSection = index),
      ),
    );
  }
}

class _StaffShell extends StatelessWidget {
  const _StaffShell({
    required this.bootstrap,
    required this.sections,
    required this.selectedIndex,
    required this.onSelectSection,
  });

  final VenueBootstrap bootstrap;
  final List<({String key, String label, IconData icon})> sections;
  final int selectedIndex;
  final ValueChanged<int> onSelectSection;

  @override
  Widget build(BuildContext context) {
    final active = sections[selectedIndex];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isExpanded = constraints.maxWidth >= 1024;
        return Scaffold(
          key: const ValueKey('tavern_staff_scaffold'),
          appBar: AppBar(
            title: Text(
              '${bootstrap.branding.name} — Staff',
              key: const ValueKey('tavern_staff_title'),
            ),
            actions: [
              Semantics(
                identifier: 'tavern_staff_refresh_button',
                label: 'Refresh board',
                button: true,
                child: IconButton(
                  key: const ValueKey('tavern_staff_refresh_button'),
                  tooltip: 'Refresh board',
                  icon: const Icon(Icons.refresh),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          body: Row(
            children: [
              if (isExpanded)
                NavigationRail(
                  key: const ValueKey('tavern_staff_rail'),
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onSelectSection,
                  labelType: .all,
                  destinations: [
                    for (final section in sections)
                      NavigationRailDestination(
                        icon: Icon(section.icon),
                        label: Text(section.label),
                      ),
                  ],
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        active.label,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Card.outlined(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: .start,
                            children: [
                              Text(
                                'Online Ordering: '
                                '${bootstrap.capabilities.onlineOrderingEnabled ? "Enabled" : "Off"}',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'A2UI Copilot: '
                                '${bootstrap.capabilities.aiAssistantEnabled ? "Ready" : "Configure BYOK key"}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: isExpanded
              ? null
              : NavigationBar(
                  key: const ValueKey('tavern_staff_nav_bar'),
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onSelectSection,
                  destinations: [
                    for (final section in sections)
                      NavigationDestination(
                        icon: Icon(section.icon),
                        label: section.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}
