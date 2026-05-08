class RouteService {
  RouteService._();

  /// 登录页路由
  static const String loginRoute = '/login';

  /// 商城页路由
  static const String shopRoute = '/shop';

  /// 问卷页路由
  static const String surveyRoute = '/survey';

  /// 获取所有路由列表
  static List<String> get allRoutes => [loginRoute, shopRoute, surveyRoute];

  /// 验证路由是否有效
  static bool isValidRoute(String route) {
    return allRoutes.contains(route);
  }
}
