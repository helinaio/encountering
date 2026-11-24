# encountering · 遇

活动现场相识系统：扫码做一张「话题卡」，一键推上大屏幕滚动照片墙。
多场活动可复用，按活动隔离数据。**本仓库是唯一代码源**（single source of truth）。

## 目录结构

```
yu/      遇 · 上传页（手机 PWA，做话题卡、推上墙）
wall/    Paper Wall · 大屏页（多行滚动照片墙 + 新照片弹窗）
sql/     Supabase 建库与迁移脚本
```

## 线上地址

| 模块 | 地址 | 部署来源 |
|------|------|----------|
| 遇（上传页） | https://xiaoyug.github.io/yu/ | 本仓库 `yu/` 同步到 [xiaoyug/yu](https://github.com/xiaoyug/yu) → GitHub Pages |
| Paper Wall 正式站（国内可访问） | https://mufriends.mushenzhen.xyz/ | 本仓库 `wall/` 本地 `npx wrangler deploy` → Cloudflare |
| Paper Wall 备用站 | https://xiaoyug.github.io/mufriends-wall/ | 本仓库 `wall/` 同步到 [xiaoyug/mufriends-wall](https://github.com/xiaoyug/mufriends-wall) → GitHub Pages |
| 云端 | Supabase 项目 `kqttuewfmvuuohvqbhel` | `sql/` 脚本建库 |

> 同步用 `git subtree split` 把子目录推到部署仓库（见 AGENTS.md「部署流程」），
> yu 和 mufriends-wall 两个仓库是**只读镜像，不要直接改**。

## 三分钟上手（开一场新活动）

1. 大屏打开 `https://mufriends.mushenzhen.xyz/?e=活动代号`（如 `?e=mu-meetup-01`）——首次访问自动建档
2. 按 `M` 进管理模式，填活动名称 / 日期 / 标语，保存
3. 把大屏投屏，右下角二维码自动带活动参数；观众扫码做卡、点「① 推上照片墙」即可上墙
4. 根地址 `https://mufriends.mushenzhen.xyz/` 是所有活动的索引页

## 活动后导出照片

```bash
cd wall
python3 export-photos.py --event 活动代号    # 按活动导出
python3 export-photos.py --live              # 只导出未被删除的
```

导出 `./export/` 目录：编号照片 + `index.csv`（昵称 / 留言 / 活动 / 时间）。

## 数据约定（两端共用，不要改字段名）

- 表 `events`：`slug`（主键）/ `name` / `date` / `slogan` / `created_at`
- 表 `photos`：`id` / `nickname` / `message` / `photo_url` / `event`（= events.slug）/ `deleted`（软删除）/ `created_at`
- 存储桶 `photos`：公开读，匿名可写（社区活动场景，接受的取舍）
- 两端都不直连 supabase.co，走 Cloudflare Worker 反代 `https://mufriends.mushenzhen.xyz/proxy`（国内稳定性）

## 文档

- [AGENTS.md](AGENTS.md) — 给 AI 协作者的项目上下文（架构、部署流程、坑）
- [yu/README.md](yu/README.md) — 上传页说明
- [wall/README-wall.md](wall/README-wall.md) — 大屏说明
- [sql/supabase-setup.sql](sql/supabase-setup.sql) — 从零建库
- [sql/supabase-events-migration.sql](sql/supabase-events-migration.sql) — 多活动化迁移

## 协作

- 需求 / bug → 本仓库 Issues
- 改代码 → 直接在本仓库 `yu/` 或 `wall/` 提 PR
- 设计基调：mu 深圳海报风——白底、黑描边、硬投影、拍立得贴纸卡片、等宽字体胶囊
