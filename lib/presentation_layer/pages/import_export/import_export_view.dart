import 'package:flutter/material.dart';
import '../../../application_layer/jobs/job_service.dart';
import '../../../application_layer/core/service_locator.dart';
import '../jobs/jobs_view.dart';
import '../../l10n/app_localizations.dart';

class ImportExportView extends StatelessWidget {
  final String jobName;

  const ImportExportView({super.key, required this.jobName});

  void _navigateToJobs(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const JobsView()),
      (route) => false, // This will remove all routes from the stack
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importExport),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateToJobs(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Import Section
            Text(
              l10n.import,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildButton(
                  label: l10n.coordinates,
                  tooltip: l10n.importCoordinatesHint,
                  onPressed: () async {
                    final jobService = locator<JobService>();
                    await jobService.importPointsFromCSV();
                  },
                ),
                _buildButton(
                  label: l10n.horzAlignment,
                  tooltip: l10n.importHorzAlignmentHint,
                  onPressed: () {},
                ),
                _buildButton(
                  label: l10n.dtmTot,
                  tooltip: l10n.importDtmTotHint,
                  onPressed: () {},
                ),
                _buildButton(
                  label: l10n.roadDesign,
                  tooltip: l10n.importRoadDesignHint,
                  onPressed: () {},
                ),
                _buildButton(
                  label: l10n.strings,
                  tooltip: l10n.importStringsHint,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Export Section
            Text(
              l10n.export,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildButton(
                  label: l10n.coordinates,
                  tooltip: l10n.exportCoordinatesHint,
                  onPressed: () {},
                ),
                _buildButton(
                  label: l10n.tacheRaw,
                  tooltip: l10n.exportTacheRawHint,
                  onPressed: () {},
                ),
                _buildButton(
                  label: l10n.tacheReduced,
                  tooltip: l10n.exportTacheReducedHint,
                  onPressed: () {},
                ),
                _buildButton(
                  label: l10n.fieldbook,
                  tooltip: l10n.exportFieldbookHint,
                  onPressed: () {},
                ),
                _buildButton(
                  label: l10n.roadDesign,
                  tooltip: l10n.exportRoadDesignHint,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Quit Button
            Center(
              child: _buildButton(
                label: l10n.quit,
                onPressed: () => _navigateToJobs(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    String? tooltip,
    required VoidCallback onPressed,
  }) {
    final button = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: onPressed,
      child: Text(label),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: button,
      );
    }

    return button;
  }
}
