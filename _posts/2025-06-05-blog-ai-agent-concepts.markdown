---
layout: post
category: "ml"
title: "AI Agent的概念、自主程度和抽象层次"
date: 2025-06-05 00:00:00 +0800
published: true
---

从事AI的人都知道，如果你现在没有在搞Agent，出门都不好意思跟人打招呼。

但是，到底什么是Agent呢？恐怕专家们也未必说得清楚。这实在怪不到谁的头上，谁让这个概念的含义竟如此宽泛呢？

本文集中精力讨论清楚三件事：
* 当前业界对Agent最新的定义是什么？有没有共识？
* 不同类型的Agent在自主程度上的不同，本质是什么？
* 为了把Agent设计好，需要做哪些抽象？

<!--more-->

### 到底什么是Agent？

AI圈内人讨论Agent的时候，通常是比较纠结的。经常发生的一个场景是，你要时不时地重述一下当前谈论的「Agent」，它具体指的是什么，才能保证接下来的讨论是一个严谨的过程。这种尴尬局面形成的原因是，Agent这个词在不同语境下有不同的含义。

在AI领域，Agent这个词的起源非常非常早，很可能在上个世纪50年代就在学术讨论中出现了。截至目前，比较为人所熟知的学术上的出处，来自于强化学习理论。强化学习中的Agent，是一个精确的理论概念，它指的是一个可以与环境交互的、有明确目标的、能够在经验中学习的，并且能主动执行某种新的action去探索未知的实体。这里所说的，既能在经验中学习，又能主动执行新的action，其实就是我们在机器学习中经常碰到的Exploitation和Exploration的权衡问题。

但是，当前在企业AI落地的场景中，以及在AI投资圈，大家所谈论的Agent概念，应该说是随着LLM的出现而发展出来的新概念。一般来讲，Agent指的是基于LLM技术实现出来的一种自主的 (autonomous) 智能系统。如果你仔细想一下，这个Agent与前面强化学习中的Agent，其实不是一个概念。这里的Agent强调的是，它能够完成真实世界的某种复杂任务（以某种自主的方式）；而强化学习Agent主要强调它如何从与环境的交互中学习。但是，很多人希望Agent系统具备「自主进化」的能力，这似乎是有点挪用了强化学习Agent的概念了。

更麻烦的是，当前AI业界对于Agent一词的使用，仍然存在至少两种解释。一种是泛指的概念，一种是特指的概念。
* 泛指：凡是使用了LLM搭建出来的能够完成某种任务的AI系统，都可以称为Agent。那么，根据这个理解，我们常见的chatbot，我们使用Dify、n8n搭建出来的workflow，以及完全自主规划的系统 (Autonomous Agent)，都叫Agent。
* 特指：完全的自主系统。在实现层面，一般来说是由agent loop驱动的一种专门的AI系统。在每一个循环迭代中，它借助LLM动态决策，自动调用适当的工具，存取恰当的记忆。每经过一次循环，就向着任务目标前进一步。很多公司推出的Deep Research产品或技术，一般来说都是这种类型的Agent。再举两个自主Agent的例子：
  * LlamaIndex对于自主Agent的特化实现[1]。
  * Anthropic著名的“Building effective agents”的blog[2]中，提到的最后一种Autonomous Agent模式。如下图：

[<img src="/assets/images_agent_concepts/autonomous_agent_from_anthropic.png" style="width:600px" alt="Autonomous Agent" />](/assets/images_agent_concepts/autonomous_agent_from_anthropic.png)

鉴于Agent概念的混乱不堪，很多思维敏捷的AI技术大佬已经开始出来澄清概念。这其中值得一提的，包括Anthropic的一篇blog[2]、LangChain创始人的一篇blog[3]、LlamaIndex的一篇官方文档[4]，还有吴恩达的一个采访[5]。根据这些言论或资料，当前业界似乎对于Agent概念逐步达成了如下的共识：
* Workflow和Autonomous Agent之间并不存在「非黑即白」的界限。这些系统之间，只是自主性的程度不同。大家普遍开始用`Agentic System`来取代原来宽泛的、意义模糊的Agent概念。关于Agentic System一词，尤其以LangChain的创始人的说法最为清晰，原文如下[3]：

> In practice, we see that most “agentic systems” are a combination of workflows and agents. This is why I actually hate talking about whether something is an agent, but prefer talking about how agentic a system is.
>  
> 译文：  
> 在实际中，我们发现大多数“agentic system”都是workflow和agent的组合。这也是为什么我其实不喜欢讨论某个东西是不是一个agent，而是更倾向于讨论一个系统有多么“agentic”。

### Agent的自主程度，本质是什么？

我们现在来仔细审视一下Anthropic的“Building effective agents”这篇blog[2]中的一些Agent设计模式。

