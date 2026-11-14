# Phase 5 external code review

Transport: Claude CLI. Reported model: tokenhub/deepseek-v4-flash. Review snapshot preceded final fixes.

下面是我在**只读静态审查**（未运行、未改动任何文件）下给出的独立评审意见。总体结论：**架构方向是对的，核心不变量（manifest 归属 + 内容哈希 + 只删自己且未被改动的文件）选得很准**；但生命周期职责上有一处自举死角、目标集合语义不可收缩、以及对“符号链接家目录”的硬拒绝，这三类会直接影响真实用户。以下按严重度排列，并给出最小改动建议。

---

## 一、总体判断

做得好的部分（建议保留，不要重构掉）：

- 单一 `manage.py` 同时服务 `bin/rdd` 和 `install.sh`，避免两套安装逻辑漂移。
- 只用标准库、兼容 Python 3.8，`dirs_exist_ok` 用法正确。
- 归属清单 + 内容哈希 → “只删除属于我们且未被用户修改的文件”，这是正确的保守模型。
- staging 建在 `prefix.parent`、先 rename 原目录再落位、失败逆序回滚，思路正确。
- tar 成员校验（绝对路径 / `..` / 特殊文件）、提取时过滤链接，方向正确。
- 不改 PATH、不碰 `settings.json`、legacy prefix 默认拒绝而非盲覆盖。

---

## 二、阻断 / 高优先级

### 1. 从已安装副本执行 `rdd install` 必然失败（自举死角）

`bin/rdd` 里 `install` 固定传 `--source "$rdd_root"`，而 `manage.py` 的 `--prefix` 默认就是 `~/.rdd-framework`。安装完成后 `rdd_root == prefix`，于是 `install()` 里的

> `if prefix == source ...: raise ValueError('Installation prefix and source must be separate trees')`

会直接报错。也就是说：**安装后打印出来的 `CLI: <prefix>/bin/rdd` 这个入口，其 `install` 子命令是不可用的**。用户想改 `--agent` 只能走 `rdd upgrade`（需要联网重新下载），离线无法重新配置。

建议：把“从源码装到 prefix”和“按 manifest 重新配置目标”拆成两个动作。最小改法是在 `bin/rdd` 检测 `$rdd_root/install-manifest.json` 存在时改调 `configure`（或在 `manage.py` 允许 `source == prefix` 且 manifest 合法时走“收敛”路径），`install` 继续保留“必须两棵树”的约束。

### 2. `--agent` 无法收缩目标集合，且会隐式改另一个客户端的技能

```python
targets = sorted(set(old['targets'] + selected))
```

- 先装 `both`，再 `--agent claude`，结果仍是 `both`，`~/.agents/skills` 照样被重写。
- 更糟：如果用户手工改过 codex 侧某个技能，`--agent claude` 会因为**不相干的 codex 技能冲突**而整体失败。
- 没有 `--agent` 的收缩语义，也没有“只卸 codex”的能力（`uninstall` 全删）。

建议：显式传入 `--agent` 时以它为准（未传入才沿用 manifest）；被移出集合的目标，按 `retired` 同样规则处理（未改动则删、改动则保留并告警）；`uninstall` 也接受 `--agent`。

### 3. 家目录里 `.claude` / `.agents` 是符号链接时，永远装不进去

`validate_destination()` 不区分来源，且**在 `--replace-skills` 分支之前无条件抛错**。因此用 yadm/stow/软链管理 `~/.claude` 的用户（Claude Code 用户里不罕见）会被直接挡死，且 `--replace-skills` 也救不了。

建议：解析链接后判断“真实目标是否仍在 home 之下”。在 home 内就放行并打印一次提示；指向 home 之外仍拒绝；或至少让 `--replace-skills` 成为显式承担风险的开关。顺带一提，`validate_destination` 一路扫到 `/` 偏宽（macOS 上 `/tmp`、`/var` 本身就是链接），建议只校验“授权根 → 目标”这一段。

### 4. 重复安装完全非幂等

