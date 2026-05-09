import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_scanner_plugin/qr_scanner_plugin.dart';
import '../services/channel_service.dart';
import '../services/route_service.dart';
import '../services/navigation_service.dart';

/// 登录页面
/// 支持用户名密码登录和扫码登录两种方式
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isScanning = false;
  bool _isFlashOn = false;
  StreamSubscription? _scanSubscription;
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void initState() {
    super.initState();
    _initChannelService();
    _initScanner();
  }

  void _initChannelService() {
    ChannelService.instance.init();
    ChannelService.instance.registerFlutterCallback('native_login_request', (data) {
      if (data != null && data is Map) {
        final username = data['username'] as String?;
        final password = data['password'] as String?;
        if (username != null && password != null) {
          _performLogin(username, password);
        }
      }
    });
  }

  Future<void> _initScanner() async {
    QrScannerPlugin.instance.init();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    QrScannerPlugin.instance.dispose();
    super.dispose();
  }

  /// 执行登录操作
  Future<void> _performLogin(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      _showError('用户名和密码不能为空');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      await ChannelService.instance.sendLoginSuccessToNative(
        'user_${DateTime.now().millisecondsSinceEpoch}',
        'token_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        _showSuccess('登录成功');
        ChannelService.instance.sendPageNavigationToNative('shop');
      }
    } catch (e) {
      _showError('登录失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 开始扫码
  Future<void> _startScan() async {
    setState(() => _isScanning = true);

    final hasPermission = await QrScannerPlugin.instance.checkCameraPermission();
    if (!hasPermission) {
      final granted = await QrScannerPlugin.instance.requestCameraPermission();
      if (!granted) {
        _showError('请授权相机权限');
        setState(() => _isScanning = false);
        return;
      }
    }

    _scanSubscription?.cancel();
    _scanSubscription = QrScannerPlugin.instance.scanResultStream.listen((result) async {
      if (result.success && result.code != null) {
        await QrScannerPlugin.instance.pauseCamera();

        await ChannelService.instance.sendScanResultToNative(result.code!);

        if (mounted) {
          _showSuccess('扫码成功: ${result.code}');
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushReplacementNamed(context, RouteService.shopRoute);
          }
        }
      }
    });
  }

  /// 停止扫码
  void _stopScan() {
    _scanSubscription?.cancel();
    QrScannerPlugin.instance.pauseCamera();
    setState(() => _isScanning = false);
  }

  /// 切换闪光灯
  Future<void> _toggleFlash() async {
    final isOn = await QrScannerPlugin.instance.toggleFlashlight();
    setState(() => _isFlashOn = isOn);
  }

  /// 切换到扫码模式
  void _switchToScanMode() {
    _startScan();
  }

  /// 切换到账号密码模式
  void _switchToAccountMode() {
    _stopScan();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationService.closeFlutterPage(),
          tooltip: '返回',
        ),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.dialpad : Icons.qr_code_scanner),
            onPressed: _isScanning ? _switchToAccountMode : _switchToScanMode,
            tooltip: _isScanning ? '账号密码登录' : '扫码登录',
          ),
        ],
      ),
      body: _isScanning ? _buildScanView() : _buildLoginForm(),
    );
  }

  /// 构建扫码视图
  Widget _buildScanView() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              Container(
                key: _qrKey,
                color: Colors.black,
                child: Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 64,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '将二维码放入框内',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '请扫描二维码进行登录',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: _toggleFlash,
              icon: Icon(_isFlashOn ? Icons.flash_off : Icons.flash_on),
              label: Text(_isFlashOn ? '关闭闪光灯' : '打开闪光灯'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建登录表单
  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.business,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            '企业共享组件登录',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '支持扫码登录和账号密码登录',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 48),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: '用户名',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: '密码',
              prefixIcon: const Icon(Icons.lock),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      '登录',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _switchToScanMode,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('使用扫码登录'),
          ),
        ],
      ),
    );
  }

  void _handleLogin() {
    _performLogin(
      _usernameController.text.trim(),
      _passwordController.text,
    );
  }
}
