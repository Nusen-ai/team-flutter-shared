import 'package:flutter/material.dart';
import 'package:device_info_plugin/device_info_plugin.dart';
import '../services/channel_service.dart';
import '../services/route_service.dart';

/// 商城页面
/// 展示设备信息并支持浏览商品
class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  DeviceInfo? _deviceInfo;
  Map<String, dynamic> _deviceData = {};
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _initPlugin();
    _loadDeviceInfo();
    _loadProducts();
  }

  Future<void> _initPlugin() async {
    DeviceInfoPlugin.instance.init();
  }

  /// 加载设备信息
  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfo = await DeviceInfoPlugin.instance.getDeviceInfo();

      setState(() {
        _deviceInfo = deviceInfo;
        _deviceData = {
          'name': deviceInfo.name,
          'systemName': deviceInfo.systemName,
          'systemVersion': deviceInfo.systemVersion,
          'model': deviceInfo.model,
          'localizedModel': deviceInfo.localizedModel,
          'identifierForVendor': deviceInfo.identifierForVendor,
          'isPhysicalDevice': deviceInfo.isPhysicalDevice,
          'hardwareInfo': deviceInfo.hardwareInfo != null
              ? {
                  'cpuType': deviceInfo.hardwareInfo!.cpuType,
                  'cpuCoreCount': deviceInfo.hardwareInfo!.cpuCoreCount,
                  'gpuInfo': deviceInfo.hardwareInfo!.gpuInfo,
                }
              : null,
          'screenInfo': deviceInfo.screenInfo != null
              ? {
                  'width': deviceInfo.screenInfo!.width,
                  'height': deviceInfo.screenInfo!.height,
                  'scale': deviceInfo.screenInfo!.scale,
                  'isRetina': deviceInfo.screenInfo!.isRetina,
                }
              : null,
          'storageInfo': deviceInfo.storageInfo != null
              ? {
                  'totalSpace': deviceInfo.storageInfo!.totalSpaceGB,
                  'freeSpace': deviceInfo.storageInfo!.freeSpaceGB,
                  'usedSpace': deviceInfo.storageInfo!.usedSpaceGB,
                }
              : null,
          'memoryInfo': deviceInfo.memoryInfo != null
              ? {
                  'totalMemory': deviceInfo.memoryInfo!.totalMemoryGB,
                  'freeMemory': deviceInfo.memoryInfo!.freeMemoryGB,
                  'usedMemory': deviceInfo.memoryInfo!.usedMemoryGB,
                }
              : null,
        };
        _isLoading = false;
      });

      await ChannelService.instance.sendMessageToNative(
        method: 'onDeviceInfoReceived',
        arguments: _deviceData,
      );

      ChannelService.instance.sendPageNavigationToNative('shop');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _deviceData = {'error': e.toString()};
      });
    }
  }

  /// 加载商品列表
  void _loadProducts() {
    _products = [
      {
        'id': '1',
        'name': 'iPhone 15 Pro',
        'price': 999.00,
        'image': '📱',
        'description': '最新款iPhone，配备A17 Pro芯片',
      },
      {
        'id': '2',
        'name': 'MacBook Pro',
        'price': 1999.00,
        'image': '💻',
        'description': 'M3 Pro芯片，专业级笔记本',
      },
      {
        'id': '3',
        'name': 'AirPods Pro',
        'price': 249.00,
        'image': '🎧',
        'description': '主动降噪，个性化空间音频',
      },
      {
        'id': '4',
        'name': 'Apple Watch',
        'price': 399.00,
        'image': '⌚',
        'description': '健康监测，时尚设计',
      },
      {
        'id': '5',
        'name': 'iPad Pro',
        'price': 799.00,
        'image': '📲',
        'description': 'M2芯片，全面屏设计',
      },
      {
        'id': '6',
        'name': 'HomePod',
        'price': 299.00,
        'image': '🔊',
        'description': '智能音响，Siri语音助手',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('商城'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDeviceInfoDialog,
            tooltip: '设备信息',
          ),
          IconButton(
            icon: const Icon(Icons.assignment),
            onPressed: () {
              Navigator.pushReplacementNamed(context, RouteService.surveyRoute);
            },
            tooltip: '问卷调查',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDeviceInfoBanner(),
          Expanded(
            child: _buildProductGrid(),
          ),
        ],
      ),
    );
  }

  /// 设备信息横幅
  Widget _buildDeviceInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_iphone, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoading ? '加载中...' : _deviceInfo?.name ?? '未知设备',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _isLoading ? '' : '${_deviceInfo?.model ?? ''} - iOS ${_deviceInfo?.systemVersion ?? ''}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 商品网格
  Widget _buildProductGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(_products[index]);
      },
    );
  }

  /// 商品卡片
  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showProductDetail(product),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Center(
                  child: Text(
                    product['image'],
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '\$${product['price'].toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示设备信息对话框
  void _showDeviceInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.phone_iphone, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('设备信息'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _deviceData.entries.map((entry) {
              if (entry.value is Map) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...((entry.value as Map).entries.map((e) =>
                          Text('  ${e.key}: ${e.value}'))),
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value?.toString() ?? 'N/A',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 显示商品详情
  void _showProductDetail(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              product['image'],
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              product['name'],
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${product['price'].toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              product['description'],
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已添加 ${product['name']} 到购物车'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('加入购物车'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
