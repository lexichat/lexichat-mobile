import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class LLMSetupScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Local LLM Setup'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step 1: Download Termux',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('Download Termux from the F-Droid repository:'),
              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  _launchUrl('https://f-droid.org/en/packages/com.termux/');
                },
                icon: Icon(Icons.download),
                label: Text('Download Termux'),
              ),
              SizedBox(height: 16),
              Text(
                'Step 2: Run Setup Script on Termux',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('Run the following command in Termux:'),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'curl -sL https://raw.githubusercontent.com/shripadaRao/lexichat-mobile/main/lib/scripts/setup_environment.bash | dos2unix | bash -s',
                      style: TextStyle(fontFamily: 'Courier'),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _copyToClipboard(
                        'curl -sL https://raw.githubusercontent.com/shripadaRao/lexichat-mobile/main/lib/scripts/setup_environment.bash | dos2unix | bash -s',
                        context,
                      );
                    },
                    icon: Icon(Icons.copy),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Step 3: Download Model Script',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('Run the following command in Termux:'),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'curl -sL https://raw.githubusercontent.com/shripadaRao/lexichat-mobile/main/lib/scripts/download_llm.bash | bash -s 1',
                      style: TextStyle(fontFamily: 'Courier'),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _copyToClipboard(
                          'curl -sL https://raw.githubusercontent.com/shripadaRao/lexichat-mobile/main/lib/scripts/download_llm.bash | bash -s 1',
                          context);
                    },
                    icon: Icon(Icons.copy),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Step 4: Run Server',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('Run the following command in Termux:'),
              SizedBox(height: 8),
              Text(
                './server',
                style: TextStyle(fontFamily: 'Courier'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  void _copyToClipboard(String text, BuildContext context) async {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Copied to clipboard")));
    });
  }
}
