import 'package:flutter/material.dart';
import '../../../application_layer/core/service_locator.dart';
import '../../../application_layer/jobs/job_service.dart';
import '../../../domain_layer/coordinates/point.dart';
import '../startup/home_page_view.dart';
import 'coordinates_viewmodel.dart';
import '../../../presentation_layer/pages/jobs/jobs_viewmodel.dart';
import '../../core/coordinate_formatter.dart';
import '../../core/dialogs/point_dialog.dart';
import 'coordinates_map_view.dart';
import 'plot_coordinates_view.dart';
import '../../l10n/app_localizations.dart';

class CoordinatesView extends StatefulWidget {
  const CoordinatesView({super.key});

  @override
  State<CoordinatesView> createState() => _CoordinatesViewState();
}

class _CoordinatesViewState extends State<CoordinatesView> {
  late final CoordinatesViewModel _viewModel;
  late final JobsViewModel _jobsViewModel;
  final _searchController = TextEditingController();
  List<Point> _filteredPoints = [];
  final int _deletedPointsCount = 0;
  String _sortField = 'id';
  bool _sortAscending = true;
  final _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _viewModel = locator<CoordinatesViewModel>();
    _jobsViewModel = locator<JobsViewModel>();
    _viewModel.init();
    _jobsViewModel.init();
    _viewModel.points.addListener(_updateFilteredPoints);
    _updateFilteredPoints();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.points.removeListener(_updateFilteredPoints);
    _jobsViewModel.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _updateFilteredPoints() {
    if (!mounted) return;
    setState(() {
      final searchTerm = _searchController.text.toLowerCase();
      _filteredPoints = _viewModel.points.value.where((point) {
        final descriptorMatch =
            point.descriptor?.toLowerCase().contains(searchTerm) ?? false;
        return point.comment.toLowerCase().contains(searchTerm) ||
            descriptorMatch ||
            point.id.toString().contains(searchTerm) ||
            point.y.toString().contains(searchTerm) ||
            point.x.toString().contains(searchTerm) ||
            point.z.toString().contains(searchTerm);
      }).toList();
      _sortPoints();
    });
  }

