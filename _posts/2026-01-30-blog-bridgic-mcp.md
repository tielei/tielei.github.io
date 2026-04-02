---
layout: post
category: "ml"
title: "使用Bridgic长程自主模块+MCP，控制你的浏览器"
date: 2026-01-30 00:00:00 +0800
published: true
---

最近我们刚发布了[Bridgic v0.3.0b1](https://github.com/bitsky-tech/bridgic/releases/tag/v0.3.0b1)版本，升级了[长程自主性智能模块](https://docs.bridgic.ai/latest/tutorials/items/agentic_module/about_recent_automa/)[1]，并且完善了[MCP集成能力](https://docs.bridgic.ai/latest/tutorials/items/protocol_integration/mcp_quick_start/)[2]。今天我就来和大家介绍一下，如何组合这些底层能力来实现一些有意思的功能（具备高度自主性的），以及将自主性模块加入到Bridgic风格的编排体系中的背后的一些设计思考。

<!--more-->

接下来的内容分四个部分：
* Bridgic长程自主性模块的设计思路。
* 一个案例：用自然语言控制浏览器实时查询金价。
* Agent Skills出现之后，MCP还有用吗？
* 分享一些MCP资源。

### Bridgic长程自主性模块的设计思路

熟悉Bridgic的朋友可能已经知道了，在Bridgic的最底层，我们使用[动态拓扑](https://mp.weixin.qq.com/s/FNAS-xp1RYAQfZj2nXLSCg)来统一编排确定性的模块和自主性的模块，期望将各种不同的智能组件纳入到一个系统里面来无缝工作。

在Bridgic上一个版本，其实已经有了一个基于ReAct的自主性模块（具体实现是[`ReActAutoma`](https://docs.bridgic.ai/v0.2.1/reference/bridgic-core/bridgic/core/agentic/#bridgic.core.agentic.ReActAutoma)类[3]）。但是，对于执行真正长程的自主性任务来说，`ReActAutoma`存在一个问题：随着时间的推移，调用工具的结果以ToolMessage的形式不断追加进上下文，造成「上下文爆炸」和「目标漂移」。

因此，我们对自主性模块进行了重大升级，使它更适合执行长程的自主性任务。这个新的模块实现，名字叫`ReCentAutoma`[1]。它是一个增强的ReAct (Resoning and Acting) loop，实现了一种称为ReCENT (Recursive Compressed Episodic Node Tree) 的记忆压缩算法。具体来说：
* ReCENT算法会选择合适的时机对情景记忆 (episodic memory) 进行压缩，在不丢失关键语义的情况下避免上下文窗口爆炸。
* `ReCentAutoma`显式提供了`goal`参数和`guidance`参数，允许开发者指明任务目标和任务指导信息。这些信息不会被ReCENT算法压缩，保证智能体长时间运行时能够维持目标。

值得一提的是，`ReCentAutoma`的内部实现也是基于Bridgic底层的动态拓扑来进行编排的。因此，`ReCentAutoma`也能够享受到Bridgic框架底层提供的可观测性集成能力和human-in-the-loop的中断、恢复等能力。换句话说，在Bridgic的世界中，动态拓扑既用于编排确定性模块和自主性模块，把这两种类型的模块融合在一个系统中，也同时用于编排自主性模块的内部结构。底层是统一的。

另外，为了让这个自主性模块能够与市面上现有的工具更轻松地对接，Bridgic这个版本对MCP集成的能力也进行了完善（引入了`ToolSetBuilder`）。至此，Bridgic的「工具架构」已经自成体系，可以用下面的图来表达（点击看大图）：

[<img src="/assets/images_bridgic_mcp/bridgic_tools_arch.png" alt="Bridgic工具架构" width="90%" />](/assets/images_bridgic_mcp/bridgic_tools_arch.png)

以上架构遵循了Bridgic一贯的协调统一的设计风格：
* 左侧是工具的原始形式，或者说，是能够被加工为工具的那些「原材料」。目前的实现已经囊括了：用Python实现的一个function，一段MCP配置，或者是，一个`GraphAutoma`子类。「原材料」的种类可以根据需要扩展（这是Bridgic对外提供的用于扩展工具的地方）。
* 各种工具的「原材料」都会被统一转换成`ToolSpec`。它表达了一个工具全方位的信息（描述信息+执行信息），对应有不同的子类实现。
* `ToolSpec`经过API `to_tool()`转换成`Tool`这个类，表达成了被LLM能够理解的工具形式。这种形式的表达用于与LLM交互，完成工具调用。
* 在执行层面，`ToolSpec`经过API `create_worker()`转换成了`Worker`。`Worker`被动态加入到`GraphAutoma`中，就可以利用Bridgic动态拓扑的编排能力完成执行。
* 最后，任何`GraphAutoma`的子类（不管是借助`@worker`还是ASL声明的），又都可以成为工具的「原材料」。

### 一个浏览器自动化案例

有了长程自主模块`ReCentAutoma`和MCP工具，我们就可以组合出很多自主性的智能体。下面举一个浏览器自动化的例子。一般来说，浏览器自动化的任务需要让模型理解页面内容，很容易撑爆上下文窗口，因此对于记忆的管理和压缩就非常有必要。

在这个例子中，我们选择Playwright提供的MCP工具[4]。如下，当前共有22个工具。

[<img src="/assets/images_bridgic_mcp/playwright_mcp_tools.png" alt="Playwright MCP Tools" width="60%" />](/assets/images_bridgic_mcp/playwright_mcp_tools.png)

以下是核心代码片段（完整代码参见[5]）：

```python
    playwright_connection = McpServerConnectionStdio(
        name="connection-playwright-stdio",
        command="npx",
        args=[
            "@playwright/mcp@latest",
            f"--output-dir={temp_dir}",
            "--viewport-size=1920x1080",
            "--save-video=1920x1080",
        ],
        request_timeout=60,
    )

    ...

    tools = playwright_connection.list_tools()
    browser_agent = ReCentAutoma(
        llm=llm,
        tools=tools,
        memory_config=ReCentMemoryConfig(
            llm=llm,
            max_node_size=8,
            max_token_size=1024 * 32,
        ),
        stop_condition=StopCondition(max_iteration=20, max_consecutive_no_tool_selected=1),
        running_options=RunningOptions(debug=True),
    )

    # Use the agent to find recent gold prices on Hong Kong Gold Exchange website
    result = await browser_agent.arun(
        goal=(
            "Find the recent gold prices on Hong Kong Gold Exchange website."
        ),
        guidance=(
            "Execute the following steps strictly sequentially; do not perform any two steps in parallel.\n"
            "1. Navigate to https://hkgx.com.hk/en\n"
            "2. Hover on the 'Market & Data' button to show more button options\n"
            "3. Click the 'Price History' button to access the historical price page\n"
            "4. As the current date is already selected, simply select the “RMB Kilo Gold” option.\n"
            "5. Click the search button and have a look at the recent gold price trends\n"
            "6. Close the browser and give out a summary of recent gold price trends\n"
        ),
    )

    print("Final Result:\n\n")
    print(result)

    # Close the connection when done
    playwright_connection.close()
```

上述代码要完成的功能是，驱动浏览器去访问香港黄金交易所的网站，然后点击各个菜单并筛选查询条件，最后检索出最新的金价并进行总结。以下是执行效果：

[<img src="/assets/images_bridgic_mcp/HKGX_browser_screen.gif" alt="Bridgic控制浏览器查询金价" width="90%" />](/assets/images_bridgic_mcp/HKGX_browser_screen.gif)

下面是截取的一段中间执行过程的日志：

[<img src="/assets/images_bridgic_mcp/gold_price_part_log.png" alt="金价查询智能体日志" width="80%" />](/assets/images_bridgic_mcp/gold_price_part_log.png)

如果你想亲自run一下以上代码，只需要执行以下几行命令即可：

```shell
git clone https://github.com/bitsky-tech/bridgic-examples.git
cd bridgic-examples
uv run --prerelease=allow  agentic/recent_browser_gold_price.py
```

更多例子代码请查阅bridgic-examples工程[6]。

### Agent Skills出现之后，MCP还有用吗？

自从Claude Code彻底出圈之后，它所推出的Skills概念也随后爆火。很多人就问了，Anthropic先是推出了MCP，后来又推出了Skills，是不是Skills会取代MCP？

我们先看下Claude Code目前的情况。

首先，在Claude Code中，Skills是提供Knowledge的，而不是用于提供工具的。如果你想在Claude Code的system tools之外，额外给它配置一些其他的工具，那么似乎还是只能依赖MCP。实际上，Skills能做的事更多，你可以在里面配置流程、编码规范、业务知识、代码示例、各种规则等等，以及对于现有工具的调用指导，你都可以在Skills中描述。但是，引入新的工具还是得通过MCP。

其次，Skills和MCP这两个机制还有一个很大不同：Skills天生提供了渐进式披露的能力，而MCP默认没有。这也是为什么有人会说，MCP会消耗大量token，甚至撑爆上下文窗口。不过，这其实跟MCP协议本身并没有直接关系。实际上，在Claude Code中，也不是所有MCP工具都会常驻上下文窗口。它有一个Tool search的技术[7]：

> Tool search (enabled by default) loads MCP tools up to 10% of context and defers the rest until needed.

这跟Skills的渐进式加载机制不同，但通过search的方式去避免了对上下文窗口的过度占用。

前面我们说，在Claude Code中引入新工具还是得通过MCP，这话其实也不绝对。如果你提供的工具是可以通过Bash调用的，换句话说，是CLI形式的工具，那么是相当于可以通过Skills引入进来的。这是因为Bash这个工具是Claude Code的一个system tool，而这个Bash工具就很特殊，它可以调用其他命令行工具。

所以，真正需要对比的可能不是Skills vs. MCP，而是CLI tools vs. MCP tools。

作为一个真实的CLI tools的例子，Playwright近日就发布了一个新项目，叫playwright-cli[8]，就是把浏览器工具封装成了一套CLI的形式。

那么，MCP tools如果和CLI tools比较起来，会怎么样呢？

第一个不同，可能在于，MCP tools会消耗大量的token，而CLI tools很可能会选择把大量的文本写入文件。当然了，这其实也跟MCP协议本身没有直接关系。可能只是因为，MCP毕竟是个更类似于函数调用的形式，运行结果通过函数输出返回给LLM，是更方便也自然的一个设计。

第二个不同，MCP可以比较方便地调用远程的服务，而CLI是本地命令。但这也只是形式上的区别。CLI是本地命令不假，但不代表它就不能执行远程的功能。

第三个不同，可能更贴近本质：MCP是大模型时代从头设计出来的新技术，而CLI则是存在了几十年的工具形式，几乎在计算机被发明初期就存在了。新技术自然免不了需要教会模型更好地使用它，也同时需要一大堆工程架构来支撑它；而CLI可能模型早就懂得如何使用了（碰到不懂的时候还可以用Skills来指导模型）。值得一提的是，MCP是依照软件开发范式设计出来的，而CLI则是设计给人使用的。

最后，从逻辑上看，Skills基本上是独立于工具的概念，它可以和各种形式的工具配合使用。比如：
* Skills + CLI tools；
* Skills + MCP tools；
* Skills + System tools；
* ...

至于说，最终是CLI tools取代MCP tools，还是反过来，或者是两种会长期共存？技术的进化是个很复杂的过程，既有路径依赖，又有跳跃式的变革，现在预测可能还为时尚早。关键是理清楚其中的关键点，作为技术管理者你就知道如何提前布局。

### MCP servers资源汇总

最后，列出一些网上公开的MCP servers。大家可以组合这些MCP工具和`ReCentAutoma`，尝试玩出一些新的花样。当然了，对于开发agentic自主性系统来说，今天介绍的只是非常基础的技术。对于更复杂的自主性任务，如何才能精确地控制它，会涉及到更多本质的东西。我们后面再跟大家分享。

* Anthropic官方收录的MCP服务器。既包含基础的文件系统工具、Git工具、Browser工具，也包含与各大厂商对接的MCP服务器。地址： <https://github.com/modelcontextprotocol/servers>
* 一些MCP广场：
  - 魔塔社区MCP广场： <https://www.modelscope.cn/mcp>
  - 阿里云百炼MCP广场： <https://bailian.console.aliyun.com/cn-beijing/?tab=app#/mcp-market>
  - MCPMarket： <https://mcpmarket.com/zh>
* 国外一些第三方收录的MCP服务器：
  - <https://mcpservers.org/>
  - <https://mcp.so/servers?tag=featured>
  - <https://fastmcp.me/MCP/Explore>
* 自动化控制手机的MCP服务器： <https://github.com/mobile-next/mobile-mcp>

### 加入技术交流群

我建了一个“Bridgic开源技术交流群”，会在群里发布项目的开发进展及计划，并讨论/分享相关技术。感兴趣加入的朋友请前往Bridgic GitHub首页README中扫描二维码，并欢迎在GitHub给个star！

> 💾 **Bridgic：一个支持动态拓扑的AI智能体框架：**  
> [点击这里直达GitHub首页 ➜ https://github.com/bitsky-tech/bridgic](https://github.com/bitsky-tech/bridgic)

（正文完）

##### 参考文献：
* [1] From Bridgic-Docs. [ReCentAutoma](https://docs.bridgic.ai/latest/tutorials/items/agentic_module/about_recent_automa/).
* [2] From Bridgic-Docs. [MCP](https://docs.bridgic.ai/latest/tutorials/items/protocol_integration/mcp_quick_start/).
* [3] From Bridgic-Docs. [ReActAutoma](https://docs.bridgic.ai/v0.2.1/reference/bridgic-core/bridgic/core/agentic/#bridgic.core.agentic.ReActAutoma).
* [4] From GitHub. [playwright-mcp](https://github.com/microsoft/playwright-mcp).
* [5] From GitHub. [recent_browser_gold_price.py](https://github.com/bitsky-tech/bridgic-examples/blob/main/agentic/recent_browser_gold_price.py).
* [6] From GitHub. [bridgic-examples](https://github.com/bitsky-tech/bridgic-examples).
* [7] From Claude Code Docs. [Extend Claude Code - MCP servers](https://code.claude.com/docs/en/features-overview#mcp-servers).
* [8] From GitHub. [playwright-cli](https://github.com/microsoft/playwright-cli).

**其它精选文章**：

* [AI智能体纪元或将从2026开始归零](https://mp.weixin.qq.com/s/h8kS6dpoX2YC771M0nGrAA)
* [基于动态拓扑的Agent编排，原理解析+源码下载](https://mp.weixin.qq.com/s/FNAS-xp1RYAQfZj2nXLSCg)
* [【开源】智能体编程语言ASL——重构智能体开发体验](https://mp.weixin.qq.com/s/D89UVC-0F0AGcjUbkdJjrw)
* [【开源】我亲手开发的一个AI框架，谈下背后的思考](https://mp.weixin.qq.com/s/d2lADFG5m8pZ31v8epUhHQ)
* [一文讲透AI Agent开发中的human-in-the-loop](https://mp.weixin.qq.com/s/fNN32CGANMeAr_wlvhxtWA)
* [AI Agent时代的软件开发范式](https://mp.weixin.qq.com/s/vejqEv5hACcbT15b4Xe5LQ)
* [AI Agent的概念、自主程度和抽象层次](https://mp.weixin.qq.com/s/dJAWleHyOWd8FPqH5ZqDWw)
* [科普一下：拆解LLM背后的概率学原理](https://mp.weixin.qq.com/s/gF-EAVn0sfaPgvHmRLW3Gw)
* [分布式领域最重要的一篇论文，到底讲了什么？](https://mp.weixin.qq.com/s/FZnJLPeTh-bV0amLO5CnoQ)
