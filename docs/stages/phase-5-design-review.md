# Phase 5 external design review

Transport: Claude CLI; reported model: tokenhub/deepseek-v4-flash (not inferred from client name).

以同事视角读完了三份设计。**方向是对的**（共享 runtime + 共享 skill 源 + 宿主入口分离，确实是唯一不需要维护两份实现的路子），但设计里有几处会在 Gate 3/5 直接把 Stage 卡死的问题，还有一处是"整件事成立与否"的前提完全没被验证就排到最后才做。

下面按优先级说。

---

## 阻塞项（不改就无法通过 Gate）

### B1. 最重要的前提假设没写在 Hypothesis 里，而且排在最后验证

三份设计的 Hypothesis 都是"A shared skill/runtime source plus explicit host entry points can provide equivalent RDD workflows"。但真正未被验证的前提是更下面那一层：

- Codex 是否真的把 `~/.agents/skills` 当作**用户级** skill 目录？
- Skill 的 invocation 名称取自**目录名**还是 frontmatter 的 `name`？（两边取的源不同 → 调用名静默不一致）
- Codex 的 loader 对 Claude Code 现有 frontmatter（`name`/`description`/`allowed-tools` 等）是忽略、报错还是必需？
- 用户级 `~/.agents/skills` 与项目级 `.agents/skills` 同时存在时的优先级？

这些如果其中一个答案是否定的，"共享 SKILL.md" 这个前提就垮了，需要退化成"生成薄适配层"。而现在它们被推到了 Stage 25 的"when credentials and client capabilities allow"——那是**最后的、可选的、可能拿不到的证据**。

**建议**：在 Stage 23 的 Gate 1 里加一项"host capability probe"，产出物是**记录在 review-log 里的证据**（版本号、目录约定、frontmatter 容忍度、调用名来源、优先级），而不是代码。设计文档里现在就写上：若探测结果与假设不符，回退方案是什么（我倾向：canonical 源里 SKILL.md 保持最小公共 frontmatter，宿主特化部分放进各自的 adapter 文件）。另外 `~/.agents/skills` 这个路径请在文档里给出处（Codex 文档/官方约定），别让它以"显然如此"的姿态出现。

### B2. 缺 install manifest —— 所有权、升级、卸载、双 agent 全都不可判定

设计反复出现五个断言：

> "does not erase unrelated skills" / "removes only owned RDD assets" / "Upgrade preserves the selected agent target" / "explicit replacement backs them up" / "rruns are idempotent"

但**没有任何机制记录"哪些资产是 RDD 拥有的"**。没有 manifest，卸载只能靠目录名猜，升级无法判断用户是否改过，`--agent claude` 之后再来 `--agent both` 再卸载就更说不清了。

**建议**：Stage 23 里显式定义一个 manifest（如 `~/.rdd-framework/install-manifest.json`），字段至少：`version`、`source`(checkout/archive/npm)、`targets[]`、每个资产的 `path` + `contentHash` + `owner`。这是三个 Stage 共享的**接口契约**，应写在设计里而不是留给实现自由发挥。有了 hash，升级的三种状态才是可判定的：未改动→覆盖；用户改过→备份 `.bak` + 警告；缺失→重装。顺便：**collision 检查必须在任何写入之前全量完成**（现在只对 "invalid target" 承诺了 fail-before-mutation）。

### B3. 引用解析契约缺失 —— 这是最可能静默坏掉的地方

Stage 24 说"Replace internal `.claude/skills` references with relative sibling references"。兄弟目录之间的相对引用没问题，但 skill 还会引用：

- runtime CLI（`rdd`）、templates、Taskfile —— 这些**不是** siblings；
- 仓库内的 `docs/stages/`、`templates/` 之类项目相对路径 —— 装到 `~/.claude/skills` 后根本没有仓库。

现在没有任何地方规定"一个 skill 允许引用什么"。结果会是：在仓库里跑得好好的，装上就坏，而且坏得很安静。

**建议**：写死三条规则（allowed references），并且配一个**静态 lint 测试**：扫描安装后的 17 个 skill，命中 `.claude/skills` 字面量、绝对路径、仓库根相对路径就 fail。这个测试成本极低、收益极高，比 Stage 25 里"verify sibling reference resolution"这句散文有用得多。

### B4. 三个 Stage 的 Hypothesis / Verification / Non-goals 逐字相同 → Gate 5 无法验伪

这不是排版问题。RDD 的模型是"每个 Stage 证伪一个假设"，而现在是**一个假设、三段工作量**被切成三个 Stage。直接后果：

