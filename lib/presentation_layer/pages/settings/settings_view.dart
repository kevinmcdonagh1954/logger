import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../../application_layer/core/localization_provider.dart';
import '../startup/home_page_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
        title: Text(l10n!.settings),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Language Section
          Consumer<LocalizationProvider>(
            builder: (context, provider, child) {
              return ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: Text(LocalizationProvider.getLanguageName(
                    provider.locale.languageCode)),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Select Language'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var locale
                                in LocalizationProvider.supportedLocales)
                              RadioListTile<String>(
                                title: Text(
                                    LocalizationProvider.getLanguageName(
                                        locale.languageCode)),
                                value: locale.languageCode,
                                groupValue: provider.locale.languageCode,
                                onChanged: (value) {
                                  if (value != null) {
                                    provider.setLocale(Locale(value));
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          const Divider(),
        ],
        ),
      ),
    );
  }
}
