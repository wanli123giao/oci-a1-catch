# oci-a1-catch — 双账户双区域 A1 抢机系统

7×24 自动抢占 Oracle Always Free A1 实例（两账户独立配额 2核/12G/150G 各一台）。

## 架构

```
LaunchAgent 心跳(每10min) ─┐
GitHub cron(*/5+错峰) ────┴─> 两个 workflow ─> hitrov 抢机 ─> 状态推送
                                catch-chicago.yml  (wanli123xiao / us-chicago-1)
                                catch-phoenix.yml  (wanli123giao / us-phoenix-1)
状态推送(deploy key) ─> 公开仓 a1-hunter-status ─> 仪表盘 https://a1-hunter.pages.dev
成功时: 自停表 + 邮件(SMTP secrets) + GitHub issue 兜底通知
```

## 仪表盘

- 地址：https://a1-hunter.pages.dev （自定义域 hunter.wanli.uk 待 CNAME：`hunter -> a1-hunter.pages.dev`，开小云朵）
- 数据延迟：raw CDN 约 1-5 分钟，正常
- 状态灯：黄=蹲守中(无容量/429) 红=未知错误 绿=已捕获

## 日常运维

```bash
# 查看火力
gh run list -R wanli123giao/oci-a1-catch --limit 10

# 手动补一发
gh workflow run catch-chicago.yml -R wanli123giao/oci-a1-catch
gh workflow run catch-phoenix.yml -R wanli123giao/oci-a1-catch

# 本机心跳(每10分钟自动踢两发)
launchctl print gui/$(id -u)/com.wanli.a1hunter.kicker | grep state
tail /tmp/a1hunter-kicker.log

# 停某区猎手(中签后自动停，无需手动)
gh workflow disable catch-phoenix.yml -R wanli123giao/oci-a1-catch
# 重启
gh workflow enable catch-chicago.yml -R wanli123giao/oci-a1-catch

# 中签后拿 IP 并登录（替换 <IID>，仪表盘横幅有现成命令）
oci compute instance list-vnics --instance-id <IID> --query 'data[0]."public-ip"' --raw-output
ssh -i ~/Downloads/oci_chi_a1 ubuntu@<IP>
# 凤凰城账户加 --profile PHX
```

## 邮件通知（待配置 SMTP secrets 后生效）

```bash
gh secret set SMTP_HOST -b smtp.qq.com -R wanli123giao/oci-a1-catch   # 或 smtp.163.com / smtp.gmail.com
gh secret set SMTP_PORT -b 465 -R wanli123giao/oci-a1-catch
gh secret set SMTP_USER -b "你的邮箱" -R wanli123giao/oci-a1-catch
gh secret set SMTP_PASS -b "SMTP授权码(非登录密码)" -R wanli123giao/oci-a1-catch
gh secret set SMTP_TO   -b "收件邮箱" -R wanli123giao/oci-a1-catch
```

## 退役清理

1. `gh workflow disable` 两个 workflow；`launchctl bootout gui/$(id -u)/com.wanli.a1hunter.kicker`
2. 删 secret gist（API 私钥）：gh gist delete 717b78f1b34b9d547045b2704a1cc91d
3. 两个账户控制台各删 API 密钥（指纹 14:c1:03:bb…）并换新
4. 删两个仓库 + LaunchAgent plist + ~/.ssh/a1_status_deploy*

## 凭证分布（安全面）

| 凭证 | 位置 | 权限面 |
|---|---|---|
| OCI API 私钥 | secret gist (仅 URL 可达) + 本机 ~/.oci | 双账户 API（共用一把，退役时双账户同轮换） |
| OCI 各项 OCID/参数 | 本仓 Actions Secrets | 仅 Actions 运行时注入 |
| 状态仓 deploy key | 本仓 Secret + 本机 ~/.ssh | 仅 a1-hunter-status 单仓写 |
| SMTP 授权码 | 本仓 Secrets | 仅发信 |

公开面（a1-hunter-status 仓库、Pages 仪表盘）：零凭证，仅状态与日志尾（OCID 属内部标识符，无凭证不可利用）。

## 已知特性

- GitHub 定时调度高峰延迟可达数十分钟；本机心跳是保底火力，Mac 睡眠时仅靠 cron
- 凤凰城是全球最挤区域，蹲守数天属正常；芝加哥通常更快
- 两 workflow 各自 concurrency 组防重叠；hitrov 自带 OCI_MAX_INSTANCES 查重，不会双开实例
- 本仓已转公开（Actions 分钟数无限）；敏感值全部在 Secrets，日志自动掩码