每次 `install` 都会：整个 prefix 复制到 staging → 重命名替换 → 每个技能目录删除重建（哪怕内容一致）。后果是 `~/.claude/skills/rdd-*` 的 mtime/inode 每次全变，编辑器、文件监听、IDE 索引、以及任何硬链接都会被打断；重复执行没有“无事发生”的收敛态。

建议：对每个文件/技能目录先比较“staged 摘要 vs manifest 摘要 vs 当前磁盘摘要”，三者一致就跳过 swap。这一步同时能把 #1 的 self-install 变成天然的 no-op，改动很小、收益很大。

### 5. `--user-home` 变化时静默遗留孤儿技能

`install` 从不校验 `manifest['user_home']` 与本次 `home` 是否一致。换 home 重装后：旧 home 的技能仍在磁盘，但新 manifest 只记录新 home，**这些文件从此既不会被升级也不会被卸载**，且无任何提示。

建议：不一致时明确报错或要求 `--migrate-home`，并打印旧路径清单。

---

## 三、中优先级：正确性与健壮性

- **忽略规则不一致（macOS 上会误判“被修改”）**：`copy_tree` / `source_inventory` 忽略 `__pycache__ cache logs .keys .DS_Store`，但校验用的 `digest()` 什么都不忽略。技能目录一旦被 Finder 写入 `.DS_Store`，下次安装就会判定为 modified 并阻断，`uninstall` 也会保留。建议抽一个 `should_ignore(relpath)` 给两边共用；同时把“按目录名全局忽略 cache/logs”改成路径精确忽略，避免误删 `templates/cache/` 这类正常资产。
- **未拥有文件的策略前后不一致**：运行时文件只要内容相同就放行（`digest(dst) != digest(src)` 才报错），技能却是“只要存在且不在 manifest 就冲突”，哪怕内容完全一致。用户之前手工拷过一份同名技能就会卡住。建议统一为“内容一致即静默接管”。
- **`--replace-skills` 名不副实**：它实际同时承担“接管未拥有文件 / 覆盖已修改文件 / 迁移 legacy prefix / 保留整树备份”四种语义。错误信息 `Modified runtime file: bin/rdd; use --replace-skills for a backup` 会让用户以为只影响技能。建议改名 `--force`（保留旧名别名），并在结束时把备份路径汇总打印（现在只有逐条 `Backup preserved:`，且 `.rdd-backup-*` 兄弟目录永久堆积、无清单、无恢复入口）。
- **`--analyze` / `--plan` 是死参数**：只 `print` 一句“Plan: add missing shared RDD assets”，不做任何分析。要么实现，要么按奥卡姆删掉。
- **`--lang zh` 只影响最后一行提示**：生成的文档、`config.yml`、`CLAUDE.md` 全是英文。要么本地化生成内容，要么删掉这个参数（半吊子 i18n 比没有更伤）。
- **`install.sh --upgrade` 是空别名**：`action='install'` 而 install 本就是默认；真正的差异来自 `bin/rdd upgrade` 额外传的 `--prefix`。建议直接删掉该 flag，或让它带上明确语义。
- **`install.sh` 的 uninstall 报错误导**：卸载时若 prefix 里没有 `manage.py`，会提示 “This source/release predates Codex support. Select a release containing Phase 5…”，与实际原因（prefix 缺失/损坏）无关。
- **无并发保护**：两个 `install` 同时跑，会互相把对方刚 rename 的 prefix 再 rename 走，回滚逻辑各自为政。建议在 `prefix.parent` 下加 `flock`/`O_EXCL` 锁文件。
- **下载无完整性校验**：只做 tag 正则校验，没有 checksum/签名；`curl` 也没有 `--connect-timeout` / `--retry`。tag 来自 GitHub API 响应，属外部数据。建议发布 `SHA256SUMS` 并校验（至少 `--retry 2 --connect-timeout 10`）。
- **`uninstall` 残留**：`.rdd/cache`、`.rdd/logs`、`.rdd/worktrees` 不在 manifest 里 → 会被保留 → prefix 目录无法删除（`rmdir` 静默失败）。空的 `~/.claude/skills`、`~/.agents/skills` 也留着。建议明确“保留运行时数据”并打印剩余目录，而不是静默失败。
- **跨文件系统分支其实用不上**：staging 建在 `prefix.parent`，`runtime` 的 swap 必然同盘，却仍走 `copytree → incoming → rename`，等于把整个 prefix 多拷一遍。可以直接 `runtime.rename(prefix)`；技能跨到 home 时才需要那条安全拷贝路径。
- **`next(t for t in targets if dst.parent == ...)` 无兜底**：命中不到会抛 `StopIteration`，而 `main` 只捕获 `ValueError/OSError/KeyError`，会给用户一个裸 traceback。建议先建 `path → target` 字典。

