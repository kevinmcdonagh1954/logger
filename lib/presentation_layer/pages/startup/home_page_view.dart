import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../jobs/jobs_view.dart';
import '../calculations/single_join_view.dart';
import '../calculations/polar_view.dart';
import '../calculations/setout_view.dart';
import '../jobs/jobs_viewmodel.dart';
import '../../../application_layer/core/service_locator.dart';
import '../coordinates/coordinates_view.dart';
import '../../core/logger_app_bar.dart';
import '../settings/settings_view.dart';
import '../fixing/fixing_page_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import '../../viewmodels/usage_viewmodel.dart';
// import 'coordinate_manager.dart';

// Route observer to track navigation events
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isCalculationsExpanded = false;
  late final UsageViewModel _usageViewModel;

  // Get the current job name from the JobsViewModel
  String? get currentJobName => _jobsViewModel.currentJobName.value;

  late final JobsViewModel _jobsViewModel = locator<JobsViewModel>();

  @override
  void initState() {
    super.initState();
    _usageViewModel = UsageViewModel();
    _usageViewModel.startTracking(currentJobName);

    // Open drawer automatically after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openDrawer();
    });

    // Listen for changes to the current job
    _jobsViewModel.currentJobName.addListener(_onCurrentJobChanged);
  }

  void _onCurrentJobChanged() {
    // Update usage tracking when job changes
    _usageViewModel.stopTracking();
    _usageViewModel.startTracking(currentJobName);

    // Force UI update when the current job changes
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _usageViewModel.dispose();
    // Unsubscribe from route observer
    routeObserver.unsubscribe(this);
    _jobsViewModel.currentJobName.removeListener(_onCurrentJobChanged);
    super.dispose();
  }

  // Called when the top route has been popped off, and this route now appears
  @override
  void didPopNext() {
    // Rebuild UI to show current point count
    if (mounted) {
      setState(() {});
    }

    // Open drawer when returning to this page
    _openDrawer();
  }

  // Helper method to open the drawer
  void _openDrawer() {
    if (scaffoldKey.currentState != null &&
        !scaffoldKey.currentState!.isDrawerOpen) {
      scaffoldKey.currentState!.openDrawer();
    }
  }

  // Navigation items defined as config, not actual widget instances
  List<NavigationItemConfig> get _navigationItems {
    final l10n = AppLocalizations.of(context)!;
    return [
      NavigationItemConfig(
        icon: Icons.home,
        label: l10n.homePage,
        viewBuilder: _buildPlaceholderWidget,
        placeholderLabel: l10n.homePage,
      ),
      NavigationItemConfig(
        icon: Icons.folder,
        label: l10n.jobs,
        viewBuilder: _buildJobsView,
        subtitle: l10n.jobsHint,
      ),
      NavigationItemConfig(
        icon: Icons.place,
        label: l10n.coordinates,
        viewBuilder: _buildCoordinatesView,
        subtitle: l10n.coordinatesHint,
      ),
      NavigationItemConfig(
        icon: Icons.calculate,
        label: l10n.calculations,
        viewBuilder: (label) => _buildCalculationsView(context),
        subtitle: l10n.calculationsHint,
      ),
      NavigationItemConfig(
        icon: Icons.gps_fixed,
        label: l10n.fixes,
        viewBuilder: (label) => const FixingPageView(),
      ),
      NavigationItemConfig(
        icon: Icons.timeline,
        label: l10n.roads,
        viewBuilder: _buildPlaceholderWidget,
        placeholderLabel: l10n.roads,
      ),
      NavigationItemConfig(
        icon: Icons.pin_drop,
        label: l10n.setout,
        viewBuilder: _buildSettingOutView,
      ),
      NavigationItemConfig(
        icon: Icons.settings,
        label: l10n.settings,
        viewBuilder: _buildSettingsView,
      ),
      NavigationItemConfig(
        icon: Icons.exit_to_app,
        label: l10n.quit,
        viewBuilder: _buildPlaceholderWidget,
        placeholderLabel: l10n.quit,
      ),
    ];
  }

  // Factory method for JobsView
  static Widget _buildJobsView(String? label) => const JobsView();

  // Factory method for CoordinatesView
  static Widget _buildCoordinatesView(String? label) => const CoordinatesView();

  // Factory method for Calculations View
  Widget _buildCalculationsView(BuildContext context) {
    final currentJob = _jobsViewModel.currentJobName.value;
    if (currentJob == null || currentJob.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a job first')),
      );
      return _buildPlaceholderWidget('Calculations');
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => PolarView(jobName: currentJob)),
          ),
          child: const Text('Polar'),
        ),
      ],
    );
  }

  // Factory method for Setting Out View
  static Widget _buildSettingOutView(String? label) =>
      SetoutView(jobName: locator<JobsViewModel>().currentJobName.value!);

  // Factory method for Settings View
  static Widget _buildSettingsView(String? label) => const SettingsView();

  // Factory method for placeholder widgets
  static Widget _buildPlaceholderWidget(String? label) =>
      _PlaceholderWidget(label: label ?? 'Page');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: LoggerAppBar(
        title: 'LOGGER HOME PAGE',
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: Drawer(
        child: Builder(
          builder: (context) => _buildDrawerContent(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Kevin profile image
            Column(
              children: [
                // Display current job name or "No Current Job" above the image
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ValueListenableBuilder<String?>(
                    valueListenable: _jobsViewModel.currentJobName,
                    builder: (context, currentJobName, child) {
                      return Text(
                        currentJobName != null && currentJobName.isNotEmpty
                            ? "Current Job: $currentJobName"
                            : "No Current Job",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: currentJobName != null &&
                                  currentJobName.isNotEmpty
                              ? Colors.black
                              : Colors.red,
                          fontFamily: 'Readex Pro',
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 160,
                  height: 180,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/kevin_on_land_cruiser_front_screen.jpg',
                      width: 180,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'LOGGER ENGINEERING SURVEY SOFTWARE',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF14181B),
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Readex Pro',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Developing 28th May 2025',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontFamily: 'Readex Pro',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontFamily: 'Readex Pro',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/www.jpg',
                      width: 20,
                      height: 20,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () async {
                        await launchUrl(Uri.parse('https://www.logger.co.za'));
                      },
                      child: const Text(
                        'www.logger.co.za',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontFamily: 'Readex Pro',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Logger  image
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30.0),
                  child: Image.asset(
                    'assets/images/logger_liberia_2010.jpg',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kevin McDonagh',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        fontFamily: 'Readex Pro',
                      ),
                    ),
                    const SizedBox(height: 5),
                    InkWell(
                      onTap: () async {
                        final Uri phoneUri = Uri(
                          scheme: 'tel',
                          path: '+27836765167',
                        );
                        await launchUrl(phoneUri);
                      },
                      child: const Text(
                        '+27 (0)83 676 5167',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontFamily: 'Readex Pro',
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    InkWell(
                      onTap: () async {
                        // WhatsApp link - remove the (0) for international format
                        final Uri whatsappUri =
                            Uri.parse('https://wa.me/27836765167');
                        await launchUrl(whatsappUri);
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'WhatsApp',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Readex Pro',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    InkWell(
                      onTap: () async {
                        final Uri emailUri = Uri(
                          scheme: 'mailto',
                          path: 'kevin@logger.co.za',
                          query: 'subject=Logger Query',
                        );
                        await launchUrl(emailUri);
                      },
                      child: const Text(
                        'kevin@logger.co.za',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontFamily: 'Readex Pro',
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Buchanan harbour with Smo. \nLiberia 2010',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Readex Pro',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Jono image with Jono's details
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30.0),
                  child: Image.asset(
                    'assets/images/jono.jpg',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 30),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jono Braude',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        fontFamily: 'Readex Pro',
                      ),
                    ),
                    const SizedBox(height: 5),
                    InkWell(
                      onTap: () async {
                        final Uri phoneUri = Uri(
                          scheme: 'tel',
                          path: '+27824449339',
                        );
                        await launchUrl(phoneUri);
                      },
                      child: const Text(
                        '+27 (0)82 4444 9339',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontFamily: 'Readex Pro',
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    InkWell(
                      onTap: () async {
                        // WhatsApp link - remove the (0) for international format
                        final Uri whatsappUri =
                            Uri.parse('https://wa.me/27824449339');
                        await launchUrl(whatsappUri);
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'WhatsApp',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Readex Pro',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    InkWell(
                      onTap: () async {
                        final Uri emailUri = Uri(
                          scheme: 'mailto',
                          path: 'jonobraude@gmail.com',
                          query: 'subject=Logger Query',
                        );
                        await launchUrl(emailUri);
                      },
                      child: const Text(
                        'jonobraude@gmail.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontFamily: 'Readex Pro',
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Jono at the beach',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Readex Pro',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Center(child: Text('Localization not available'));
    }
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40.0), // Reduced space for the status bar

          // Display current job name above the image
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              currentJobName != null && currentJobName!.isNotEmpty
                  ? l10n.currentJob(currentJobName!)
                  : l10n.noCurrentJob,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: currentJobName != null && currentJobName!.isNotEmpty
                    ? Colors.black
                    : Colors.red,
                fontFamily: 'Readex Pro',
              ),
              textAlign: TextAlign.center,
            ),
          ),

          ClipRRect(
            borderRadius: BorderRadius.circular(50.0),
            child: Image.asset(
              'assets/images/kevin_on_land_cruiser_front_screen.jpg',
              width: 100.0, // Reduced size
              height: 110.0, // Reduced size
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16.0), // Spacing after image

          // Generate menu items from navigation items
          ..._navigationItems.asMap().entries.map((entry) {
            final int index = entry.key;
            final NavigationItemConfig item = entry.value;

            // Special handling for Calculations menu with submenus
            if (item.label == l10n.calculations) {
              return Column(
                children: [
                  _buildDrawerItem(
                    item.label,
                    subtitle: item.subtitle,
                    onTap: () {
                      if (!mounted) return;
                      setState(() {
                        _isCalculationsExpanded = !_isCalculationsExpanded;
                      });
                    },
                    trailing: Icon(
                      _isCalculationsExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 20.0,
                      color:
                          currentJobName != null && currentJobName!.isNotEmpty
                              ? null
                              : Colors.grey,
                    ),
                  ),
                  if (_isCalculationsExpanded) ...[
                    _buildDrawerItem(
                      l10n.singleJoin,
                      onTap: () async {
                        final currentContext = context;
                        if (!mounted || !currentContext.mounted) return;
                        Navigator.pop(currentContext); // Close the drawer
                        Navigator.pushReplacement(
                          currentContext,
                          MaterialPageRoute(
                            builder: (context) => SingleJoinView(
                              jobName: currentJobName!,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      l10n.polar,
                      onTap: () async {
                        final currentContext = context;
                        if (!mounted || !currentContext.mounted) return;
                        Navigator.pop(currentContext); // Close the drawer
                        Navigator.pushReplacement(
                          currentContext,
                          MaterialPageRoute(
                            builder: (context) => PolarView(
                              jobName: currentJobName!,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              );
            }

            // Regular menu items
            return _buildDrawerItem(
              item.label,
              subtitle: item.subtitle,
              onTap: () async {
                final currentContext = context;
                // Special handling for Quit menu item
                if (item.label == AppLocalizations.of(currentContext)!.quit) {
                  _showUsageTimerDialog();
                  return;
                }

                // If it's not the home page, navigate to the view
                if (index > 0) {
                  final Widget view = item.viewBuilder(item.placeholderLabel);
                  if (!mounted || !currentContext.mounted) return;
                  Navigator.pop(currentContext); // Close the drawer

                  // Navigate to the selected view using pushReplacement
                  Navigator.pushReplacement(
                    currentContext,
                    MaterialPageRoute(
                      builder: (context) => view,
                    ),
                  );
                } else {
                  if (!mounted || !currentContext.mounted) return;
                  Navigator.pop(
                      currentContext); // Just close the drawer for home
                }
              },
            );
          }),

          const SizedBox(height: 8.0), // Small padding at the bottom
        ],
      ),
    );
  }

  Widget _buildDrawerItem(String title,
      {String? subtitle, VoidCallback? onTap, Widget? trailing}) {
    bool isEnabled = title == 'Jobs' ||
        title == 'Quit' ||
        (currentJobName != null && currentJobName!.isNotEmpty);

    // Check if this is a submenu item (Join, Polar, Area)
    final l10n = AppLocalizations.of(context)!;
    bool isSubmenu =
        title == l10n.singleJoin || title == l10n.polar || title == l10n.area;

    // Regular menu item
    return ListTile(
      dense: isSubmenu, // Make submenu items more compact
      visualDensity: isSubmenu
          ? const VisualDensity(vertical: -4, horizontal: -4)
          : null, // Reduce vertical spacing even more
      contentPadding: isSubmenu
          ? const EdgeInsets.only(
              left: 32.0,
              right: 16.0,
              top: 0,
              bottom: 0) // Adjusted left padding for better alignment
          : null,
      title: title == 'Coordinates'
          ? ValueListenableBuilder<int>(
              valueListenable: _jobsViewModel.pointCount,
              builder: (context, count, child) {
                return Text(
                  'Coordinates${count > 0 ? ' ($count)' : ''}',
                  style: TextStyle(
                    color: isEnabled ? const Color(0xFF1515C4) : Colors.grey,
                    letterSpacing: 0.0,
                    fontFamily: 'Readex Pro',
                    fontSize: isSubmenu
                        ? 13.0
                        : null, // Slightly smaller font for submenus
                  ),
                  textAlign: isSubmenu
                      ? TextAlign.right
                      : TextAlign.left, // Right align submenu items
                );
              },
            )
          : Text(
              title,
              style: TextStyle(
                color: isEnabled ? const Color(0xFF1515C4) : Colors.grey,
                letterSpacing: 0.0,
                fontFamily: 'Readex Pro',
                fontSize: isSubmenu ? 13.0 : null,
              ),
              textAlign: isSubmenu
                  ? TextAlign.right
                  : TextAlign.left, // Right align submenu items
            ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize:
                    isSubmenu ? 10.0 : 10.0, // Match main menu subtitle size
                letterSpacing: 0.0,
                fontFamily: 'Readex Pro',
                color: isEnabled ? null : Colors.grey,
              ),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: isSubmenu ? 20.0 : 20.0, // Match main menu icon size
            color: isEnabled ? null : Colors.grey,
          ),
      onTap: isEnabled ? onTap : null,
      enabled: isEnabled,
    );
  }

  void _showUsageTimerDialog() async {
    final currentDuration = _usageViewModel.currentDuration;
    final formattedDuration = _usageViewModel.formatDuration(currentDuration);
    final currentContext = context;
    final l10n = AppLocalizations.of(currentContext)!;

    if (currentJobName != null) {
      final totalJobDuration =
          await _usageViewModel.getTotalDurationByJob(currentJobName!);
      final formattedTotalDuration =
          _usageViewModel.formatDuration(totalJobDuration);

      if (!mounted || !currentContext.mounted) return;

      showDialog(
        context: currentContext,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(l10n.usageTimer),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.currentSession(formattedDuration)),
                const SizedBox(height: 8),
                Text(
                    l10n.totalJobTime(currentJobName!, formattedTotalDuration)),
                const SizedBox(height: 8),
                if (_usageViewModel.currentPosition != null) ...[
                  Text(l10n.latitude(
                      _usageViewModel.currentPosition!.latitude.toString())),
                  Text(l10n.longitude(
                      _usageViewModel.currentPosition!.longitude.toString())),
                ] else
                  Text(l10n.locationNotAvailable),
              ],
            ),
            actions: <Widget>[
              if (_usageViewModel.currentPosition != null)
                TextButton(
                  onPressed: () async {
                    final lat = _usageViewModel.currentPosition!.latitude;
                    final lon = _usageViewModel.currentPosition!.longitude;
                    final url =
                        'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url));
                    }
                  },
                  child: Text(l10n.viewOnGoogleMaps),
                ),
              TextButton(
                onPressed: () {
                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();
                },
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () async {
                  await _usageViewModel.stopTracking();
                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();
                  SystemNavigator.pop();
                },
                child: Text(l10n.exit),
              ),
            ],
          );
        },
      );
    } else {
      if (!mounted || !currentContext.mounted) return;
      showDialog(
        context: currentContext,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(l10n.usageTimer),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.currentSession(formattedDuration)),
                const SizedBox(height: 8),
                if (_usageViewModel.currentPosition != null) ...[
                  Text(l10n.latitude(
                      _usageViewModel.currentPosition!.latitude.toString())),
                  Text(l10n.longitude(
                      _usageViewModel.currentPosition!.longitude.toString())),
                ] else
                  Text(l10n.locationNotAvailable),
              ],
            ),
            actions: <Widget>[
              if (_usageViewModel.currentPosition != null)
                TextButton(
                  onPressed: () async {
                    final lat = _usageViewModel.currentPosition!.latitude;
                    final lon = _usageViewModel.currentPosition!.longitude;
                    final url =
                        'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url));
                    }
                  },
                  child: Text(l10n.viewOnGoogleMaps),
                ),
              TextButton(
                onPressed: () {
                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();
                },
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () async {
                  await _usageViewModel.stopTracking();
                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();
                  SystemNavigator.pop();
                },
                child: Text(l10n.exit),
              ),
            ],
          );
        },
      );
    }
  }
}

/// Navigation item configuration class
class NavigationItemConfig {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? placeholderLabel;
  final Widget Function(String?) viewBuilder;

  const NavigationItemConfig({
    required this.icon,
    required this.label,
    required this.viewBuilder,
    this.placeholderLabel,
    this.subtitle,
  });
}

/// Placeholder widget for unimplemented pages
class _PlaceholderWidget extends StatelessWidget {
  final String label;

  const _PlaceholderWidget({required this.label});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          ),
        ),
        title: Text(label),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.comingSoon,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
