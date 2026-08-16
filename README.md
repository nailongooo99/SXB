# 时薪宝（SXB）

本地隐私优先的 SwiftUI iOS 工时与实时收入追踪 App。

## 当前实现

- 月薪制 / 时薪制配置
- 每日工时、每月工作天数、午休时长配置
- 每秒刷新今日收入与赚钱速度
- 上下班打卡、休息时间扣除
- 历史记录编辑与删除
- 今日、本周、本月、全部统计
- 金额一键隐藏
- Core Data 本地保存工时记录
- GitHub Actions macOS 构建未签名 IPA

## 数据隐私

薪资配置只保存于 `UserDefaults`，工时记录只保存于本地 Core Data，不使用 CloudKit、网络服务器或第三方依赖。

## 工程结构

- `TimeWageApp/Models/`：薪资配置与 Core Data 实体
- `TimeWageApp/Services/`：工时记录持久化服务
- `TimeWageApp/ViewModels/`：实时计时状态
- `TimeWageApp/ContentView.swift`：SwiftUI 页面与导航
- `.github/workflows/ios-unsigned-ipa.yml`：GitHub Actions 构建流程

最低部署目标：iOS 16.1。
