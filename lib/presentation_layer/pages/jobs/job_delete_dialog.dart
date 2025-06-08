import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// A dialog for deleting jobs
class JobDeleteDialog {
  /// Show a confirmation dialog for deleting a job
  static Future<void> show(
    BuildContext context, {
    required String jobName,
    required Future<void> Function(String) deleteJobFunction,
    required Future<void> Function() refreshJobsListFunction,
    required Future<void> Function(String) openJobFunction,
    required Function(String) selectJobFunction,
    required Function() updateUIFunction,
    required Function() notifyJobUpdatedFunction,
    required ValueNotifier<String?> currentJobNameNotifier,
    required ValueNotifier<List<String>> filteredJobsNotifier,
  }) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(dialogContext)!.deletingYourJob),
          content: Text(AppLocalizations.of(dialogContext)!
              .deleteJobConfirmation(jobName)),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                  ),
                  child: Text(
                    AppLocalizations.of(dialogContext)!.cancel,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(
                    AppLocalizations.of(dialogContext)!.delete,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      try {
        // Delete the job
        await deleteJobFunction(jobName);

        // Refresh jobs list
        await refreshJobsListFunction();

        // Get the new current job (if any jobs exist)
        if (filteredJobsNotifier.value.isNotEmpty) {
          final String newCurrentJob =
              currentJobNameNotifier.value ?? filteredJobsNotifier.value.first;

          // Explicitly open this job to ensure it's marked as current
          await openJobFunction(newCurrentJob);

          // Select this job in the UI
          selectJobFunction(newCurrentJob);

          // Force UI update to show green checkmark
          updateUIFunction();

          // Also notify listeners to ensure all UI elements update
          notifyJobUpdatedFunction();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Job "$jobName" deleted. Now using "$newCurrentJob"'),
                duration: const Duration(milliseconds: 500),
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Job "$jobName" deleted. No jobs remaining.'),
                duration: const Duration(milliseconds: 500),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting job: ${e.toString()}'),
              duration: const Duration(milliseconds: 500),
            ),
          );
        }
      }
    }
  }
}
