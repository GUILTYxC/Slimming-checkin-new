---
feature: app-optimization
status: delivered
updated: 2026-09-10
branch: main
commits: 61b642d..abb7cb7
---

# 全面优化：性能体验 + 逻辑正确性

## Report

**What was built** — 在 main 工作树上落地一揽子可安全合并的性能与正确性修复。主壳改为 `IndexedStack` 四 Tab 保活，列表入场动画改为 `FadeInOnce` 仅首播；`AppRepository` 的记录/任务 upsert 改为按唯一键的 `DoUpdate` 原子写；`DashboardStats.goalReached` 支持增重/减重双向；历史页与概览共用 `computeStreak`；日期工具改为 UTC 日历日运算（DST-safe）；日期选择器跟随暗色；不可点玻璃跳过按压动画壳，图表包 `RepaintBoundary` 并按 tab 加 key 以保留分段切换动画。

**Verification** — `flutter analyze` → PASS（No issues found）；`flutter test` → PASS（16/16）。独立 review 发现 Major（无 key 的 RepaintBoundary 抑制 AnimatedSwitcher）后已修复并复跑。

**Journey log**
1. Drift 的 `insertOnConflictUpdate` 只对主键 `id` 生效，不覆盖 `(planId,date)` 唯一键；改用 `insert(..., onConflict: DoUpdate(..., target: [...]))`。
2. 将 `RepaintBoundary` 包在 `AnimatedSwitcher` 子节点外且不加 key，会导致 `canUpdate` 判定为同一节点、切换动画消失；边界须带 `ValueKey(tab)`。
3. `charts.dart` 内部改写括号层级容易踩坑，重绘边界放在调用方更安全。
4. 玻璃无按压时的静态路径可接受“抬起瞬间 material 不缓动”（几何仍有 AnimatedScale）。

## [S1] Problem

自用型减重打卡应用已可日常使用，但存在若干可安全落地的体验与正确性问题：

1. **主 Tab 切换丢状态**：`HomeShell` 用 `AnimatedSwitcher` 重建页面，滚动位置与页内临时状态丢失，列表入场动画每次切回都重播。
2. **upsert 非原子**：`upsertRecord` / `setTaskCompletion` 先 select 再 insert/update，未包事务，依赖唯一约束却不用冲突更新。
3. **目标方向假定减重**：`goalReached` 使用 `currentWeight <= target`，增重计划（target > start）会在未达标时被判定为已达标。
4. **历史页与概览 streak 口径不一致**：概览统计 records+completed logs、含今日宽限；历史页只算 records、从最新记录回溯，同一数据两处数字可能不同。
5. **日期选择器硬编码亮色**：`ColorScheme.light` 在暗色模式下违和。
6. **玻璃按压动画常开**：每个 `GlassSurface`（含不可点卡片）都包一层 `TweenAnimationBuilder`，按下时每帧新建 `ImageFilter`。
7. **图表无重绘边界**：折线/柱状图在兄弟节点重建时连带重绘。
8. **日期差用 `Duration.inDays`**：在观察夏令时的时区，本地午夜差 23 小时会得到 0 天，影响 `daysBetween` 与 streak 步进（中国时区无 DST，属防御性修复）。

## [S2] Design

### Tab 保活（性能/交互）

- `HomeShell` 改为 `IndexedStack` 四页常驻，保留各页 `ScrollController` 与本地状态。
- 入场动画（dashboard / plans / history）仅在**首次**构建时播放；保活后切回不再重播。
- 实现：共享 `FadeInOnce`（`lib/shared/widgets/fade_in_once.dart`）。

### 原子 upsert（数据）

- `AppRepository.upsertRecord` / `setTaskCompletion`：Drift `insert` + `DoUpdate`，冲突目标为业务唯一键 `(planId, date)` / `(taskId, date)`（不是自增主键）。
- 保留 `dateOnly` 归一化后再写入。

### 目标方向与进度（逻辑）

- `DashboardStats`：
  - `bool get isLosingWeight => plan.startWeight >= plan.targetWeight;`
  - `goalReached`：减重 `current <= target`；增重 `current >= target`。
  - `progress`：保持 0..1 clamp；增重路径有单测。
  - 不改 `remainingKg` 的现有减重语义。

### 统一 streak（逻辑）

- 抽 `DashboardStats.computeStreak(checkInDates, today)`；历史页与概览共用。
- 规则：check-in 日 = 有 daily record **或** 有 completed task log；今日未打卡则从昨日起算（一日宽限）。

### 日期工具 DST-safe（逻辑）

- `AppDate.daysBetween`：UTC 日历日差。
- `AppDate.addDays(date, n)`：UTC 日历日加减。
- streak 回溯、近 7 天窗口、计划默认结束日均用 `addDays`。

### 日期选择器暗色（交互）

- `history_page` / `plan_form_page` 使用 `ColorScheme.fromSeed` + 当前 brightness。

### 玻璃与图表微优化（性能）

- `GlassSurface`：`pressed == false` 时跳过 `TweenAnimationBuilder` 静态路径。
- 趋势图 `RepaintBoundary` + `ValueKey(_tab)`，保证分段切换动画仍在。

### 测试边界

- 单测：增重 `goalReached`/`progress`；`daysBetween`/`addDays`；`computeStreak` 宽限与断档；repository upsert 幂等。
- 现有 smoke 金测保持通过。

## [S3] Out of Scope

- JSON 导入/恢复、多用户、云同步。
- 拆分 500+ 行页面文件、CI、Windows 构建验证。
- 增重计划的文案/标签全面适配（仅修判定逻辑）。
- 任务中途增删对 `totalTaskExpected` 的历史回溯修正。
- 清理根目录 apk/log 等仓库卫生问题（不阻塞功能）。

## Tasks

- [x] T1: HomeShell 改 IndexedStack 保活 — acceptance: 切换四 Tab 后滚动位置与状态保留；切回不重建子树 (covers: S2)
- [x] T2: 列表页入场动画仅首播 — acceptance: 切到历史/计划再切回，卡片不再逐个 fadeIn 重播 (covers: S2; depends: T1)
- [x] T3: AppDate DST-safe daysBetween/addDays — acceptance: daysBetween 使用 UTC 日历日；单测覆盖 (covers: S2)
- [x] T4: DashboardStats goalReached 支持增重方向 — acceptance: start=60,target=70,current=65 时 goalReached=false；current=70 时为 true (covers: S2)
- [x] T5: Repository 原子 upsertRecord / setTaskCompletion — acceptance: 同键二次写仍单行；代码路径为 insertOnConflictUpdate 或等价事务 (covers: S2)
- [x] T6: 统一 streak 计算 — acceptance: 历史摘要与概览 streak 同源；有 completed log 无 record 的日计入 streak (covers: S2)
- [x] T7: 日期选择器跟随暗色 — acceptance: 暗色模式下 picker 不强制 ColorScheme.light (covers: S2)
- [x] T8: GlassSurface 无按压时跳过动画壳 + 图表 RepaintBoundary — acceptance: 不可点 AppCard 仍正常渲染；图表组件包 RepaintBoundary (covers: S2)
- [x] T9: 补/调单测并 `flutter analyze` + `flutter test` 全绿 — acceptance: 分析零 issue，测试全部通过 (covers: S2; depends: T3,T4,T5,T6)
