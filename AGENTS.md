# AGENTS.md · encountering 项目上下文（给 AI 协作者）

> 读这份文件就能获得整个系统的全貌。改代码前先看「部署流程」和「坑」两节。
> **本仓库是唯一代码源**，所有改动都在 `yu/` 或 `wall/` 里进行。

## 一句话

活动工具：手机 PWA 做「话题卡」→ 推 Supabase → 大屏 5 秒内弹出并汇入滚动照片墙。多活动复用，`?e=slug` 隔离数据。

## 架构

```
手机浏览器                Cloudflare                  Supabase 免费项目
┌─────────────┐    ┌──────────────────────┐    ┌────────────────────┐
│ yu/ 上传页   │──▶ │ mufriends.mushenzhen │──▶ │ Postgres:          │
│ (PWA 话题卡) │    │ .xyz/proxy/* 反代     │    │  · events 表       │
└─────────────┘    │  (国内直连 supabase   │    │  · photos 表       │
┌─────────────┐    │   .co 不稳，故反代)   │    │ Storage:           │
│ wall/ 大屏   │──▶ │                      │    │  · photos 桶(公开) │
│ (滚动照片墙) │    │ 静态托管大屏本身      │    └────────────────────┘
└─────────────┘    └──────────────────────┘
```

- 两端都是**纯静态、无构建、无框架**。上传页是 cache-first PWA（现场没网是常态）
- 轮询而非实时订阅：大屏每 5 秒拉一次新照片（简单可靠，量小）
- 匿名读写：anon key 公开在客户端，RLS 放开。社区活动无机密数据，这是有意取舍

## 仓库结构

```
yu/      上传页 PWA：index.html / app.js / card.js / config.js / sw.js / manifest.webmanifest / assets/
wall/    大屏：index.html / app.js / config.js / logo-data.js / server.js / worker.js / wrangler.toml
         / export-photos.py / upload-snippet.js / vendor/ / assets/
sql/     建库与迁移脚本
```

部署镜像（**只读，不直接改**）：

| 镜像 | 内容 | 触发什么 |
|------|------|----------|
| xiaoyug/yu | `yu/` 的子树 | push → GitHub Pages 上线 xiaoyug.github.io/yu |
| xiaoyug/mufriends-wall | `wall/` 的子树 | push → 备用站；正式站另需 wrangler deploy |

## 部署流程（关键）

### 改上传页（yu/）

1. 改代码后**必须 bump `yu/sw.js` 里的 CACHE 版本号**（如 `yu-v15-xxx`），否则用户端旧缓存不更新
2. 同步到部署镜像：
   ```bash
   SHA=$(git subtree split --prefix=yu main)
   git push git@github.com:xiaoyug/yu.git $SHA:main --force
   ```
   （公开镜像历史不连续是常态，必须 force）
3. 用户端是 cache-first PWA：新版要**连开两次**页面才生效；页脚有版本号（当前 v6），让用户报版本号排查

### 改大屏（wall/）

1. 本地预览：`node wall/server.js`（默认 7100 端口）
2. 备用站：`git subtree split --prefix=wall main` → force push 到 xiaoyug/mufriends-wall
3. **正式站必须另跑**：`cd wall && npx wrangler deploy`（wrangler.toml 已绑定 mufriends.mushenzhen.xyz 自定义域）

### Supabase

- anon key：`sb_publishable_TeAH2DCcPXl2e-MVtwyPOQ_kIEQ79YB`（公开可写，见架构节）
- 两端配置走 `https://mufriends.mushenzhen.xyz/proxy` 反代（通用透传，新增表自动可用）
- **免费版闲置约 7 天自动暂停**：暂停后 DNS NXDOMAIN、反代 530。数据不丢，Dashboard 点 Resume project 恢复
- 表结构变更：SQL Editor 执行 `sql/` 下脚本

## 多活动机制

- 大屏 URL `?e=slug` 进活动页；slug 不存在时自动在 events 表建档（name=slug、date=当天本地日期）
- 不带参数的根地址是活动索引页
- 大屏右下角二维码自动拼接 `?e=slug`，观众扫码直达对应活动的上传页
- 上传页读 `?e=`：从 events 表预填活动名/日期；推上墙时先 upsert events 再插 photos（带 event 字段）；无参数时按「活动名-日期」slug 化兜底（保 CJK）
- 大屏按 M 进管理模式：删照片（软删除 deleted=true）+ 编辑活动信息

## 坑（都踩过）

1. **wrangler deploy 和 git push 是两回事**——只 push 不 deploy，正式站不会变
2. **改 yu 不 bump sw.js 版本号 = 用户端看不到改动**；排查先说「连开两次」
3. **github.com 直连在国内夜间会大面积超时**，但 api.github.com 正常——可用 GitHub API（push_files）应急推送文本文件；含图片等二进制时只能等网络恢复走 git
4. **localhost:7100 可能被本机其他 dev server 占用**（IPv6 ::1 优先），验证时用 127.0.0.1:7100
5. Cloudflare 对脚本 UA 会 403——curl 验证带浏览器 UA
6. wrangler.toml 的 compatibility_date 不能填 UTC「未来」日期
7. 自动建档日期**不要用 toISOString()**（UTC 会差一天），用本地日期拼接
8. Supabase 暂停恢复后，PostgREST schema cache 可能需几秒刷新，PGRST205 稍等重试

## 现场运维速查

| 情况 | 处理 |
|------|------|
| 大屏照片没了 / fail to load | 八成是 Supabase 暂停 → Dashboard Resume；其次看左下角状态灯（红=连接异常） |
| 上传报 fetch error | 查手机网络能否打开 mufriends.mushenzhen.xyz；备用方案扫 github.io 的二维码 |
| 要删乱传的照片 | 大屏按 M → 点照片 ✕ |
| 要删测试活动 | Supabase Dashboard → Table Editor → events 表删行（大屏暂无删活动 UI） |
| 导出照片 | `cd wall && python3 export-photos.py --event <slug>` |

## 联系人

Owner: Sunny（xiaoyug）· mu 深圳社区
