import 'package:flutter/material.dart';
import 'polar_view.dart';

class CalculationsPage extends StatelessWidget {
  final String jobName;
  const CalculationsPage({super.key, required this.jobName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculations'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            // Joins Section
            _buildSection(
              context,
              'Joins',
              [],
            ),

            // Polars Section
            _buildSection(
              context,
              'Polars',
              [
                _buildCalculationButton(
                  context,
                  'Polar Calculations',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PolarView(jobName: jobName),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> buttons) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          color: Colors.deepPurple.withAlpha(26),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: buttons,
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationButton(
      BuildContext context, String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