- Stage 23 的 Gate 5 "hypothesis evidence" 要么空洞，要么只是 Stage 25 的部分证据；
- 三份 Verification 段落完全一样，Gate 3 的评审会为"这个测试归谁"吵架；
- E2E 重复：23 要求 "two real E2E paths"，25 又要 codex-only + both + rerun + upgrade + uninstall，"Run the tests again from a clean copied source"。

**建议**：Roadmap 上放一个总假设，每个 Stage 一个**可独立证伪的子命题**，例如：
- 23：单一安装器可在不复制资产的前提下同时服务两个宿主（可证伪点：两套目录需要不同内容，或 manifest 不足以支撑卸载）；
- 24：17 个 skill 的引用可以被改成宿主中立（可证伪点：某些 skill 本质上依赖 Claude 专属机制）；
- 25：文件级一致性足以预测工作流可用性 ← **这条本身就该被质疑**，见 P1-7。

Verification 段落要改成互不重叠：23 只验安装器机械行为；24 只验资产集合与引用解析（静态 + init）；25 只验端到端矩阵 + 文档 + 真机 smoke。

### B5. "覆盖率必须度量执行代码" 与 shell 安装器结构性冲突

Stage 25 写："Coverage evidence must measure executed code, not test-count estimates. Gate 3 remains open if measurement ... cannot be obtained."

Shell 安装器基本无法做行覆盖率。如果实现主体是 Node/TS 的 runtime CLI（看起来是），那覆盖率只能覆盖它，shell 那层怎么算？设计没说，结果是 Gate 3 **永久开着**，或者实现者临场找一个自欺欺人的方案。

**建议**：在设计里明确切分——"覆盖率度量对象 = runtime CLI 的 TS/JS 实现；shell 入口被限定为薄封装，仅由 E2E 矩阵覆盖；薄封装的判定标准是 ≤N 行且不含业务分支"。顺带说一句：对安装器来说 20% 这个数字几乎是装饰，真正的质量门槛是 E2E 矩阵，别让覆盖率数字给人虚假的安全感。

---

## 重要建议（不阻塞，但会返工）

**P1-1｜Stage 顺序建议调整。** 24 的"引用中立化"是对 17 个 skill 的机械重构（注意最近的 commit `d2ecce7 convert RDD skills to Claude Code directory format` 说明它们现在是宿主专属的），风险最高、最底层。如果这件事做不成，23 的安装器设计就没有意义。建议 24 的资产/引用工作先行或至少与 23 并行推进，23 的安装器对着"已中立化"的源做。

**P1-2｜绝对不要去改用户的 `Taskfile.yml` 和 `CLAUDE.md`。** 设计说"Never overwrite existing user entry points or Taskfile during migration"，但 `rdd init` 又必须让 Task 入口可用——中间那步"合并 YAML"就是经典脚坑。Occam 的答案：**根本不合并**。生成 `Taskfile.rdd.yml`，让用户 include 一行（go-task 原生支持）；CLAUDE.md 同理，用 `<!-- rdd:begin --> / <!-- rdd:end -->` 标记块做幂等 append。缺失 include 时打印确切片段并要求用户确认，不代改。

**P1-3｜CLAUDE.md / AGENTS.md 的桥方向被反转了，有迁移风险。** 设计是"Generate AGENTS.md for both + CLAUDE.md bridge"，即 AGENTS.md 为 canonical。但当前仓库恰好相反：`CLAUDE.md` 是主入口且内容相当 Claude 专属，`AGENTS.md` 才是 general rules。老用户机器上已有的 CLAUDE.md 不会被覆盖（按设计），于是他们**永远看不到那个 bridge**，AGENTS.md 白生成。要么在 init 里检测并显式提示/写入标记块，要么在 CHANGELOG 里把它列成 breaking change。

**P1-4｜npm 的 postinstall 不要写 `$HOME`。** "npm entry works without a pre-existing `~/.rdd-framework`" 是好的，但如果实现成 postinstall 里装 skill 到用户目录：CI/容器会炸、`ignore-scripts` 环境会静默少装、而且"安装包往家目录写东西"是供应链上很难解释的行为。建议：包内只带资产，装 skill 走显式 `rdd install --agent ...`。另外 "runtime CLI resolves its own prefix" 要写清机制（`import.meta.url` 向上走），并对 `npx` / `-g` / 本地 dev 三种布局各一个测试——这三种的 prefix 推导经常不一样。

**P1-5｜"17" 这个硬编码会腐烂。** 改成集合等价断言：canonical 源里的每个 skill 在两个 target 中都存在且字节相同，数量由源派生。否则加第 18 个 skill 时 parity 静默失效。

**P1-6｜"equivalent workflows" 没有可操作定义。** 现在验收全是文件断言，而 Hypothesis 讲的是工作流等价。这两者之间没有桥。给一个可测试的 proxy：对每个 skill 验证 (a) 宿主可发现，(b) 其声明的入口命令能解析到真实存在的 Task target / script，(c) 文档化第一步能 dry-run 通过。这仍然不等于 LLM 行为等价，但至少是可证伪的，Gate 5 才有东西可写。

