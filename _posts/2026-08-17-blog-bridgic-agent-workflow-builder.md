---
layout: post
category: ml
title: 闭关几个月，今天正式发布一个开源agent产品，开启「斜杠build」
date: 2026-08-17 00:00:00 +0800
published: true
---

各位朋友，今天正式发布一个新的开源agent项目：**Bridgic Agent**。说实话，我们内部花了非常多的精力去打磨它。周围的朋友和客户也已经试用了相当长一段时间，给我们提供了很多宝贵的建议。我在此向我们的第一批用户表达感谢🙏🏻

<!--more-->

各位朋友肯定头脑中冒出至少两个问题：
- Bridgic Agent能做什么？
- 它有什么不一样？

### Bridgic Agent能做什么？

Bridgic Agent是一款桌面应用，也是一个智能的自动化工作流构建器。目前支持macOS和Windows两个系统。

它能做什么呢？我通过几个例子以及截图来说明。

先看第一个例子：

[<img src="/assets/images_bridgic_agent/workflow-card-2.webp" width="80%" />](/assets/images_bridgic_agent/workflow-card-2.webp)

以上这个截图是啥意思呢？它是我通过Bridgic Agent构建出来的一个产物——实际上，是一个可以自动化执行的工作流。

这个工作流是干啥的呢？别着急啊，我慢慢解释。

在我们项目开发的后期，我需要对每天测试发现的bug进行追踪。于是我选了一个比较轻量级的做法，用飞书表格来每天做记录，并和项目组其他同学共享这个表格。类似下面这个样子：

[<img src="/assets/images_bridgic_agent/scheduled-feishu-writeback.webp" width="80%" />](/assets/images_bridgic_agent/scheduled-feishu-writeback.webp)

接下来，我们就自然产生了一个想法：能不能让agent来定期扫描这个表格，把最新的、还没有解决的bug扫出来，写一个bug分析报告？这个分析报告呢，会写明bug是什么原因产生的，以及具体的修复方案。

没错，前面截图的那个“飞书待处理 Bug 代码分析报告 Workflow”，就是自动化地干这个事儿的。

那Bridgic Agent在这个过程中起了啥作用呢？答案是，我借助Bridgic Agent，没写一行代码，当然也没读过一行代码，就很轻松地把这个工作流制作出来了。而且，它能够很精准地执行我预期的操作。比如说，这个工作流会根据“任务性质”过滤出里面的bug，按时间倒序去扫描，还会扫描分析对应的代码库，最后写完报告后它还会在表格里记录一下，以避免下次扫描重复处理，等等。

那具体是怎么把这个工作流制作出来的啊？前面的工作流截图里面的那么多字，是我手敲进去的吗？快速回答一下，不是！但具体的制作过程，我们先留一个疑问在这，后文会再介绍。

显然，Bridgic Agent是一个通用的agent，它当然不会只能完成这么一个工作流。实际上，它可以构建出你想要的任何工作流。前提是只要你自己能梳理清楚流程。

在介绍第二个例子之前，我们可以看一眼Bridgic Agent长什么样子了：

[<img src="/assets/images_bridgic_agent/building-2.webp" width="80%" />](/assets/images_bridgic_agent/building-2.webp)

第二个例子：

[<img src="/assets/images_bridgic_agent/workflow-card.webp" width="80%" />](/assets/images_bridgic_agent/workflow-card.webp)

很多工程师可能都有这样的诉求，希望及时了解GitHub上最近又有什么比较火的项目了。以上这个工作流正好满足这个需求，它扫描GitHub趋势榜单（Trending）的周榜和月榜，写一个趋势分析报告并推送飞书消息。

[<img src="/assets/images_bridgic_agent/schedule-lark-message.webp" width="25%" />](/assets/images_bridgic_agent/schedule-lark-message.webp)

