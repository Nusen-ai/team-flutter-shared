import 'package:flutter/services.dart';

/// 页面导航服务
/// 处理 Flutter 页面与 iOS 原生页面之间的导航交互
class NavigationService {
  NavigationService._();

  static final NavigationService _instance = NavigationService._();
  static NavigationService get instance => _instance;

  /// 用于通知 iOS 关闭 Flutter 页面的 MethodChannel
  static const MethodChannel _closeChannel =
      MethodChannel('com.shared.components/close_flutter');

  /// 关闭当前 Flutter 页面，返回到 iOS 原生页面
  /// 通过 MethodChannel 通知 iOS 侧关闭当前 Flutter 视图控制器
  static Future<void> closeFlutterPage() async {
    try {
      await _closeChannel.invokeMethod('closeFlutterPage');
    } on PlatformException catch (e) {
      print('关闭Flutter页面失败: ${e.message}');
    } on MissingPluginException {
      print('closeFlutterPage 方法未实现');
    }
  }

  /// 通知 iOS 侧导航到指定页面
  /// [pageName] 页面名称
  static Future<void> notifyNavigation(String pageName) async {
    try {
      await _closeChannel.invokeMethod('onPageNavigated', {
        'page': pageName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } on PlatformException catch (e) {
      print('通知导航失败: ${e.message}');
    }
  }
}