[<img src="/assets/images_agent_concepts/prompt_chaining_from_anthropic.png" style="width:600px" alt="The prompt chaining workflow" />](/assets/images_agent_concepts/prompt_chaining_from_anthropic.png)

上图表达Prompt Chaining。对于模型的调用，是顺序执行的。整个workflow总共分几步完成，第一步做什么，第二步做什么，都是提前确定好的。

[<img src="/assets/images_agent_concepts/parallelization_from_anthropic.png" style="width:600px" alt="The parallelization workflow" />](/assets/images_agent_concepts/parallelization_from_anthropic.png)

这张图表达Parallelization的设计模式。与前一个模式的不同之处在于，Prompt Chaining是串行执行的，而Parallelization表示几个LLM调用是并行执行的。但是，不管是并行还是串行，执行路径都是提前确定好的。

[<img src="/assets/images_agent_concepts/routing_from_anthropic.png" style="width:600px" alt="The routing workflow" />](/assets/images_agent_concepts/routing_from_anthropic.png)

这张图表达的模式称为Routing，也就是三个LLM Call节点，只会选择其中一个执行。它与前面两种模式有一个明显的不同：Prompt Chaining和Parallelization的执行路径是提前确定好的，而Routing的执行路径必须等到输入数据来了才能真正确定。类比编程语言，Routing类似于if条件判断。

[<img src="/assets/images_agent_concepts/autonomous_agent_from_anthropic.png" style="width:600px" alt="Autonomous Agent" />](/assets/images_agent_concepts/autonomous_agent_from_anthropic.png)

这张图表示Autonomous Agent模式（本文开头展示过）。这种模式的自主程度更进一步。在前面的Routing模式下，虽然具体的执行路径是根据输入数据动态确定的，但三条可选的执行路径至少还是提前确定的。而在Autonomous Agent模式下，具体执行路径也是无法提前确定的。系统通常执行多个轮次/步骤，每一步执行什么Action无法提前确定，总共会执行多少步也无法提前确定。

以上这几种Agent设计模式并非全部可能的情况，但是，基本展示了一个Agent（或者更准确地说，一个`Agentic System`）的三种不同的自主性程度。不同程度的自主性，本质在于，**系统编排的执行路径是在何时决策的**：
* **静态编排**：类似于Prompt Chaining和Parallelization，执行路径是完全提前确定好的。这就好比，设计师给了你一张非常详尽的「图纸」，你只需要按照预定的「图纸」去执行就好了。
* **程序动态编排**：类似于Routing模式。可能的执行逻辑和可能的执行路径，是提前确定好的，但具体执行时的路径只能根据输入数据动态确定。这就好比，诸葛亮给了你若干个「锦囊」，并且告诉你如果遇到什么样的麻烦，就拆开看哪个「锦囊」。总之，相当于是提前想好了应对各种可能情况的措施。
* **自主编排**：类似于Autonomous Agent模式。没法提前设想所有的可能情况，执行路径也需要根据执行动态现场确定。通常来说，Autonomous Agent可能会根据实际情况现场编写程序来解决问题。这就好比，「将在外，君令有所不受
」，在外带兵的将军，遭遇紧急情况只能权宜行事。

总之，从Prompt Chaining和Parallelization，到Routing，再到Autonomous Agent，系统的自主程度越来越高，人类工程师对于系统的精准控制力也逐步减弱，因此系统的行为也就越来越动态。当然通常来说，它能够处理的问题复杂度也就越来越高。

### 设计Agent的抽象层次

要把Agent设计好，并非只是了解模型算法技术或工程编程技术就可以了。设计Agent是一项在多层次上进行抽象的系统工程。

在最顶层，需要找到业务场景适配。一方面需要深入了解业务流程，知道业务价值大的地方在哪里；另一方面也需要理解以LLM为基础的AI技术的边界，它擅长解决什么问题。比如，销售领域是一个很大的领域，涉及到与各种类型的客户、代理商、还有平台之间的复杂的互动流程。其中一个典型的AI落地场景就在于新客户的outreach的自动化：对自家产品感兴趣的客户可能是通过网站、大会展位或者其他渠道留下了联系方式，下一步一般需要给客户发送邮件。这个邮件如果只是千篇一律地介绍自己的产品，那么转化率就不高。而针对客户做个性化的邮件撰写，正是当前生成式AI所擅长的。在熟知的领域内找到适合AI提效的场景，完成技术与业务的第一次适配，这个过程可能是需要业务专家和技术专家紧密配合的。