---

## 四、设计层面（值得先对齐再改代码）

1. **技能存在两份事实来源**：`ASSETS` 里包含 `.claude/skills`，所以 prefix 内也有一份 `~/.rdd-framework/.claude/skills/**`，同时技能又被复制到 `home/.claude/skills`。前者是惰性的，只会带来双份存储和“改哪份”的歧义。建议把 `.claude/skills` 从 `ASSETS` 中移除（或明确它只是随包分发的源，并在文档里写清唯一用途）。
2. **技能识别口径不一致**：home 侧只装 `rdd-*/SKILL.md`，prefix 侧却装整个 `.claude/skills/**`。一个不符合 `SKILL.md` 布局的技能会“在 prefix 里存在、在客户端不可见”。建议统一以 `SKILL.md` 为唯一判定，并在发现不匹配时告警。
3. **`install` 与 `configure` 职责耦合**是 #1/#2 的根因。建议 manifest 里区分 `targets`（已配置）与 `available`（可配置），并新增 `rdd configure --agent ...`；`install` 只负责 prefix。
4. **prefix manifest 是单用户的**：`user_home` 写死在共享 prefix 的 manifest 里。若 prefix 被多用户共享（`/opt/rdd`），最后一个安装者会覆盖前者的技能归属记录。至少要在文档里声明 prefix 必须 per-user，或改为 `manifests/<user>.json`。
5. **`provision` 的“已存在就跳过”策略偏硬**：
   - 项目已有 `CLAUDE.md` 时，完全不会写入 RDD 指引，用户很可能以为 init 失效。建议改为**带标记的追加块**（`<!-- rdd:begin -->…<!-- rdd:end -->`），可重复执行、可幂等。
   - `.rdd/config.yml` / `Taskfile.rdd.yml` 同理：跳过意味着未来版本新增的默认键永远不会补齐。建议做一次浅合并。
   - Taskfile 测试桩替换是 **静默**的：正则不匹配就什么都不做，用户会以为“已置为待配置”，实际跑的是框架自带测试任务，可能在 Gate 3 给出假阳性。建议断言替换次数必须为 4，否则报错退出。
6. **`provision` 的资产集合需要核对**：它只拷 `.rdd/scripts`、`.rdd/hooks`、`.rdd/*.yml`，不拷顶层 `scripts/`、`templates/`、`bin/`。如果 `Taskfile.yml` 里有引用顶层 `scripts/` 或 `templates/` 的任务，`rdd init` 出来的项目会在运行时缺文件。这一点我无法在不看 Taskfile 的情况下确认，建议加一条“provision 后跑 `task --list` 冒烟”的测试。
7. **`init` 不校验技能是否已安装**：`rdd init` 能成功，但 `/rdd-help` 可能并不存在（用户只 init 没 install）。建议 `init` 末尾做一次探测并提示。

---

## 五、附带的两个运行时脚本

`subagent-scheduler.sh` / `worktree-pool.sh` 会被打进 prefix 并 provision，属于“统一运行时”的一部分，但当前状态更像占位：

