import 'package:flutter/services.dart';

/// MethodChannel 服务类
/// 实现Flutter与iOS原生应用的双向通信
class ChannelService {
  ChannelService._();

  static final ChannelService _instance = ChannelService._();
  static ChannelService get instance => _instance;

  /// 从原生应用到Flutter的通道
  static const MethodChannel _nativeToFlutterChannel =
      MethodChannel('com.shared.components/native_to_flutter');

  /// 从Flutter到原生应用的通道
  static const MethodChannel _flutterToNativeChannel =
      MethodChannel('com.shared.components/flutter_to_native');

  /// Flutter事件通道（用于Flutter向iOS发送事件）
  static const EventChannel _eventChannel =
      EventChannel('com.shared.components/event_channel');

  /// 初始化通道服务
  void init() {
    _setupNativeToFlutterListener();
    _setupEventChannelListener();
  }

  /// 设置从原生应用接收消息的监听器
  void _setupNativeToFlutterListener() {
    _nativeToFlutterChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'getDeviceInfo':
          return await _handleGetDeviceInfo(call.arguments);
        case 'loginWithToken':
          return await _handleLoginWithToken(call.arguments);
        case 'setAppConfig':
          return await _handleSetAppConfig(call.arguments);
        default:
          throw PlatformException(
            code: 'NOT_FOUND',
            message: '未找到方法: ${call.method}',
          );
      }
    });
  }

  /// 设置事件通道监听器
  void _setupEventChannelListener() {
    _eventChannel.receiveBroadcastStream().listen(
      (event) {
        _handleNativeEvent(event);
      },
      onError: (error) {
        print('事件通道错误: $error');
      },
    );
  }

  /// 处理原生事件
  void _handleNativeEvent(dynamic event) {
    if (event is Map) {
      final type = event['type'] as String?;
      final data = event['data'];

      switch (type) {
        case 'native_notification':
          _onNativeNotification(data);
          break;
        case 'app_lifecycle':
          _onAppLifecycleChange(data);
          break;
        case 'user_action':
          _onUserAction(data);
          break;
      }
    }
  }

  /// 处理获取设备信息的请求
  Future<Map<String, dynamic>> _handleGetDeviceInfo(dynamic arguments) async {
    return {
      'success': true,
      'data': {
        'platform': 'ios',
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
      }
    };
  }

  /// 处理Token登录请求
  Future<Map<String, dynamic>> _handleLoginWithToken(dynamic arguments) async {
    final token = arguments as String?;
    if (token == null || token.isEmpty) {
      return {
        'success': false,
        'error': 'Token不能为空'
      };
    }
    return {
      'success': true,
      'data': {
        'userId': 'user_12345',
        'username': 'flutter_user',
        'token': token,
      }
    };
  }

  /// 处理应用配置设置
  Future<Map<String, dynamic>> _handleSetAppConfig(dynamic arguments) async {
    if (arguments is! Map) {
      return {
        'success': false,
        'error': '参数格式错误'
      };
    }
    return {
      'success': true,
      'data': {
        'configUpdated': true,
        'receivedConfig': arguments,
      }
    };
  }

  /// 原生通知回调
  void _onNativeNotification(dynamic data) {
    print('收到原生通知: $data');
  }

  /// 应用生命周期变化回调
  void _onAppLifecycleChange(dynamic data) {
    print('应用生命周期变化: $data');
  }

  /// 用户操作回调
  void _onUserAction(dynamic data) {
    print('用户操作: $data');
  }

  /// 向原生应用发送消息
  Future<Map<String, dynamic>> sendMessageToNative({
    required String method,
    dynamic arguments,
  }) async {
    try {
      final result = await _flutterToNativeChannel.invokeMethod(method, arguments);
      return {
        'success': true,
        'data': result,
      };
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': e.message ?? '未知错误',
      };
    }
  }

  /// 发送登录成功事件到原生
  Future<void> sendLoginSuccessToNative(String userId, String token) async {
    await sendMessageToNative(
      method: 'onLoginSuccess',
      arguments: {
        'userId': userId,
        'token': token,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 发送页面跳转事件到原生
  Future<void> sendPageNavigationToNative(String pageName) async {
    await sendMessageToNative(
      method: 'onPageNavigation',
      arguments: {
        'page': pageName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 发送扫码结果到原生
  Future<void> sendScanResultToNative(String scanResult) async {
    await sendMessageToNative(
      method: 'onScanResult',
      arguments: {
        'scanResult': scanResult,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 发送蓝牙数据到原生
  Future<void> sendBluetoothDataToNative(String data) async {
    await sendMessageToNative(
      method: 'onBluetoothData',
      arguments: {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 发送错误信息到原生
  Future<void> sendErrorToNative(String errorCode, String errorMessage) async {
    await sendMessageToNative(
      method: 'onError',
      arguments: {
        'code': errorCode,
        'message': errorMessage,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 注册Flutter回调方法
  void registerFlutterCallback(String methodName, Function(dynamic) callback) {
    // 保存回调方法供后续使用
    _callbacks[methodName] = callback;
  }

  final Map<String, Function(dynamic)> _callbacks = {};
}