再往下一层要考虑的，是Agent以什么样的产品形态展现在目标用户面前。是一个chatbot就够了？还是在自动化基础上增加简单的human-in-the-loop的交互就够了？或者是针对更复杂的场景，像《[生成式AI和传统软件的分野和融合](https://mp.weixin.qq.com/s/9f61jeYdYP9TLxj3spYwCg)》这篇文章所提到的IVERS模式一样，需要产品与用户之间进行更复杂的指令下达、可视化反馈、以及后续多轮交互才行？比如在AI Coding领域，Cursor给我们提供了一个良好的Agent产品样例。这个层面的设计过程，需要专业的AI产品经理参与其中。

再往下是Agent粒度的拆解。这仍然是在业务流程抽象的层面，还没有真正到达AI技术层面。需要进行自动化的整个业务流程，是否能再分成更细小、更专业、目标也更明确的子流程？每个子流程可以单独实现成一个Agent，然后整体业务目标可以通过multi-agent协作的方式来完成。对于子流程的拆解，边界越清晰，目标越明确，实现出来的AI Agent也就准确率越高。再看一下前面的销售outreach场景，自动撰写个性化的营销邮件，至少可以分成两步：第一步，基于客户留下的线索去企业内部的情报数据库+公开的互联网搜索更多信息，对信息进行汇总形成对客户profile的描述（可能包括客户的背景、核心业务领域、当前关心的业务拓展方向，等等）。第二步，基于前一步形成的客户profile信息，结合自身产品撰写个性化的邮件内容。当然，一个完整的自动化产品也许还能自动完成最后一步，把邮件批量发送出去。这个层面的设计工作其实至关重要，与传统的BPM (Business Process Management) 建模、SOP (Standard Operating Procedure) 梳理，是一脉相承的思路。如果类比传统的软件开发的模式，这份工作则是属于DDD (Domain-Driven Design) 的手艺活。

再往下才到了Anthropic的“Building effective agents”这篇blog[2]所描述的那些Agent设计模式。这一层的抽象已经不涉及到业务概念了。Prompt Chaining，Routing，Parallelization，Orchestrator-workers，Evaluator-optimizer，Autonomous Agent，所有这些，与技术实现仅有一步之遥了。但这个层面的抽象仍然只是逻辑层面的。

再往下才是应用层代码、框架代码、LLM模型。真正AI技术层面的东西。

抽象能力是人类高级思维的皇冠。正是因为目前的LLM还没法完全复刻人类的这些思维过程，所以AI Agent的设计才需要人类专家和工程师来承担以上这些抽象工作。这些工作说来也实在有些复杂，一些内心本来就糊涂的「专家们」，自然也是搞不懂这么多抽象层次。因此，Agent一词的概念模糊，以及人们对Agent的缺乏共识，也就更好理解一些了。

### 文章最后

最后呢，预告一下，下次我打算结合具体的技术方案，对比一下LangGraph和LlamaIndex在实现Agent方面的异同和优劣。我们下次见。

PS：下次发文的时候，我可能会换个头像。大家可别认不出来了☺️

（正文完）

##### 参考文献：
* [1] [Agents (LlamaIndex)](https://docs.llamaindex.ai/en/stable/module_guides/deploying/agents/).
* [2] [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents).
* [3] [How to think about agent frameworks](https://blog.langchain.dev/how-to-think-about-agent-frameworks/).
* [4] [Agents (LlamaIndex)](https://docs.llamaindex.ai/en/stable/use_cases/agents/).
* [5] [Andrew Ng: State of AI Agents \| LangChain Interrupt](https://www.youtube.com/watch?v=4pYzYmSdSH4).

**其它精选文章**：

* [技术变迁中的变与不变：如何更快地生成token？](https://mp.weixin.qq.com/s/BPnX0zOJr8PLAxlvKQBsxw)
* [DSPy下篇：兼论o1、Inference-time Compute和Reasoning](https://mp.weixin.qq.com/s/hh2BQ9dCs1HsqiMYKf9NeQ)
* [科普一下：拆解LLM背后的概率学原理](https://mp.weixin.qq.com/s/gF-EAVn0sfaPgvHmRLW3Gw)
* [用统计学的观点看世界：从找不到东西说起](https://mp.weixin.qq.com/s/W6hSnQPiZD1tKAou3YgDQQ)
* [从GraphRAG看信息的重新组织](https://mp.weixin.qq.com/s/lCjSlmuseG_3nQ9PiWfXnQ)
* [企业AI智能体、数字化与行业分工](https://mp.weixin.qq.com/s/Uglj-w1nfe-ZmPGMGeZVfA)
* [三个字节的历险](https://mp.weixin.qq.com/s/6Gyzfo4vF5mh59Xzvgm4UA)
* [分布式领域最重要的一篇论文，到底讲了什么？](https://mp.weixin.qq.com/s/FZnJLPeTh-bV0amLO5CnoQ)
* [漫谈分布式系统、拜占庭将军问题与区块链](https://mp.weixin.qq.com/s/tngWdvoev8SQiyKt1gy5vw)