好了，更多例子先不展开了。这里我为大家准备了4个详细的教程（由于时间关系先准备了这么多，后续持续添加）：
- [【教程】基于飞书多维表格自动化管理软件项目](https://showcase.bridgic.ai/zh/workflows/project-management-automation)
- [【教程】自动采集天猫超市商品信息](https://showcase.bridgic.ai/zh/workflows/e-commerce-product-scraper)
- [【教程】基于教材批量制作教学材料](https://showcase.bridgic.ai/zh/workflows/courseware-development)
- [【教程】GitHub热点及AI项目追踪](https://showcase.bridgic.ai/zh/workflows/github-trending-tracker)

每个教程里面，都附了工作流下载链接。你可以下载后，照葫芦画瓢，自己捣鼓一个适合自己的工作流。随心所欲，想怎么修改都行。

### Bridgic Agent有哪些独到之处？

关于这个问题呢，就不得不说一下Bridgic Agent这个产品的一些设计原则和指导思想了。

**第一，精心设计的「斜杠build」指令。也就是`/build`。**

对生活在这个时代的个体来说，AI带给我们的对于数字世界的**低成本定制化能力**，是前所未有的。很多人都不缺想法，但想法和真正能run的东西之间，铺满了“荆棘丛”——晦涩的编程语言、复杂的技术栈、令人眼花缭乱的执行环境。但是今天，事情有点不同了。

在Bridgic Agent中，「斜杠build」指令相当于为普通人铺就了一条跨越“荆棘丛”的道路。虽然并非每次都是坦途，但它无时无刻不在帮你扫清障碍，护送你抵达真正的目的地——把你在日常工作和生活中真正有用的那个工作流制作出来。

随时敲下`/build`，准确而简洁地写下你的需求。不需要长篇大论，只需要阐明关键点。

[<img src="/assets/images_bridgic_agent/new-task.webp" width="80%" />](/assets/images_bridgic_agent/new-task.webp)

然后，Bridgic Agent会把整个构建过程分成**四个阶段：任务创建、探路、生成、验证**。只要你有耐心，agent会以极高的成功率把你想要的工作流构建出来。

[<img src="/assets/images_bridgic_agent/login-prompt.webp" width="80%" />](/assets/images_bridgic_agent/login-prompt.webp)

**第二，Agent 引导人，而不是人指挥 Agent。**

这个设计原则贯穿在Bridgic Agent运行的各个阶段。

当agent发现你的需求有待澄清的时候，它会主动找你确认。比如：

[<img src="/assets/images_bridgic_agent/clarify-3.webp" width="80%" />](/assets/images_bridgic_agent/clarify-3.webp)

在工作流运行中，当遇到重大决策点时，agent也会主动征求你的同意。比如：

[<img src="/assets/images_bridgic_agent/running-subagents-confirm.webp" width="80%" />](/assets/images_bridgic_agent/running-subagents-confirm.webp)

在整个过程中，你只需要设定目标并给出关键判断，Bridgic Agent则负责探索路径、推进任务，并在需要时主动寻求你的帮助。

**第三，用户只提目标，直接拿结果。**

你不需要管理执行过程，也**无需管理技能和插件**。你只需要「描述需求 → 必要时参与 → 验收结果」，中间过程则全部交给 Bridgic Agent。

我们当前仍处于agent技术飞速发展的中间阶段。市面上涌现出大量的技能和插件，但这显然不是最终形态。要求AI的用户去了解哪些任务应该使用哪些技能，是反人性的。技能、插件、MCP这些技术，最终将成为用户无需直接关注的底层技术手段。

为了达到这一目标，Bridgic Agent提供了一个内置的元技能，称为`/how-to`技能。在「斜杠build」指令构建工作流的过程中，它会主动调用`/how-to`技能，为当前任务定位、下载、组合合适的技能。这一切发生在幕后。

**第四，不只是运行一次，而是长期运行。**

真正有用的工作流，通常是会重复执行的。

Bridgic Agent把一次成功的自动化，变成可以反复运行、持续演进的个人生产力资产。

为此，Bridgic Agent提供了完善的工作流管理能力：

[<img src="/assets/images_bridgic_agent/workflow-management.webp" width="80%" />](/assets/images_bridgic_agent/workflow-management.webp)

完善的定时调度能力：

[<img src="/assets/images_bridgic_agent/schedule-running.webp" width="80%" />](/assets/images_bridgic_agent/schedule-running.webp)

已建好的工作流并非一成不变，可以随需求变化、环境变化随时修改、优化或修复：

[<img src="/assets/images_bridgic_agent/workflow-update.webp" width="80%" />](/assets/images_bridgic_agent/workflow-update.webp)

总之，从**构建、运行、修改、优化、修复到定时调度**，Bridgic Agent覆盖工作流完整生命周期。一次构建，长期运行，持续演进。

**第五，为复杂长任务而生的 Multi-Agent。**

Bridgic Agent提供了两种启动子agent的方式。

第一种，子agent由主agent启动：

[<img src="/assets/images_bridgic_agent/running-subagent-step.webp" width="80%" />](/assets/images_bridgic_agent/running-subagent-step.webp)

第二种，子agent由工作流脚本启动：

[<img src="/assets/images_bridgic_agent/running-subagents-list.webp" width="80%" />](/assets/images_bridgic_agent/running-subagents-list.webp)

请注意：在Bridgic Agent中，子agent通常不需要用户关注它们如何使用、如何创建。Bridgic Agent会自动拆解任务、启动多个子 Agent 并发协作；它们支持高并发、长时间运行和持久交互。

**第六，打造真正属于你的工作流。**

不是只能使用别人预先设计好的模板。

你可以根据自己的工作方式构建、修改和演进工作流，把经验、流程和自动化能力逐渐沉淀为**属于自己的私有资产**。

**你的需求，你的工作流，你的 Agent**。

### 小结

AI发展到今天，很多东西在变，很多观点尚未达成共识。

工程师是最先感受到这些变化的群体。

从原来的手写代码，过渡到AI Coding。截至今天，需要人类工程师亲自编写代码的场景已经很少了。

但是，AI写出来的代码，是否需要人类工程师阅读、review，至今仍然充满争论。人类对于代码的控制权，最终能够放手到什么样的程度，还在演进之中。

然而，在某些场景下，特别是不涉及庞大代码库的那些场景下，完全使用自然语言编程、完全不关注代码，是基本可行的。人们日常工作和生活中经常碰到的工作流自动化，恰恰属于这样的一种场景。

这意味着，对于数字资产通过“编程”的方式进行定制化的能力，会从工程师群体扩散到大众群体。

Bridgic Agent的设计，正是将coding这一“超能力”，以相对优雅的方式赋予每一个人。它的用户无需关注底层的实现细节，只用关注如何使用自然语言将自己的需求表达清楚即可。

使用Bridgic Agent，非技术人员可以做到以前根本无法想象的事情。而技术人员也可以使用Bridgic Agent，让工作变得轻松愉快——一边玩着游戏，一边构建你的工作流。

限于篇幅，关于Bridgic Agent底层的技术架构和实现，我们以后再聊。

### 软件下载

> [点击这里下载源码 ➜ https://github.com/bitsky-tech/bridgic-agent/](https://github.com/bitsky-tech/bridgic-agent/)

**macOS和Windows安装包下载**：

请前往 [bridgic-agent Releases](https://github.com/bitsky-tech/bridgic-agent/releases)
页面下载对应的安装包：macOS 使用 `.pkg` 文件，Windows 使用 `.exe` 文件。

> **注意：** Windows 安装包目前尚未进行代码签名。如果被 Windows 拦截，可能需要在 Windows 安全中心和智能应用控制中调整相关设置。也可以选择从源码启动。

### 社区交流

请通过以下渠道参与讨论，支持我们。谢谢！

（1）Discord群/频道：

> <https://discord.gg/XcEqrwKUXN>

（2）微信群：

[<img src="/assets/weixin_group_huoma.png" width="20%" />](/assets/weixin_group_huoma.png)

（3）X账号（发布更新动态的主阵地）：

> <https://x.com/bridgic>

（正文完）

**其它精选文章**：

* [为什么agent和workflow可以融合在同一个架构里？](https://mp.weixin.qq.com/s/heZdKTFKn1r33QwarNhrMg)
* [两栖模式构建Agent，与OpenClaw/Hermes不一样的解法](https://mp.weixin.qq.com/s/KKHWWzJqeKR1fF6EsXheLQ)
* [过年了，聊聊AI和人文](https://mp.weixin.qq.com/s/8rQ8a5M35ymod_gjP1JChg)
* [AI智能体纪元或将从2026开始归零](https://mp.weixin.qq.com/s/h8kS6dpoX2YC771M0nGrAA)
* [【开源】我亲手开发的一个AI框架，谈下背后的思考](https://mp.weixin.qq.com/s/d2lADFG5m8pZ31v8epUhHQ)
* [AI Agent时代的软件开发范式](https://mp.weixin.qq.com/s/vejqEv5hACcbT15b4Xe5LQ)
* [AI Agent的概念、自主程度和抽象层次](https://mp.weixin.qq.com/s/dJAWleHyOWd8FPqH5ZqDWw)
* [科普一下：拆解LLM背后的概率学原理](https://mp.weixin.qq.com/s/gF-EAVn0sfaPgvHmRLW3Gw)
* [分布式领域最重要的一篇论文，到底讲了什么？](https://mp.weixin.qq.com/s/FZnJLPeTh-bV0amLO5CnoQ)
