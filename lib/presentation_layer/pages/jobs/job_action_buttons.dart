import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'job_sort_order.dart';
import '../import_export/import_export_view.dart';

/// A widget that displays action buttons for a selected job
class JobActionButtons extends StatelessWidget {
  final String jobName;
  final Function(String) onSettings;
  final Function(String) onBackup;
  final Function(String) onDelete;
  final Function() onSearch;
  final Function() onCreateNewJob;
  final Function(String) onInfo;
  final Function(BuildContext, JobSortMethod) onSortSelected;
  final ValueNotifier<JobSortMethod> currentSortMethod;

  const JobActionButtons({
    super.key,
    required this.jobName,
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 8.0),
      child: Wrap(
        alignment: WrapAlignment.start,
        spacing: 8,
        runSpacing: 4,
        children: [
          // Settings button
          _buildActionButton(
            icon: Icons.settings,
            label: l10n.settings,
            onPressed: () => onSettings(jobName),
          ),

          // Import button
          _buildActionButton(
            icon: Icons.upload_file,
            label: l10n.importPoints,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImportExportView(jobName: jobName),
                ),
              );
            },
          ),

          // Export button
          _buildActionButton(
            icon: Icons.download,
            label: l10n.exportPoints,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImportExportView(jobName: jobName),
                ),
              );
            },
          ),

          // Line break with SizedBox
          const SizedBox(width: double.infinity, height: 4),

          // Backup button
          _buildActionButton(
            icon: Icons.backup,
            label: l10n.backup,
            onPressed: () => onBackup(jobName),
          ),

          // Delete button
          _buildActionButton(
            icon: Icons.delete,
            label: l10n.delete,
            onPressed: () => onDelete(jobName),
          ),

          // Search For Job button
          _buildActionButton(
            icon: Icons.search,
            label: l10n.searchJob,
            onPressed: onSearch,
          ),

          // Sort By button
          _buildActionButton(
            icon: Icons.sort,
            label: l10n.sortBy,
            onPressed: () {
              // Show a simple dialog for sorting options
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                    title: Text(l10n.sortJobsBy),
                    children: [
                      _buildSortDialogOption(
                        context,
                        JobSortMethod.alphabeticalAtoZ,
                        l10n.nameAtoZ,
                      ),
                      _buildSortDialogOption(
                        context,
                        JobSortMethod.alphabeticalZtoA,
                        l10n.nameZtoA,
                      ),
                      _buildSortDialogOption(
                        context,
                        JobSortMethod.dateModifiedNewest,
                        l10n.dateModifiedNewest,
                      ),
                      _buildSortDialogOption(
                        context,
                        JobSortMethod.dateModifiedOldest,
                        l10n.dateModifiedOldest,
                      ),
                    ],
                  );
                },
              );
            },
          ),

          // Line break with SizedBox
          const SizedBox(width: double.infinity, height: 4),

          // Create New Job button
          _buildActionButton(
            icon: Icons.add,
            label: l10n.createNewJob,
            onPressed: onCreateNewJob,
          ),

          // Info button
          _buildActionButton(
            icon: Icons.info_outline,
            label: l10n.info,
            onPressed: () => onInfo(jobName),
          ),
        ],
      ),
    );
  }

  // Helper method to build action buttons with consistent styling
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 14),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: const Size(0, 28),
      ),
    );
  }

  // Helper method to build sort dialog options
  Widget _buildSortDialogOption(
    BuildContext context,
    JobSortMethod method,
    String title,
  ) {
    return SimpleDialogOption(
      onPressed: () {
        // Call the sort method callback
        onSortSelected(context, method);
        // Close the dialog
        Navigator.pop(context);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          if (method == currentSortMethod.value)
            const Icon(Icons.check, size: 18),
        ],
      ),
    );
  }
}
