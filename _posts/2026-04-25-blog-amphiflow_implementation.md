---
layout: post
category: ml
title: 为什么agent和workflow可以融合在同一个架构里？
date: 2026-04-25 00:00:00 +0800
published: true
---

在今年，AI应用层的技术已经从workflow全面转向自主性agent。前者的典型代表是n8n、dify，后者的典型代表是OpenClaw、Hermes、CoWork。但是，**未来的新技术肯定不是对旧技术的全盘否定或全盘肯定，而是有克制的「扬弃」**。

我在上一篇介绍我们的新技术栈[AmphiLoop](https://mp.weixin.qq.com/s/KKHWWzJqeKR1fF6EsXheLQ)的时候，引入了一种新的程序架构，称为「amphiflow」。**Amphiflow是一种全新的、也是世界上第一个「决策与执行解耦」的架构，它同时具备workflow和agent两种运行模式，而且能够在两种模式之间自动切换**。

今天借周末的时间，我们一起剖析一下这种架构背后的实现原理，并分析一下它如何能同时发挥两种模式的优势。

<!--more-->

> [点击这里下载源码 ➜ https://github.com/bitsky-tech/AmphiLoop/](https://github.com/bitsky-tech/AmphiLoop/)

### Amphiflow的工作方式

完成任何一个任务，都需要确定**目标和路径**两个因素。举个简单的例子：

[<img src="/assets/images_amphiflow_tech/grid_s_d.png" width="80%" />](/assets/images_amphiflow_tech/grid_s_d.png)

在上面的网格中，假设S点有一个机器人，它的任务目标是从S点走到D点。再假设这个机器人只能水平或垂直移动。

按照workflow模式（也是传统软件的思路），一般来说，我们需要在编程时指定具体的路径，机器人才能知道如何行动。如下：

[<img src="/assets/images_amphiflow_tech/grid_s_d_path.png" width="80%" />](/assets/images_amphiflow_tech/grid_s_d_path.png)

当然，从S到D不止一条路径。但我们的workflow只需要指出一条路径就行。

而按照自主agent模式，我们就没有必要提前指定一条路径。我们只需要指定任务的目标（也就是到达D点），然后LLM会自动找到路径。这也是**当今AI Agent技术与传统软件的本质区别**。更详细的讨论参见《[AI Agent时代的软件开发范式](https://mp.weixin.qq.com/s/vejqEv5hACcbT15b4Xe5LQ)》中提到的“编程范式的转变：从面向step到面向goal”。

现在假设机器人在沿着既定路径的移动过程中，碰到了一个预料之外的“障碍”（如下图红色挡板）。

[<img src="/assets/images_amphiflow_tech/grid_s_d_failed.png" width="80%" />](/assets/images_amphiflow_tech/grid_s_d_failed.png)

如果机器人是由workflow模式驱动，并且这个红色障碍是workflow编程时无法预期的，那么这时候就只有一个结果：任务失败。

但是，如果机器人在遇到障碍时转换成了agent模式，那么它可能会绕过去继续前进。如下图：

[<img src="/assets/images_amphiflow_tech/grid_s_d_detour.png" width="80%" />](/assets/images_amphiflow_tech/grid_s_d_detour.png)

如果障碍实在远超预期，导致原来的路径已经完全不可用，agent模式还可能干脆重新规划一条路径。如下图：

[<img src="/assets/images_amphiflow_tech/grid_s_d_replan.png" width="80%" />](/assets/images_amphiflow_tech/grid_s_d_replan.png)

以上这个例子虽然只是一个比喻，但已经说明了**amphiflow最基础的工作原理**：
- amphiflow首先工作在workflow模式。一旦碰到预料之外的障碍，某一步发生错误了，就切换到agent模式。在agent模式下，可能产生两个降级。
- 先是尝试小降级。它会试图「修复」当前这一步的错误。如果它能够以agent模式正确完成当前这一步，那么就重新切换回workflow模式，继续向下运行（对应前面碰到障碍绕过去的情况）。否则，在多次修复尝试失败后，会进入大降级。
- 大降级：程序整体切换到一个大的agentic loop，完全以agent模式来尝试完成原始的task goal（对应前面重新规划出一条路径的情况）。当然，它会考虑原来workflow已经完成的部分，在这个基础上去执行剩下的动作。

在使用AmphiLoop进行构建的时候，在Project Mode这一步选择2，就能生成amphiflow架构的程序。如下：

[<img src="/assets/images_amphiloop/choose_option_1.png" width="90%" />](/assets/images_amphiloop/choose_option_1.png)

当然，上面的介绍中忽略了一些细节。Workflow模式也并非在编程时一定要指定**具体的**路径，它也可以包含一个动态的算法来动态计算出一条路径。但这里的**关键在于：对于workflow模式来说，如果执行路径中出现的障碍是它非预期的，它就无法解决。但是，agent模式却可以处理非预期的障碍或情况**。

### Amphiflow的优势

Amphiflow可以同时具备workflow和agent两种模式的优势：
- 在预期范围之内运行时，使用workflow模式，稳定、可控，不依赖LLM，节省token。
- 当发生预期之外的环境变化时，切换到agent模式，自主应对非预期情况，绕过障碍或者通知人类解决障碍。

正是因为这一新架构同时具备workflow和agent模式的特征，所以才被称为amphiflow (amphibious flow)。

### Amphiflow的实现原理

要讲清楚amphiflow的实现原理，有两个方面需要解释：
1. workflow模式和agent模式是怎么融合到一起的？
2. 在workflow模式出错的时候，又是怎么切换到agent模式的？

其中问题1，又需要涉及到两个概念：
- 「观察 - 思考 - 行动」循环，即Observe-Think-Act cycle。在AmphiLoop的架构中，两种运行模式都可以统一归结到这个循环上。它们共享观察 (Observe) 与行动 (Act) ，但是思考过程 (Think) 则各自独立。
- 决策与执行解耦，即Decoupling Decision from Execution。在AmphiLoop的架构中，两种运行模式各自独立的Think产生独立的Decision。

这里涉及到的核心实现代码，基本都在`bridgic-amphibious`模块的`_amphibious_automa.py`文件中。地址：

> https://github.com/bitsky-tech/bridgic/blob/main/packages/bridgic-amphibious/bridgic/amphibious/_amphibious_automa.py

#### 「观察 - 思考 - 行动」循环

agent模式看做一个循环，这通常是好理解的：
- **观察：把观察到的原始数据加工成适合思考的形式**。这一步也可以认为是一个**「感知」过程**。
- **思考：产生一个决策（decision），以决定下一步如何行动**。对于agent模式来说，这个decision由LLM产生。这一步也可以认为是一个**「认知」的过程**。
- **行动：调用工具，对环境产生影响**。

agent模式的这个「观察 - 思考 - 行动」循环，实现代码在`_run_once`方法中：

[<img src="/assets/images_amphiflow_tech/code_agent_run_once.png" width="90%" />](/assets/images_amphiflow_tech/code_agent_run_once.png)

在AmphiLoop的架构中，比较独特的一点是，workflow也实现成了一个「观察 - 思考 - 行动」循环。如何做的呢？首先，观察和行动，是跟agent模式一样的，代码在`_run_workflow`方法中：

[<img src="/assets/images_amphiflow_tech/code_run_workflow.png" width="90%" />](/assets/images_amphiflow_tech/code_run_workflow.png)

注意上面代码中只有观察和行动这两步，其中有个很关键的`decision`变量，它不再由LLM产生，而是由workflow产生。代码如下：

[<img src="/assets/images_amphiflow_tech/code_call_on_workflow.png" width="90%" />](/assets/images_amphiflow_tech/code_call_on_workflow.png)

以上这段代码调用`on_workflow`产生一个generator，然后在一个循环中调用`__anext__`和`asend`原语从generator中每次拿到一个`item`（里面包含了`item.decision`）。这个循环就形成了workflow模式的「观察 - 思考 - 行动」循环。

#### 决策与执行解耦

前面我们看到了**workflow模式的「观察 - 思考 - 行动」循环。其中的「思考」过程由workflow的代码隐式地表达**。我们看一下`on_workflow`的一个具体实现例子：

[<img src="/assets/images_amphiflow_tech/code_on_workflow_example.png" width="90%" />](/assets/images_amphiflow_tech/code_on_workflow_example.png)

这段代码并非AmphiLoop框架里面的代码，而是每次由AmphiLoop根据具体任务描述（`TASK.md`）引导生成的代码。因此，`on_workflow`描述了具体任务的执行步骤。

这里使用了python的`yield`语法，表示`on_workflow`方法执行的时候并不代表任务的真正执行。真正的执行延迟到了前面的`_run_workflow`方法中由`_action`方法执行。**借助这种技术手段，workflow的执行也表现为一个「观察 - 思考 - 行动」循环。每次循环产生一个decision（封装在`ActionCall`中）**。

还需要注意的是，这段代码中不仅仅是`ActionCall`动作序列，它还可以包含动态逻辑（分支和循环），比如上面代码中的`for`循环。**这表明AmphiLoop的workflow不同于简单的录制重放，而是真正的动态程序**。

#### 运行模式的切换

基于前面的「观察 - 思考 - 行动」循环以及决策与执行解耦的架构，workflow模式得以在出错时能够自动切换到agent模式。

[<img src="/assets/images_amphiflow_tech/code_mode_switch.png" width="90%" />](/assets/images_amphiflow_tech/code_mode_switch.png)

以上代码中，`self.snapshot`和`self._run`是小降级，相当于在独立的上下文中执行一个agent。其目标是：修复出错的那一步的错误，然后执行它（这里的`decision.step_content`来自前面的`ActionCall`的`description`参数）。这样在修复后还可以切换回workflow模式继续执行。

`self.on_agent(ctx)`是大降级，相当于启动一个agent，其目标即是原始任务目标，且与原来的workflow共享上下文。

### 小结

AmphiLoop及其引入的amphiflow架构，是基于agent的自主性优势和传统软件的确定性优势推演出来的未来架构。它瞄准的是当今AI技术不可控、不稳定、极耗token的核心问题，理论上有利于推动AI技术在更广、更加纵深的场景中被采用。

### 社区交流

（1）我们新建了一个Discord社区，请访问如下地址参与讨论：

> <https://discord.gg/4NyKjXGKEh>

由于微信群维护不方便，也请原来在群里的同学移步Discord。

（2）新的X (Twitter) 账号（后面是发布版本更新动态的主阵地）：

> <https://x.com/bridgic>

（正文完）

**其它精选文章**：

* [两栖模式构建Agent，与OpenClaw/Hermes不一样的解法](https://mp.weixin.qq.com/s/KKHWWzJqeKR1fF6EsXheLQ)
* [【开源】专为「探路+编码」范式设计的全新浏览器工具集+Skills](https://mp.weixin.qq.com/s/1nstbS6EBEuZAJQL8o4ASg)
* [过年了，聊聊AI和人文](https://mp.weixin.qq.com/s/8rQ8a5M35ymod_gjP1JChg)
* [AI智能体纪元或将从2026开始归零](https://mp.weixin.qq.com/s/h8kS6dpoX2YC771M0nGrAA)
* [【开源】我亲手开发的一个AI框架，谈下背后的思考](https://mp.weixin.qq.com/s/d2lADFG5m8pZ31v8epUhHQ)
* [AI Agent时代的软件开发范式](https://mp.weixin.qq.com/s/vejqEv5hACcbT15b4Xe5LQ)
* [AI Agent的概念、自主程度和抽象层次](https://mp.weixin.qq.com/s/dJAWleHyOWd8FPqH5ZqDWw)
* [科普一下：拆解LLM背后的概率学原理](https://mp.weixin.qq.com/s/gF-EAVn0sfaPgvHmRLW3Gw)
* [分布式领域最重要的一篇论文，到底讲了什么？](https://mp.weixin.qq.com/s/FZnJLPeTh-bV0amLO5CnoQ)
