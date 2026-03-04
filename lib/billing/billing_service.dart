import 'package:url_launcher/url_launcher.dart';

class BillingService {
  Future<void> openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      throw Exception('Could not open URL');
    }
  }
}
