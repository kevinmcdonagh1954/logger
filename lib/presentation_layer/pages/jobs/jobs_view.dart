import 'package:flutter/material.dart';
import 'package:logger/application_layer/core/service_locator.dart';
import 'package:logger/presentation_layer/core/logger_app_bar.dart';
import 'package:logger/presentation_layer/core/debug_app_bar.dart';
import 'jobs_viewmodel.dart';
import 'job_list_item.dart';
import '../../../application_layer/jobs/job_actions_service.dart';
import 'dart:async';
import '../startup/home_page_view.dart'; // Import for routeObserver
import '../../../l10n/app_localizations.dart';

/// View for displaying and managing jobs
class JobsView extends StatefulWidget {
  const JobsView({super.key});

  @override
  State<JobsView> createState() => _JobsViewState();
}

class _JobsViewState extends State<JobsView> with DebugInfoMixin, RouteAware {
  // Search controller
  final TextEditingController _searchController = TextEditingController();

  late final JobsViewModel _viewModel = locator<JobsViewModel>();
  late final JobActionsService _jobActions =
      JobActionsService(_viewModel, context);

  // State
  bool _isSearchVisible = false;

  void _navigateToJobs(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  void initState() {
    super.initState();
    _viewModel.init();

    // Set up listener for search
    _searchController.addListener(() {
      if (_searchController.text.isNotEmpty) {
        _viewModel.setSearchQuery(_searchController.text);
      }
    });

    // Add listener to rebuild when filtered jobs change
    _viewModel.filteredJobs.addListener(() {
      if (mounted) {
        setState(() {}); // Trigger rebuild to update app bar title
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route observer
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    // Only refresh if we're returning to this screen
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      _refreshJobsList();
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Refresh jobs list when returning to this screen
    _refreshJobsList();
  }

  // Refreshes the jobs list by directly calling the job service
  Future<void> _refreshJobsList() async {
    // Show loading indicator
    _viewModel.isBusy.value = true;

    try {
      // Refresh the jobs list
      await _viewModel.refreshJobsList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh jobs list'),
            duration: Duration(milliseconds: 500),
          ),
        );
      }
    } finally {
      // Hide loading indicator
      _viewModel.isBusy.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        return false;
      },
      child: Scaffold(
        appBar: LoggerAppBar(
          title: 'JOBS',
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateToJobs(context),
          ),
        ),
        body: Column(
          children: [
            // Add refresh indicator at the top
            ValueListenableBuilder<bool>(
              valueListenable: _viewModel.isBusy,
              builder: (context, isBusy, child) {
                if (isBusy) {
                  return const LinearProgressIndicator();
                }
                return const SizedBox(height: 4);
              },
            ),

            // Search bar with Exit button
            if (_isSearchVisible)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context)!.searchJobsHint,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        autofocus: true,
                        onSubmitted: (value) {
                          _performSearch(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _toggleSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      child: Text(AppLocalizations.of(context)!.exit),
                    ),
                  ],
                ),
              ),

            // Error message
            ValueListenableBuilder<bool>(
              valueListenable: _viewModel.hasError,
              builder: (context, hasError, child) {
                return hasError
                    ? ValueListenableBuilder<String?>(
                        valueListenable: _viewModel.errorMessage,
                        builder: (context, errorMessage, child) {
                          return Container(
                            color: Colors.red.shade100,
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              errorMessage ?? 'An error occurred',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink();
              },
            ),

            // Jobs list
            Expanded(
              child: ValueListenableBuilder<List<String>>(
                valueListenable: _viewModel.filteredJobs,
                builder: (context, jobs, child) {
                  if (jobs.isEmpty) {
                    return _buildEmptyJobsView();
                  }

                  return ValueListenableBuilder<String?>(
                    valueListenable: _viewModel.selectedJob,
                    builder: (context, selectedJob, child) {
                      return ValueListenableBuilder<String?>(
                        valueListenable: _viewModel.currentJobName,
                        builder: (context, currentJobName, child) {
                          return ListView.builder(
                            itemCount: jobs.length,
                            itemBuilder: (context, index) {
                              final job = jobs[index];
                              final bool isSelected = job == selectedJob;
                              final bool isCurrentJob = job == currentJobName;

                              return JobListItem(
                                jobName: job,
                                isSelected: isSelected,
                                isCurrentJob: isCurrentJob,
                                onTap: _selectJob,
                                onDoubleTap: _openJob,
                                onSettings: _openJobSettings,
                                onBackup: _backupJob,
                                onDelete: _showDeleteJobDialog,
                                onSearch: _toggleSearch,
                                onCreateNewJob: _createNewJob,
                                onInfo: _showJobInfoDialog,
                                onSortSelected: (context, method) =>
                                    _setSortMethod(context, method),
                                currentSortMethod: ValueNotifier<JobSortMethod>(
                                    _viewModel.sortMethod.value),
                              );
                            },
                          );
                        },
                      );
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

  // Build the empty jobs view
  Widget _buildEmptyJobsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/no_jobs_found.jpg',
            width: 64,
            height: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Jobs Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a new job to get started',
            style: TextStyle(
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create A New Job'),
            onPressed: _createNewJob,
          ),
        ],
      ),
    );
  }

  // Toggle search visibility
  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;

      // Clear search when hiding
      if (!_isSearchVisible) {
        _searchController.clear();
        _viewModel.setSearchQuery('');
      }
    });
  }

  // Automatically close search after search is performed
  void _performSearch(String query) {
    _viewModel.setSearchQuery(query);

    // Close the search box
    setState(() {
      _isSearchVisible = false;
    });
  }

  // Handler for setting sort method
  void _setSortMethod(BuildContext context, JobSortMethod method) {
    _viewModel.setSortMethod(method);
  }

  // Delegated methods that use the JobActionsService

  void _selectJob(String jobName) async {
    // Select the job
    _viewModel.selectJob(jobName);

    // Make it the current job
    final bool success = await _viewModel.openJob(jobName);
    if (success) {
      // Force UI update to reflect the change
      _viewModel.notifyJobUpdated();

      if (mounted) {
        setState(() {});
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job "$jobName" is now active'),
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open job'),
            duration: Duration(milliseconds: 500),
          ),
        );
      }
    }

    // If search is visible, close it and clear the search query
    if (_isSearchVisible) {
      setState(() {
        _isSearchVisible = false;
        _searchController.clear();
        _viewModel.setSearchQuery('');
      });
    }
  }

  void _openJob(String jobName) async {
    await _jobActions.openJob(jobName);
  }

  void _createNewJob() async {
    await _jobActions.createNewJob();

    // Force refresh UI after job creation
    if (mounted) {
      setState(() {
        // This will rebuild the UI and switch from empty view to job list
        // if a job was successfully created
      });
    }
  }

  void _showDeleteJobDialog(String jobName) async {
    await _jobActions.deleteJob(jobName);
  }

  void _openJobSettings(String jobName) async {
    await _jobActions.openJobSettings(jobName);
  }

  void _backupJob(String jobName) async {
    await _jobActions.backupJob(jobName);
  }

  void _showJobInfoDialog(String jobName) async {
    await _jobActions.showJobInfo(jobName);
  }
}
