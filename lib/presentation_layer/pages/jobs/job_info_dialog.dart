import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// A dialog that shows detailed information about a job
class JobInfoDialog {
  /// Show a dialog with job information
  static Future<void> show(
    BuildContext context, {
    required String jobName,
    required Future<Map<String, dynamic>> Function(String) getJobInfoFunction,
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const AlertDialog(
        title: Text('Loading Job Information'),
        content: SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    try {
      // Get job information
      final jobInfo = await getJobInfoFunction(jobName);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Format dates
      final DateTime modifiedDate = jobInfo['date'] as DateTime;
      final String formattedModifiedDate =
          '${modifiedDate.day.toString().padLeft(2, '0')}/${modifiedDate.month.toString().padLeft(2, '0')}/${modifiedDate.year} ${modifiedDate.hour.toString().padLeft(2, '0')}:${modifiedDate.minute.toString().padLeft(2, '0')}';

      final DateTime? creationDate = jobInfo['creationDate'] as DateTime?;
      final String formattedCreationDate = creationDate != null
          ? '${creationDate.day.toString().padLeft(2, '0')}/${creationDate.month.toString().padLeft(2, '0')}/${creationDate.year} ${creationDate.hour.toString().padLeft(2, '0')}:${creationDate.minute.toString().padLeft(2, '0')}'
          : 'Not available';

      // Show information dialog
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(l10n.jobInfoDialogTitle(jobName)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(l10n.lastModified),
                    subtitle: Text(formattedModifiedDate),
                  ),
                  ListTile(
                    title: Text(l10n.created),
                    subtitle: Text(formattedCreationDate),
                  ),
                  ListTile(
                    title: Text(l10n.size),
                    subtitle: Text('${jobInfo['sizeKB']} KB'),
                  ),
                  ListTile(
                    title: Text(l10n.location),
                    subtitle: Text(jobInfo['location'] as String),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(MaterialLocalizations.of(context).closeButtonLabel),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting job info: ${e.toString()}'),
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    }
  }
}
