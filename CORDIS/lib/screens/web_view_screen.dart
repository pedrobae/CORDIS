import 'package:cordis/providers/navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _controller;
  bool _isLoading = false;
  WebResourceError? _webResourceError;

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
  }

  void _initializeWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _webResourceError = error;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse("https://newheartbrasil.org/"));
  }

  Future<bool> _handleBackNavigation() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return true;
    }
    return false;
  }

  Widget _buildWebView() {
    if (_webResourceError != null) {
      return Center(
        child: Text(
          'Error: ${_webResourceError!.description}',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          Positioned(
            top: 24,
            left: 24,
            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.surface),
          ),
      ],
    );
  }

  Widget _buildPopScope(Widget child) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        final canGoBack = await _handleBackNavigation();
        if (!canGoBack && mounted) {
          context.read<NavigationProvider>().attemptPop(context);
        }
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildPopScope(_buildWebView());
  }
}
