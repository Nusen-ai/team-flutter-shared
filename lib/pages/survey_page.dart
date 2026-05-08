import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/channel_service.dart';
import '../services/route_service.dart';

/// 问卷表单页面
/// 支持填写问卷并通过蓝牙发送数据
class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _feedbackController = TextEditingController();

  int _satisfactionLevel = 3;
  List<String> _selectedFeatures = [];
  bool _isSubmitting = false;
  bool _isBluetoothEnabled = false;
  bool _isSendingBluetooth = false;
  BluetoothDevice? _connectedDevice;

  final List<String> _featureOptions = [
    '用户界面',
    '性能',
    '功能完整性',
    '易用性',
    '稳定性',
    '兼容性',
  ];

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
    ChannelService.instance.sendPageNavigationToNative('survey');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  /// 检查蓝牙状态
  Future<void> _checkBluetoothStatus() async {
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        setState(() => _isBluetoothEnabled = false);
        return;
      }

      final state = await FlutterBluePlus.adapterState.first;
      setState(() => _isBluetoothEnabled = state == BluetoothAdapterState.on);
    } catch (e) {
      setState(() => _isBluetoothEnabled = false);
    }
  }

  /// 开关蓝牙
  Future<void> _toggleBluetooth() async {
    if (_isBluetoothEnabled) {
      try {
        await FlutterBluePlus.stopScan();
        if (_connectedDevice != null) {
          await _connectedDevice!.disconnect();
          setState(() {
            _connectedDevice = null;
            _isBluetoothEnabled = false;
          });
        }
      } catch (e) {
        _showError('关闭蓝牙失败: $e');
      }
    } else {
      try {
        await FlutterBluePlus.turnOn();
        setState(() => _isBluetoothEnabled = true);
      } catch (e) {
        _showError('打开蓝牙失败，请手动在设置中开启');
      }
    }
  }

  /// 扫描并连接蓝牙设备
  Future<void> _scanAndConnectDevice() async {
    if (!_isBluetoothEnabled) {
      _showError('请先开启蓝牙');
      return;
    }

    setState(() => _isSendingBluetooth = true);

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      BluetoothDevice? targetDevice;
      await for (final scanResult in FlutterBluePlus.scanResults) {
        for (final result in scanResult) {
          if (result.device.platformName.isNotEmpty) {
            targetDevice = result.device;
            break;
          }
        }
        if (targetDevice != null) break;
      }

      await FlutterBluePlus.stopScan();

      if (targetDevice != null) {
        await targetDevice.connect(timeout: const Duration(seconds: 10));
        setState(() => _connectedDevice = targetDevice);
        _showSuccess('已连接到设备: ${targetDevice.platformName}');
      } else {
        _showError('未找到可连接的蓝牙设备');
      }
    } catch (e) {
      _showError('连接失败: $e');
    } finally {
      setState(() => _isSendingBluetooth = false);
    }
  }

  /// 通过蓝牙发送数据
  Future<void> _sendDataViaBluetooth(Map<String, dynamic> data) async {
    if (_connectedDevice == null) {
      _showError('请先连接蓝牙设备');
      return;
    }

    setState(() => _isSendingBluetooth = true);

    try {
      final services = await _connectedDevice!.discoverServices();

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            final jsonData = data.toString();
            final bytes = jsonData.codeUnits;
            await characteristic.write(bytes);

            await ChannelService.instance.sendBluetoothDataToNative(jsonData);
          }
        }
      }

      _showSuccess('数据已通过蓝牙发送');
    } catch (e) {
      _showError('蓝牙发送失败: $e');
    } finally {
      setState(() => _isSendingBluetooth = false);
    }
  }

  /// 提交表单
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      final formData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'feedback': _feedbackController.text.trim(),
        'satisfaction': _satisfactionLevel,
        'features': _selectedFeatures,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (_connectedDevice != null) {
        await _sendDataViaBluetooth(formData);
      }

      await ChannelService.instance.sendMessageToNative(
        method: 'onSurveySubmitted',
        arguments: formData,
      );

      if (mounted) {
        _showSuccess('问卷提交成功！');
        _resetForm();
        Navigator.pushReplacementNamed(context, RouteService.shopRoute);
      }
    } catch (e) {
      _showError('提交失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// 重置表单
  void _resetForm() {
    _nameController.clear();
    _emailController.clear();
    _feedbackController.clear();
    setState(() {
      _satisfactionLevel = 3;
      _selectedFeatures = [];
    });
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
        title: const Text('问卷调查'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isBluetoothEnabled ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: _isBluetoothEnabled ? Colors.green : Colors.grey,
            ),
            onPressed: _toggleBluetooth,
            tooltip: _isBluetoothEnabled ? '蓝牙已开启' : '蓝牙已关闭',
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushReplacementNamed(context, RouteService.shopRoute);
            },
            tooltip: '商城',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBluetoothStatusCard(),
              const SizedBox(height: 24),
              _buildFormFields(),
              const SizedBox(height: 24),
              _buildSatisfactionSection(),
              const SizedBox(height: 24),
              _buildFeatureSelection(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 蓝牙状态卡片
  Widget _buildBluetoothStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _isBluetoothEnabled ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: _isBluetoothEnabled ? Colors.green : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '蓝牙状态',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _isBluetoothEnabled
                            ? (_connectedDevice != null
                                ? '已连接: ${_connectedDevice!.platformName}'
                                : '已开启，可连接设备')
                            : '已关闭',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isBluetoothEnabled)
                  ElevatedButton(
                    onPressed: _toggleBluetooth,
                    child: const Text('开启'),
                  ),
                if (_isBluetoothEnabled && _connectedDevice == null)
                  ElevatedButton(
                    onPressed: _isSendingBluetooth ? null : _scanAndConnectDevice,
                    child: _isSendingBluetooth
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('连接'),
                  ),
              ],
            ),
            if (_connectedDevice != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _scanAndConnectDevice,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新扫描'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _connectedDevice?.disconnect();
                        setState(() => _connectedDevice = null);
                      },
                      icon: const Icon(Icons.link_off, color: Colors.red),
                      label: const Text('断开连接', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 表单字段
  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: '姓名',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入姓名';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: '邮箱',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入邮箱';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return '请输入有效的邮箱地址';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _feedbackController,
          decoration: InputDecoration(
            labelText: '您的建议',
            prefixIcon: const Icon(Icons.feedback),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入您的建议';
            }
            if (value.trim().length < 10) {
              return '建议至少输入10个字符';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// 满意度选择
  Widget _buildSatisfactionSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '满意度评分',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (index) {
                final level = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _satisfactionLevel = level),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _satisfactionLevel >= level
                          ? _getSatisfactionColor(level)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getSatisfactionIcon(level),
                          color: _satisfactionLevel >= level
                              ? Colors.white
                              : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getSatisfactionText(level),
                          style: TextStyle(
                            color: _satisfactionLevel >= level
                                ? Colors.white
                                : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSatisfactionColor(int level) {
    switch (level) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getSatisfactionIcon(int level) {
    switch (level) {
      case 1:
        return Icons.sentiment_very_dissatisfied;
      case 2:
        return Icons.sentiment_dissatisfied;
      case 3:
        return Icons.sentiment_neutral;
      case 4:
        return Icons.sentiment_satisfied;
      case 5:
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  String _getSatisfactionText(int level) {
    switch (level) {
      case 1:
        return '很差';
      case 2:
        return '较差';
      case 3:
        return '一般';
      case 4:
        return '满意';
      case 5:
        return '非常满意';
      default:
        return '未知';
    }
  }

  /// 功能选择
  Widget _buildFeatureSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '关注的功能（可多选）',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _featureOptions.map((feature) {
                final isSelected = _selectedFeatures.contains(feature);
                return FilterChip(
                  label: Text(feature),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedFeatures.add(feature);
                      } else {
                        _selectedFeatures.remove(feature);
                      }
                    });
                  },
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).primaryColor,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 提交按钮
  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send),
                  const SizedBox(width: 8),
                  Text(
                    _connectedDevice != null ? '提交并发送蓝牙数据' : '提交问卷',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
      ),
    );
  }
}
