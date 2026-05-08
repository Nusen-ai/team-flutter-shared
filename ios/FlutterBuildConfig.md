# Flutter iOS Framework 编译配置

## 编译命令

### Debug版本（模拟器开发）
```bash
cd flutter_shared_components
flutter build ios-framework \
  --debug \
  --simulator \
  --no-codesign \
  --output=../ios_private_pods/FlutterSharedComponent.xcframework
```

### Release版本（生产环境）
```bash
flutter build ios-framework \
  --release \
  --output=../ios_private_pods/FlutterSharedComponent.xcframework
```

### 指定目标设备
```bash
flutter build ios-framework \
  --release \
  --target-platform=iphoneos \
  --output=../ios_private_pods/FlutterSharedComponent.xcframework
```

## 编译产物

编译完成后，在 `../ios_private_pods/` 目录下生成：

```
FlutterSharedComponent.xcframework/
├── ios-arm64/                              # 真机ARM64架构
│   ├── FlutterSharedComponents.framework/
│   └── Info.plist
├── ios-arm64_x86_64-simulator/              # 模拟器架构（Intel & Apple Silicon）
│   ├── FlutterSharedComponents.framework/
│   └── Info.plist
└── Info.plist                               # Framework总体信息
```

## 产物验证

### 检查Framework架构
```bash
# 列出所有架构
lipo -info FlutterSharedComponent.xcframework

# 检查真机Framework
lipo -info FlutterSharedComponent.xcframework/ios-arm64/FlutterSharedComponents.framework/FlutterSharedComponents

# 检查模拟器Framework
lipo -info FlutterSharedComponent.xcframework/ios-arm64_x86_64-simulator/FlutterSharedComponents.framework/FlutterSharedComponents
```

### 预期输出
真机Framework应包含：`arm64`
模拟器Framework应包含：`arm64 x86_64`

## 常见问题

### 编译失败
```bash
# 清理并重新编译
flutter clean
flutter pub get
flutter build ios-framework --release
```

### 架构不匹配
确保编译产物包含所有目标架构：
- 真机：arm64
- 模拟器（Intel）：x86_64
- 模拟器（Apple Silicon）：arm64

### 符号表问题
如果运行时出现符号找不到错误，尝试：
```bash
flutter build ios-framework \
  --release \
  --debug-symbols-path=./symbols \
  --output=../ios_private_pods/FlutterSharedComponent.xcframework
```

## 自动化编译

使用提供的脚本自动编译：

```bash
cd ../ios_private_pods
chmod +x build_framework.sh
./build_framework.sh
```

脚本将自动：
1. 安装Flutter依赖
2. 清理旧产物
3. 编译Release版本
4. 验证编译结果
