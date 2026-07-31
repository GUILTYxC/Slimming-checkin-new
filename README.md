# 轻盈打卡 · Slimming Check-in

一款跨端（**macOS / Android / Windows**）的减肥打卡应用。浅色、简洁、直观，配合流畅的交互与动效。所有数据仅保存在本机（本地 SQLite），无需账号、无需联网。

## 功能

- **计划管理**：创建/编辑/删除减肥计划，每个计划包含开始与结束日期、起始体重、目标体重，以及可增删的每日打卡任务；支持多计划并一键切换「当前计划」。
- **每日打卡**：记录当天体重、消耗卡路里（千卡），逐项勾选任务完成；全部任务完成时触发庆祝动效。支持对历史日期补记。
- **概览 Dashboard**：
  - 距目标进度环（当前体重居中显示，完成度百分比）
  - 关键指标卡：已减重、距目标、剩余天数、连续打卡天数（streak）
  - 今日状态卡：是否已打卡、今日消耗、任务完成进度
  - 体重趋势折线图（含目标虚线）与近 7 天消耗柱状图
- **历史记录**：按日期倒序查看每天的体重 / 消耗 / 任务完成情况，点击可回看并编辑。
- **设置**：体重单位切换（kg / lb，自动换算）、跟随系统外观、导出数据为 JSON（复制到剪贴板）、清空数据。

## 技术栈

| 关注点 | 选择 |
| --- | --- |
| 框架 | Flutter (Material 3) |
| 状态管理 | flutter_riverpod |
| 本地数据库 | drift + drift_flutter（跨端 SQLite） |
| 路由 | go_router |
| 图表 | fl_chart |
| 动效 | flutter_animate + Flutter 内建动画 |
| 偏好存储 | shared_preferences |

## 环境要求

- **Flutter SDK ≥ 3.35**（含 Dart ≥ 3.7；已在 Flutter 3.44 stable 上校验）。安装参考 <https://docs.flutter.dev/get-started/install>
- 目标平台工具链：
  - macOS 构建：Xcode + CocoaPods
  - Android 构建：Android SDK（Android Studio）
  - Windows 构建：Visual Studio（含「使用 C++ 的桌面开发」工作负载）
- 首次启用桌面支持：
  ```bash
  flutter config --enable-macos-desktop --enable-windows-desktop
  ```

## 快速开始

本仓库包含全部业务源码（`lib/`、`test/`、`pubspec.yaml`）。原生平台外壳（`android/`、`macos/`、`windows/`）由 `flutter create` 生成，不纳入版本库。

```bash
# 1) 进入项目目录
cd slimming-checkin

# 2) 生成各平台原生工程外壳（会保留已有的 lib/ 与 pubspec.yaml）
flutter create . --platforms=android,macos,windows \
  --project-name slimming_checkin --org com.example

# 3) 拉取依赖
flutter pub get

# 4) 生成 Drift 数据库代码（app_database.g.dart）
dart run build_runner build --delete-conflicting-outputs

# 5) 运行（任选其一）
flutter run -d macos
flutter run -d windows
flutter run -d <your-android-device-id>
```

> 说明：`app_database.g.dart` 是由 Drift 自动生成的文件，未纳入版本库。**首次运行前必须执行第 4 步**，否则会报缺少生成文件的错误。修改数据库表结构后需重新执行第 4 步（或使用 `dart run build_runner watch` 持续生成）。

## 打包发布

```bash
flutter build macos     # 产物在 build/macos/Build/Products/Release/
flutter build windows   # 产物在 build/windows/x64/runner/Release/
flutter build apk       # 或 flutter build appbundle
```

## 测试

```bash
flutter test
```

包含：
- `test/dashboard_stats_test.dart`：Dashboard 统计逻辑（进度、streak、聚合等）单元测试。
- `test/repository_test.dart`：基于内存 SQLite 的数据仓储集成测试（创建计划 / upsert 记录 / 任务勾选 / 级联删除）。
- `test/app_smoke_test.dart`：应用启动冲烟测试——无计划时的空态，以及含活跃计划时 Dashboard（概览、图表）的渲染。

> 已在 **Flutter 3.44.7 stable / Dart 3.12.2** 上验证：`dart run build_runner build` 生成成功、`flutter analyze` 零问题、`flutter test` 全部通过（9/9）。

## 项目结构

```
lib/
  main.dart                     # 入口：初始化 SharedPreferences 并注入 ProviderScope
  app.dart                      # MaterialApp.router + 主题
  core/
    theme/                      # 配色与 Material 3 主题
    router/app_router.dart      # go_router 路由与转场
    utils/                      # 日期、格式化、单位换算
    providers.dart              # 数据库/仓储/数据流/Dashboard 聚合 Provider
  data/
    database/app_database.dart  # Drift 表定义与数据库
    models/                     # DashboardStats、TaskInput 等
    repositories/               # AppRepository（所有持久化入口）
  features/
    home/                       # 自适应导航外壳（底部栏 / 侧边栏）
    dashboard/ plans/ checkin/ history/ settings/
  shared/widgets/               # 进度环、统计卡、动画数字、图表、空态等
test/
```

## 数据模型（本地 SQLite）

- `plans`：计划（名称、起止日期、起始/目标体重、是否为当前计划）
- `plan_tasks`：计划下的每日任务模板
- `daily_records`：每日记录（体重、消耗卡路里、备注），`(plan, date)` 唯一
- `task_logs`：每日各任务完成状态，`(task, date)` 唯一

删除计划会级联删除其任务与打卡记录。

## 备注

- 数据仅保存在本机，卸载应用或「清空数据」会丢失记录；可用「设置 → 导出数据」备份为 JSON。
- 默认体重单位为 kg、卡路里单位为千卡（kcal）。
