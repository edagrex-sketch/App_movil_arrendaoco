import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:arrendaoco/theme/tema.dart';

class StripePayScreen extends StatefulWidget {
  final String url;
  final String title;

  const StripePayScreen({
    super.key, 
    required this.url,
    this.title = 'Pago Seguro',
  });

  @override
  State<StripePayScreen> createState() => _StripePayScreenState();
}

class _StripePayScreenState extends State<StripePayScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            // Detectar éxito
            if (url.contains('/success') || url.contains('checkout-success')) {
              _showSuccessAndClose();
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('/success') || request.url.contains('checkout-success')) {
              _showSuccessAndClose();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _showSuccessAndClose() {
    // Cerramos la pantalla y devolvemos true significando éxito
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: MiTema.azul,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
