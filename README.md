# encountering · 遇

活动现场相识系统：扫码做一张「话题卡」，一键推上大屏幕滚动照片墙。
两场以上活动可复用，按活动隔离数据。

## 系统组成

| 模块 | 是什么 | 代码仓库 | 线上地址 |
|------|--------|----------|----------|
| 遇（上传页） | 手机端 PWA，做话题卡、推上墙 | [xiaoyug/yu](https://github.com/xiaoyug/yu) | https://xiaoyug.github.io/yu/ |
| Paper Wall（大屏） | 多行滚动照片墙 + 新照片弹窗 | [xiaoyug/mufriends-wall](https://github.com/xiaoyug/mufriends-wall) | https://mufriends.mushenzhen.xyz/（正式，国内可访问）· https://xiaoyug.github.io/mufriends-wall/（备用） |
| 云端 | Supabase 免费项目（Postgres + 对象存储） | 本仓库 `sql/` 有建库脚本 | 项目 ref：`kqttuewfmvuuohvqbhel` |

本仓库是**协作枢纽**：项目上下文、数据约定、部署手册、SQL 脚本都在这里。
代码改动请直接去对应代码仓库提 PR；需求讨论用本仓库 Issues。

## 三分钟上手（开一场新活动）

1. 大屏打开 `https://mufriends.mushenzhen.xyz/?e=活动代号`（如 `?e=mu-meetup-01`）——首次访问自动建档
2. 按 `M` 进管理模式，填活动名称 / 日期 / 标语，保存
3. 把大屏投屏，右下角二维码自动带活动参数；观众扫码做卡、点「① 推上照片墙」即可上墙
4. 根地址 `https://mufriends.mushenzhen.xyz/` 是所有活动的索引页

## 活动后导出照片

```bash
# 在 mufriends-wall 仓库目录下
python3 export-photos.py --event 活动代号    # 按活动导出
python3 export-photos.py --live              # 只导出未被删除的
```

导出 `./export/` 目录：编号照片 + `index.csv`（昵称 / 留言 / 活动 / 时间）。

## 数据约定（两端共用，不要改字段名）

- 表 `events`：`slug`（主键）/ `name` / `date` / `slogan` / `created_at`
- 表 `photos`：`id` / `nickname` / `message` / `photo_url` / `event`（= events.slug）/ `deleted`（软删除）/ `created_at`
- 存储桶 `photos`：公开读，匿名可写（社区活动场景，接受的取舍）
- 大屏/上传页都不直连 supabase.co，走 Cloudflare Worker 反代 `https://mufriends.mushenzhen.xyz/proxy`（国内稳定性）

## 文档

- [AGENTS.md](AGENTS.md) — 给 AI 协作者的项目上下文（架构、部署流程、坑）
- [sql/supabase-setup.sql](sql/supabase-setup.sql) — 从零建库（photos 表 + 存储桶 + 权限）
- [sql/supabase-events-migration.sql](sql/supabase-events-migration.sql) — 多活动化迁移（events 表 + photos.event 字段）

## 协作

- 需求 /  bug → 本仓库 Issues
- 上传页代码 → xiaoyug/yu 提 PR
- 大屏代码 → xiaoyug/mufriends-wall 提 PR
- 设计基调：mu 深圳海报风——白底、黑描边、硬投影、拍立得贴纸卡片、等宽字体胶囊
