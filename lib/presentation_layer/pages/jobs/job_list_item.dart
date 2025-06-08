import 'package:flutter/material.dart';
import 'job_action_buttons.dart';
import 'job_sort_order.dart';

/// A widget that displays a job item in the list
class JobListItem extends StatelessWidget {
  final String jobName;
  final bool isSelected;
  final bool isCurrentJob;
  final Function(String) onTap;
  final Function(String) onDoubleTap;
  final Function(String) onSettings;
  final Function(String) onBackup;
  final Function(String) onDelete;
  final Function() onSearch;
  final Function() onCreateNewJob;
  final Function(String) onInfo;
  final Function(BuildContext, JobSortMethod) onSortSelected;
  final ValueNotifier<JobSortMethod> currentSortMethod;

  const JobListItem({
    super.key,
    required this.jobName,
    required this.isSelected,
    required this.isCurrentJob,
    required this.onTap,
    required this.onDoubleTap,
    required this.onSettings,
    required this.onBackup,
    required this.onDelete,
    required this.onSearch,
    required this.onCreateNewJob,
    required this.onInfo,
    required this.onSortSelected,
    required this.currentSortMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 2 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onDoubleTap: () => onDoubleTap(jobName),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // First row: job name
              ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        jobName,
                        style: TextStyle(
                          fontWeight: isSelected || isCurrentJob
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected || isCurrentJob
                              ? Colors.blue.shade800
                              : null,
                        ),
                      ),
                    ),
                    if (isCurrentJob)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                  ],
                ),
                onTap: () => onTap(jobName),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 3.0,
                ),
                dense: true,
                visualDensity: const VisualDensity(vertical: -4),
              ),

              // Show action buttons only for the selected job
              if (isSelected) ...[
                const Divider(height: 1),
                JobActionButtons(
                  jobName: jobName,
                  onSettings: onSettings,
                  onBackup: onBackup,
                  onDelete: onDelete,
                  onSearch: onSearch,
                  onCreateNewJob: onCreateNewJob,
                  onInfo: onInfo,
                  onSortSelected: onSortSelected,
                  currentSortMethod: currentSortMethod,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