- **`parallel` 并不并行**：`execute_stage` 是前台同步写 trigger，`wait` 时没有后台作业；日志却说 “Parallel execution plan”。
- **`sequential` 只处理第一个 stage 就 `return 0`**，后续 stage 永远不会被排队（注释说明是故意的，但命令名和 usage 没体现）。
- **worktree 只分配不释放**：两条路径都不调用 `release`，`MAX_PARALLEL=3` 很快被占满；`git worktree remove` 后也不删 `rdd/stage-<id>-<ts>` 分支，分支长期堆积。
- **用 grep/sed 解析 JSON**（`active_count`、`existing_path`、`list_worktrees`），stage id 含非数字或正则元字符就会误判甚至命令注入；文件写入已经用 python 了，读取也统一用 python 更省事。
- **`max_parallel` 双源**：`init_pool` 永远写死 3，env 变量只改 shell 变量，`pool.json` 里的字段从不被读取。
- **`SCHEDULER_STATE` 是死状态**：`status` 会 `cat` 它，但没有任何代码写过它。
- **`PROJECT_ROOT` 从脚本位置推两层**：在 prefix 里运行时得到的是 `~/.rdd-framework`，会在框架目录下建 worktree。项目内副本因为 provision 过所以是对的——但这属于“靠部署位置兜底”，建议显式传 `PROJECT_ROOT` 或加 `git rev-parse --show-toplevel`。
- **无 flock**：`allocate` 的“计数—创建”是典型竞态。

---

## 六、建议补的测试（都是能直接证明上述问题的）

1. 已安装副本上执行 `rdd install`（期望：成功收敛，而非 “separate trees”）。
2. `both` → `--agent claude`（期望：codex 技能被正确移除或明确保留，且不因 codex 侧改动而失败）。
3. `~/.claude` 为符号链接（指向 home 内 / 指向 home 外两组）。
4. 连续两次 `install`，第二次不改变任何文件的 inode/mtime。
5. `install` → `uninstall` 后 prefix 与两个 skills 根是否干净，以及有 `.rdd/cache` 时的行为。
6. 安装中途 `SIGKILL`，验证 prefix / 技能均回到旧状态、无 `.rdd-incoming-*` 残留。
7. 技能目录里放一个 `.DS_Store`，验证不会被判定为 modified。
8. 篡改 manifest（`../`、绝对路径、非 `rdd-` 技能名），验证被拒且不产生任何写入。
9. 两个并发 `install` 的互斥性。
10. `rdd init` 到已有 `CLAUDE.md` / `Taskfile.yml` 的项目，验证标记块追加与任务桩替换的**断言**（而非静默）。

---

## 七、如果只改三处

1. **幂等收敛 + 允许 `source == prefix` 的 reconfigure 路径** —— 一次性解决 #1、#4，并让“重新配置”变成零风险操作。
2. **让 `--agent` 成为权威目标集合（含收缩与卸载侧对称支持）** —— 解决 #2，同时消除“改 A 客户端因 B 客户端冲突而失败”的荒谬路径。
3. **符号链接目标改为“解析后判定是否在授权根内”** —— 解除对 dotfiles 用户的硬阻断，同时保留越界拒绝。

---

## 八、我可能判断错的点（请确认，我没有读 Taskfile 与 tests）

- `Taskfile.yml` 是否引用顶层 `scripts/` / `templates/`，决定第四节第 6 条是真实缺陷还是我多虑。
- 仓库里 `.agents/` 是权威内容还是生成镜像；若是权威内容，`ASSETS` 不含它会导致 codex 侧来源漂移。
- `bin/rdd upgrade` 在**源码检出**中运行：目前靠“无 manifest 则拒绝”这条副作用挡住了覆盖检出；但如果开发者曾在该检出里用 `--replace-skills` 安装过，这层保护就失效了，未改动的受版本控制文件会被发布包内容替换。请确认这是否可接受，或显式禁止在 `.git` 存在的 prefix 上 install。
- 是否有意不支持“只卸某一个客户端”——若不是，第 2 条建议的优先级还应上调。