  void _sortPoints() {
    if (!mounted) return;
    setState(() {
      _filteredPoints.sort((a, b) {
        var result = 0;
        switch (_sortField) {
          case 'id':
            result = a.id.toString().compareTo(b.id.toString());
            break;
          case 'comment':
            result = a.comment.compareTo(b.comment);
            break;
          case 'y':
            result = a.y.toString().compareTo(b.y.toString());
            break;
          case 'x':
            result = a.x.toString().compareTo(b.x.toString());
            break;
          case 'z':
            result = a.z.toString().compareTo(b.z.toString());
            break;
          case 'descriptor':
            final aDesc = a.descriptor ?? '';
            final bDesc = b.descriptor ?? '';
            result = aDesc.compareTo(bDesc);
            break;
        }
        return _sortAscending ? result : -result;
      });
    });
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, Point point) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Point${point.comment.isNotEmpty ? ': ${point.comment}' : ''}',
            style: const TextStyle(fontSize: 16),
          ),
          content: const Text('Are you sure you want to delete this point?'),
          actions: <Widget>[
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _viewModel.deletePoint(point.id!);
        if (!context.mounted) return;
        setState(() {
          _updateFilteredPoints();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Point deleted successfully')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            ),
          ),
          title: ValueListenableBuilder<String?>(
            valueListenable: _viewModel.currentJobName,
            builder: (context, jobName, _) {
              return Text(_getAdaptiveTitle(jobName ?? ''));
            },
          ),
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.sort),
              color: Colors.white,
              onPressed: _showSortMenu,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'view_on_maps',
                  child: Row(
                    children: [
                      Icon(Icons.map),
                      SizedBox(width: 8),
                      Text('View on Google Maps'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'plot_coordinates',
                  child: Row(
                    children: [
                      Icon(Icons.scatter_plot),
                      SizedBox(width: 8),
                      Text('Plot Coordinates'),
                    ],
                  ),
                ),
              ],
              onSelected: (String value) async {
                if (value == 'view_on_maps') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CoordinatesMapView(
                        points: _viewModel.points.value,
                        coordinateFormat: _viewModel.coordinateFormat.value,
                      ),
                    ),
                  );
                } else if (value == 'plot_coordinates') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlotCoordinatesView(),
                    ),
                  );
                }
              },
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    children: [
                      TextSpan(text: '${_filteredPoints.length}/'),
                      TextSpan(
                        text: '$_deletedPointsCount',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            try {
              await PointDialog.showAddEditPointDialog(
                context: context,
                jobService: locator<JobService>(),
                coordinateFormat: _viewModel.coordinateFormat.value,
                onSuccess: () {
                  if (!context.mounted) return;
                  setState(() {
                    _updateFilteredPoints();
                  });
                },
              );
            } catch (e) {
              debugPrint('Error: ${e.toString()}');
            }
          },
          mini: true,
          backgroundColor: const Color(0xFF0D47A1),
          child: const Icon(Icons.add, size: 20, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Points',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _updateFilteredPoints();
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => _updateFilteredPoints(),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredPoints.length,
                itemBuilder: (context, index) {
                  final point = _filteredPoints[index];
                  if (point.id == null) return const SizedBox.shrink();
                  return ListTile(
                    title: Text(point.comment),
                    subtitle: ValueListenableBuilder<String>(
                      valueListenable: _viewModel.coordinateFormat,
                      builder: (context, format, _) {
                        return Text(
                          '${CoordinateFormatter.formatCoordinates(point, format)}${point.descriptor != null ? '\nDescriptor: ${point.descriptor}' : ''}',
                        );
                      },
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(context, point),
                    ),
                    onTap: () async {
                      try {
                        final updatedPoint =
                            await PointDialog.showAddEditPointDialog(
                          context: context,
                          jobService: locator<JobService>(),
                          coordinateFormat: _viewModel.coordinateFormat.value,
                          existingPoint: point,
                          onDelete: () async {
                            await _viewModel.deletePoint(point.id!);
                            if (!context.mounted) return;
                            setState(() {
                              _updateFilteredPoints();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Point deleted successfully')),
                            );
                          },
                        );

                        if (updatedPoint != null) {
                          if (!context.mounted) return;
                          setState(() {
                            _updateFilteredPoints();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.success)),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('${l10n.error}: ${e.toString()}')),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAdaptiveTitle(String jobName) {
    const int maxLength = 15;
    String title = 'Coordinates - $jobName';

    if (title.length > maxLength) {
      title = 'Coords - $jobName';
    }

    return title;
  }

  void _showSortMenu() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title:
                  Text('ID (${_sortAscending ? 'Ascending' : 'Descending'})'),
              trailing: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
              onTap: () {
                if (!mounted) return;
                setState(() {
                  _sortField = 'id';
                  _sortAscending = !_sortAscending;
                  _sortPoints();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Comment (${_sortAscending ? 'A-Z' : 'Z-A'})'),
              trailing: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
              onTap: () {
                if (!mounted) return;
                setState(() {
                  _sortField = 'comment';
                  _sortAscending = !_sortAscending;
                  _sortPoints();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(
                  'Y Coordinate (${_sortAscending ? 'Ascending' : 'Descending'})'),
              trailing: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
              onTap: () {
                if (!mounted) return;
                setState(() {
                  _sortField = 'y';
                  _sortAscending = !_sortAscending;
                  _sortPoints();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(
                  'X Coordinate (${_sortAscending ? 'Ascending' : 'Descending'})'),
              trailing: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
              onTap: () {
                if (!mounted) return;
                setState(() {
                  _sortField = 'x';
                  _sortAscending = !_sortAscending;
                  _sortPoints();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(
                  'Z Coordinate (${_sortAscending ? 'Ascending' : 'Descending'})'),
              trailing: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
              onTap: () {
                if (!mounted) return;
                setState(() {
                  _sortField = 'z';
                  _sortAscending = !_sortAscending;
                  _sortPoints();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Descriptor (${_sortAscending ? 'A-Z' : 'Z-A'})'),
              trailing: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
              onTap: () {
                if (!mounted) return;
                setState(() {
                  _sortField = 'descriptor';
                  _sortAscending = !_sortAscending;
                  _sortPoints();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