**P1-7｜真机 smoke 拿不到时的收口措辞必须写进交付物，不能只写进 review log。** 设计已经很有纪律地写了 "Do not claim host execution parity on file assertions alone"，但 Gate 5 的关闭条件里没有对应约束，结果可以出现"Stage 25 关闭 + 零次真机验证"。建议：Stage 25 允许以"file-level parity verified / host-level parity unverified"关闭，但**这句原话必须出现在 README 和 CHANGELOG 里**。把诚实落到产物上，而不是只落在日志里。

**P1-8｜调度器/worktree 那两条像是被夹带的 bugfix。**
> "A shell scheduler trigger is a pending request, never evidence of completed execution."
> "Sequential scheduling must not release a worktree before its task is actually completed."

这是 loop/scheduler skill 的行为正确性，不是 Codex 对齐。以验收条款的形式出现在 parity Stage 里，读起来像是在给一个已知缺陷开后门。要么单独立一个小 Stage（+ 对应测试），要么明确写进 scope 并配测试；不要让它以"顺便满足"的方式存在。同理，"review records distinguish independent same-model review from verified multi-model review" 是评审协议的 schema 变更，应在 ADR + review-log 模板里落地，否则每个 Stage 各自造措辞。

---

## 小问题

- **`--no-path` 的默认值没写**，而且反过来设计更安全：默认**不**改 shell rc（打印那一行，让用户自己贴），需要时用 `--path` 显式开启。安装器静默改 rc 文件是很招人烦的行为，也更难在测试里断言。
- **`--agent both`** 读起来别扭。`--agents claude,codex`（默认 `both` 语义）更可扩展，也不用为"both"造魔法值。这是 bikeshed，提一次。
- **建议加 `--dry-run`**。它让 collision、idempotency、fail-before-mutation 这几个断言可以被廉价地 E2E，回报远大于成本。
- **Rollback 有个经典陷阱**：三个 Stage 都写 "Revert Phase 5 source changes; remove only installer-owned skill directories"。但回滚代码后，**旧版本不认识新 manifest**，装过的东西可能卸不掉。补一句操作顺序："先用新版本的 uninstall 清理，再回滚代码"，并保证 manifest 前后兼容（多字段容忍、缺字段降级）。
- **安全一句话**：安装器往 `~/.claude/skills` 和 `~/.agents/skills` 写的是会被两个 agent 加载并执行的代码。设计应显式声明"源只能是本地 checkout / archive / npm tarball，安装期不拉取远程内容、不 `curl | sh`"。现在的措辞暗示了这一点但没说死，值得写死。
- **测试要断言"真实 HOME 未被动过"**：现在只承诺"tests 不写真目录"。加一条断言（真实 skills 目录 mtime/inode 前后不变），能挡住硬编码 `~` 的回归。
- **`status` 应报告 skew**：`~/.claude/skills` 与 `~/.agents/skills` 版本不一致（用户分两次装的）是很可能发生的状态，Stage 25 验 "CLI init/status/help" 时顺带把"检测并报告 drift/修复建议"列进去。
- **Phase 5 没有上下文**，外部读者不知道 1–4 是什么、Phase 5 是否是最后一段。一句话带过即可。

---

## 如果要一个最小改动清单

1. 加 **install manifest** 规范（含 hash 三态升级语义），写进三个 Stage 共用的"接口契约"小节。
2. 加 **host capability probe** 作为 Stage 23 Gate 1 的交付物，含探测清单和不符合假设时的回退方案；`~/.agents/skills` 给出处。
3. 加 **引用解析三条规则 + 静态 lint 测试**。
4. 把三份逐字重复的 Hypothesis / Verification / Non-goals 改写成**一个总假设 + 三个可独立证伪的子命题 + 三段互不重叠的验证**。
5. 明确**覆盖率度量对象**与 shell 薄封装的判定标准，否则 Gate 3 永远开着。
6. 改成 **不改用户 Taskfile / CLAUDE.md**（include + 标记块）。
7. 明确"真机 smoke 缺失"时的**收口措辞必须进 README/CHANGELOG**。
8. 把调度器/worktree 两条挪出去或显式纳入 scope。
9. 顺手：`--path` opt-in、`--dry-run`、rollback 顺序、npm 不写 `$HOME`、17 改为派生。

最需要你先回答的一个问题：**Codex 侧 `~/.agents/skills` 和 `$skill` 调用到底有没有一手证据？** 如果目前只是推断，我建议先花半天做 spike 再让 Gate 2 通过——否则这三份设计是在一个未验证的地基上做细节编排。