---
layout: post
category: ml
title: Claude Managed Agents意味着什么？
date: 2026-04-11 00:00:00 +0800
published: true
---

4月8号，Anthropic发布了一项称为Claude Managed Agents的API服务，导致全球软件公司的股票进一步下跌。这项服务对软件产业真的有这么大的利空影响吗？它到底是怎样的一项服务？

<!--more-->

其实呢，类似Claude Managed Agents这样的企业服务在今天能够出现，应该早在预期之中。资本市场的反应总是会迟一步，而一旦有所发觉则倾向于反应过度。

我在之前的两篇文章《[使用OpenClaw时如何降低token消耗？分享一个浏览器自动化的skill](https://mp.weixin.qq.com/s/gMeZ-x-3UU5Lq2qlxMfw7A)》和《[不用手写一行代码，10分钟立等可取，爬取twitter和github动态](https://mp.weixin.qq.com/s/QPsIg0F0mvErkCSnaHFVNg)》中提到过，类似OpenClaw这样的通用agent和类似Claude Code这样的coding agent，未来会作为被编排、被调度的「通用的AI计算单元」而存在的。Claude Managed Agents的推出，则意味着这种「通用的AI计算单元」从桌面端移到了云端——一个很自然的动作。

一个通用的AI计算单元可以用来做什么呢？这意味着不管是企业还是个人，都可以用它作为最基本的一个构建单元，来构建出更大规模的AI系统。实际上，之前已经有很多人在将Claude Code作为一种「通用的AI计算单元」来调用了，只不过调用的方式更像是「本地」执行（表现为claude -p命令）。我在[上一篇](https://mp.weixin.qq.com/s/1nstbS6EBEuZAJQL8o4ASg)文章中已经展示过这种方式了（如下图）。

[<img src="/assets/images_bridgic_browser/task_release_tracker.png" width="90%" />](/assets/images_bridgic_browser/task_release_tracker.png)

类似这种调用方式，你需要自己提供执行环境和除了模型以外的计算资源。但Claude Managed Agents提供了整套云端运行环境，你只需要像调用其他API一样来使用它。当然，Anthropic会向你收钱，按时间付费。

刚才亲手试了下Claude Managed Agents的功能，简单说，它大概提供了两方面能力：

第一，快速构建出一个通用agent，并定制化它。基本配置一下就可以。

第二，云端运行环境和资源。

简单理解的话：

Claude Managed Agents = 一个agent builder + 一个跑在云端的Claude Code。

作为一个通用agent，能够定制什么呢？我们知道，Claude Code可以配置MCP、Skills，但system tools你作为用户是没法改的。而在Claude Managed Agents中system tools是可以定制的：

[<img src="/assets/images_claude_managed_agents/edit_agent.png" width="90%" />](/assets/images_claude_managed_agents/edit_agent.png)

甚至可以增加自定义工具：

[<img src="/assets/images_claude_managed_agents/add_custom_tools.png" width="90%" />](/assets/images_claude_managed_agents/add_custom_tools.png)

[<img src="/assets/images_claude_managed_agents/agent_config.png" width="90%" />](/assets/images_claude_managed_agents/agent_config.png)

毕竟Claude Code的目标很明确，就是主要用来编码的。但Managed Agents是为了开放给企业使用的，那主要用法就可能跟场景有些关系的。所以允许更多的可定制性是合理的。

---

有些人说，Anthropic发布Claude Managed Agents是为了进一步封杀OpenClaw。毕竟前几天Anthropic刚刚封杀了第三方应用使用Claude订阅账号。真的是这样吗？

简单来回答：没啥必然联系。前面说了，Claude Managed Agents的推出是「通用的AI计算单元」从桌面向云端的一种自然的延伸，是符合大的技术发展路径的。如果非要说跟OpenClaw有关的话，也有一点：那就是阻止OpenClaw使用Claude的订阅算力，空出来以后给Managed Agents使用。毕竟这项服务是在云端运行长程的计算，是很消耗资源的（所以要单独收钱）。

第二个问题：Claude Managed Agents真的会杀死软件公司吗？

AI的发展，确实会重塑软件的边界和逻辑，尤其是以工作流为业务核心的软件，面临很大的考验。但是，这个逻辑早就浮出水面了，主要与coding成本的下降有关，看起来与Claude Managed Agents也并没有直接联系。

第三个问题：Claude Managed Agents的计费方式，给我们什么启示？

Claude Managed Agents采用了按token量计费和按session运行时间计费两种叠加的方式。以前呢，大模型厂商普遍有两种收费方式：按token量计费和订阅账号（按月/按年）。现在多了一种按session运行时间计费，而且这个计费跟模型的推理成本没关系，是收的harness+工具+容器运行的钱。

[<img src="/assets/images_claude_managed_agents/pricing.png" width="90%" />](/assets/images_claude_managed_agents/pricing.png)

这个收费模式如果能跑通，对业界是个好事儿。agent公司找到了一种新的收费模式，也不再把收费跟token绑定到一起了。

当然了，作为一种「通用的AI计算单元」的云端形式，Claude Managed Agents肯定不会是最后一个。我们在未来会看到无数这样的计算单元被提供出来，作为构建未来AI世界的「砖和瓦」。

（正文完）

**其它精选文章**：

* [不用手写一行代码，10分钟立等可取，爬取twitter和github动态](https://mp.weixin.qq.com/s/QPsIg0F0mvErkCSnaHFVNg)
* [使用OpenClaw时如何降低token消耗？分享一个浏览器自动化的skill](https://mp.weixin.qq.com/s/gMeZ-x-3UU5Lq2qlxMfw7A)
* [过年了，聊聊AI和人文](https://mp.weixin.qq.com/s/8rQ8a5M35ymod_gjP1JChg)
* [AI智能体纪元或将从2026开始归零](https://mp.weixin.qq.com/s/h8kS6dpoX2YC771M0nGrAA)
* [【开源】我亲手开发的一个AI框架，谈下背后的思考](https://mp.weixin.qq.com/s/d2lADFG5m8pZ31v8epUhHQ)
* [AI Agent时代的软件开发范式](https://mp.weixin.qq.com/s/vejqEv5hACcbT15b4Xe5LQ)
* [AI Agent的概念、自主程度和抽象层次](https://mp.weixin.qq.com/s/dJAWleHyOWd8FPqH5ZqDWw)
* [科普一下：拆解LLM背后的概率学原理](https://mp.weixin.qq.com/s/gF-EAVn0sfaPgvHmRLW3Gw)
* [分布式领域最重要的一篇论文，到底讲了什么？](https://mp.weixin.qq.com/s/FZnJLPeTh-bV0amLO5CnoQ)
