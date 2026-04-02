---
layout: post
category: "ml"
title: "【开源】我亲手开发的一个AI框架，谈下背后的思考"
date: 2025-11-05 00:00:00 +0800
published: true
---

有不少读者朋友发来私信询问，如果要开发AI Agent应该如何对AI框架进行选型。这确实不是一两句话能够说清楚的，因为我觉得也不好选🤦 

一方面，虽然市面上选择很多，但各自的差异也比较大，没有能“包治百病”的。另一方面，在我看来各种方案都不够好：要么代码臃肿，概念堆砌；要么就是各种黑盒方案，在生产环境很不可控...

<!--more-->

当然了，要开发复杂一点的AI应用，还是需要框架的，否则难不成每次都从零开始编码吗？于是，我们就手搓了一个新的、**支持动态拓扑的AI智能体框架，名字叫Bridgic**。在我们自己使用的同时，现在也开源出来，算是为了人类早日实现AGI贡献一份力量吧🔥

> 💾 **下载链接：**  
> [点击这里下载源码 ➜ https://github.com/bitsky-tech/bridgic](https://github.com/bitsky-tech/bridgic)

不过本文的主要目的还不是介绍Bridgic框架如何使用（文末会附上专门的使用文档）。由于第一个版本我亲手写了大半的代码，所以对于中间碰到的一些技术设计问题有深切的体会。在这里我就讲讲背后的一些思考，涉及到“如何看待智能体”这样的第一性的问题，也涉及到很多工程原则，也许会对大家如何开发智能体和如何做架构选型有参考价值吧。

### 再谈智能体的自主性

我们在《[AI Agent的概念、自主程度和抽象层次](https://mp.weixin.qq.com/s/dJAWleHyOWd8FPqH5ZqDWw)》一文中曾经讨论到，Agent这个词在不同语境下有不同的含义。更好的一个词汇是`Agentic System`，这个概念既包含了确定性的workflow，也包含了完全自主规划的autonomous agent，当然还包含了任何介于两者之间的东西。

首先，我们在设计系统底层的时候，就需要一套统一的概念，对这个可能具有不同自主程度的Agentic System进行统一的描述。只有这样，才能把各种不同的智能组件纳入到一个系统里面来无缝工作。在这里，**系统是否建立在一套统一的概念基础之上，就是一个很重要的设计决策**，也是一个涉及到第一性的问题。有些同学可能知道，在很多早期的智能体项目中，或者只具备描述workflow的能力，或者只具备描述agent的能力，或者干脆用两套不同的概念对两者进行各自的描述。这样提供出来的方案就是充满了割裂和违和感的，日后也很难扩展。

在Bridgic的最底层，我们把智能体世界的万事万物都归结到两个核心概念之上。**一个叫worker，一个叫automa**。有了这两个概念，我们才能有进一步的讨论。

* **Worker**是最基本的执行单元。落实到实际系统当中，它可能代表了一段精确执行的逻辑（比如一个function，或一个API调用），也可能是具备高度自主性的模块或系统，或者是一个可调用的工具。换句话说，任何一个实体，只要它有能力take action，不管它的自主性程度如何，都能使用worker这个概念来描述。
* **Automa**是用来管理、编排和调度多个worker的那个实体。它是一个执行容器，自身不会直接处理任务，而是通过驱动它所管理的那些worker的执行，来完成更高层面的一个任务。落实到实际系统中，一个workflow，或者一个agent，或者任何的一个agentic system，都可以用一个automa来描述。

[<img src="/assets/images_bridgic_reflection/automa_workers_basic.png" style="width:500px" alt="Automa和Worker" />](/assets/images_bridgic_reflection/automa_workers_basic.png)

接下来就引出了另一个重要的问题：automa驱动worker执行的顺序，是怎么决定的？在一个确定性的workflow中，执行次序很可能是预先定义好的 (predefined) ；而在一个高度自主的agent中，每一步的执行次序很可能是模型动态规划出来的。

这就涉及到了**第二个核心的设计决策：automa对于worker的执行次序的编排，底层应该用什么方式来承载？**

这需要我们来重新审视一下，AI Agent的自主性对于编排这件事有什么本质上的、不同的要求，它的能力边界应该划定在什么地方。在我之前的《[AI Agent的概念、自主程度和抽象层次](https://mp.weixin.qq.com/s/dJAWleHyOWd8FPqH5ZqDWw)》一文中，我们得到了一个重要结论：各种不同的Agentic System，它们所呈现出来的不同程度的自主性，本质在于**系统编排的执行路径是在何时决策的**。总共分成了三种编排时机：
* 静态编排（图纸式执行）：执行路径的每一步都是提前确定好的。
* 程序动态编排（锦囊式应对）：具体执行时的路径只能根据输入数据动态确定。
* 自主编排（LLM带来的自主性）：没法提前设想所有的可能情况，执行路径也需要根据执行动态现场确定。

理论上来说，静态编排使用DAG (Directed Acyclic Graph) 就可以表达；程序动态编排一般来说需要使用DG (Directed Graph) 来表达，很可能有动态的分支或循环。在另一篇文章《[AI Agent时代的软件开发范式](https://mp.weixin.qq.com/s/vejqEv5hACcbT15b4Xe5LQ)》中，我们已经分析过，这里的**程序动态编排**，就处于等同于DG编排的动态性水平层次上，而**LLM带来的自主性（自主编排），是AI Agent时代软件开发中「新」的特性**。DAG和DG都是基于图的编排，那么这里就需要思考一个问题：为了支撑LLM带来的自主性，基于图的编排是否具备足够的表达能力？

理想中的编排方案可能是这样的：
* 统一的底层：使用一种统一的编排方式，同时支撑三种不同程度的自主性编排。
* 进化的适应性：随着未来模型智能程度的不断提升，底层的编排架构不用进行调整。一方面，模型的能力还在飞速提升，系统的底层机制不能被轻易颠覆。另一方面，我们正处于一个从传统技术向着AGI不断前进的历史进程当中，从确定性到自主性，这个历史进程可能会经历相当长的历史时期。我们需要底层架构具备足够的适应性来帮助我们穿越广大的「中间地带」。

把这个问题拆解一下，会看得更清楚。

[<img src="/assets/images_bridgic_reflection/automa_dag.png" style="width:450px" alt="Automa静态编排举例" />](/assets/images_bridgic_reflection/automa_dag.png)

上图表达了一个**静态编排**的例子，几个worker之间的执行次序是提前预定义好的。worker_1先执行；然后是worker_2和worker_3并发执行；最后是worker_4执行。

[<img src="/assets/images_bridgic_reflection/automa_routing.png" style="width:450px" alt="Automa动态分支举例" />](/assets/images_bridgic_reflection/automa_routing.png)

[<img src="/assets/images_bridgic_reflection/automa_loop.png" style="width:350px" alt="Automa动态循环举例" />](/assets/images_bridgic_reflection/automa_loop.png)

以上两个图，它们分别表达了动态的分支和循环。所有这些，都可以用DG/DAG来表达。

但是，LLM带来的自主性就不同了。一个例子是**模型的动态任务拆分**，模型把一个复杂的任务拆成若干个子任务，子任务的数量以及每个子任务是什么，你都无法在编码的那一刻完全确定。也就是说，我们没法提前确定需要创建几个worker实例来运行这些子任务。另一个常见的例子是**工具的动态选用**，在一个agent loop中，每次模型都会选择若干个工具来执行。这个时候你也无法提前确定每次调用工具的数量，以及哪些工具会被调用。我们如果底层统一用worker这个概念来表达工具的话，那么worker的创建也需要是动态的。

[<img src="/assets/images_bridgic_reflection/automa_ddg.png" style="width:800px" alt="Automa DDG举例" />](/assets/images_bridgic_reflection/automa_ddg.png)

像上图一样，我们增加一个时间维度，随着时间的流逝，允许图的拓扑在一定的限定条件下发生变化。这样我们就得到了一幅动态的图景，称之为**动态有向图 (Dynamic Directed Graph) ，简称为DDG**。Bridgic就是将底层构建在DDG之上的，允许一边执行一边修改图的拓扑。这一特性被称为**动态拓扑 (Dynamic Topology)**。

小结一下：

* Bridgic建立在统一的概念基础之上 (worker和automa) ，得以将各种不同的智能组件纳入到一个系统。
* Bridgic将编排方式统一于DDG之上，得以同时支撑各种不同程度的自主性（以及未来更高智能程度的自主性）。

这也是Bridgic这个名字的由来，它表示「Bridging Logic and Magic」，将代表精确性、确定性的logic和代表创造性、自主性的magic无缝地结合起来。

除此之外，对于automa的设计，还有一个蛮有意思的地方：`Automa`是`Worker`的子类。这表示，一个automa不仅是个执行容器，它在对外表现上还是个worker。这允许automa之间进行灵活地嵌套组合，是组件化编程的基础（下面会介绍）。

### Bridgic框架的核心特性

**模块化和组件化**

我们相信，随着AI Agent开发持续发展，它会变得越来越复杂。这种复杂度同样需要构建大型软件的传统智慧——借助模块化和组件化来解耦和复用代码。我们前面对于worker和automa概念的统一抽象，天然支持模块化和组件化。借助worker和automa，我们能够对任何粒度的智能或逻辑进行模块化的建模。

古老的软件设计格言告诉我们：使用「组合」而非「继承」来复用软件。在AI Agent开发中也同样如此。假设我们已经有了一个实现ReAct loop的组件（在Bridgic的实现中称为`ReActAutoma`）。现在随着工具数量的增多，我们需要前置增加一个工具的筛选模块，基于动态的用户输入，通过相似度+其他规则先对工具进行预选。这里就需要一个完美的组合复用。

[<img src="/assets/images_bridgic_reflection/automa_nesting.png" style="width:600px" alt="Automa 嵌套举例" />](/assets/images_bridgic_reflection/automa_nesting.png)

如上图，worker和automa允许层次化地嵌套组合。这种组件化复用方式，也为我们带来了关于如何构建智能体的新视角：通过组合不同自主化程度的智能化组件，像搭积木一样构建起新的Agentic System。

总之，模块化和组件化是Bridgic的一个基本设计原则，后面还会有更多相关特性加入进来。

**动态性**

借助DDG (Dynamic Directed Graph) 的动态拓扑能力，Bridgic提供了最强的编排动态性。这体现在框架设计的很多方面。比如，在Bridgic的ReAct实现中，工具列表是可以作为动态参数传入的，而不必在初始化时固定死。这就为工具的动态筛选提供了基础（而且是以组件化复用的方式）。再比如，一个工具的执行是以单worker实例的粒度来提供支持的。这使得基于Bridgic构建的软件模块能够以最细的粒度来享用框架提供的底层能力（如可观测性、human-in-the-loop、callback回调等机制）。

针对前面提到的「程序动态编排」，Bridgic提供了一个`ferry_to()` API，允许Agent开发者使用自然的方法调用这种方式来控制动态分支或循环。一般来说，DAG和循环逻辑是有冲突的，但如果没有DAG的显式依赖，等待多个并发分支同步完成的能力就很难实现[1]。在DDG中，预定义的执行依赖和动态的程序控制流通过严格的语义定义被整合到一起。详情请参阅项目文档的Basics章节[2]。

**Parameter Binding**

前面提到的基于DDG的编排，决定了worker之间的控制流 (control flow) 。但是在任何的系统架构设计里面，也都会涉及到数据流 (data flow) 的问题。这是两个不一样的概念[3]。控制流表示worker之间的执行先后次序，而数据流则表示数据在worker之间的传递路径。

这里存在两个设计决策：
* 是否需要单独的数据流？
* 是否需要共享状态？

对于第一个问题，如果规定数据只能沿着控制流传递，那么会非常不方便，对编程造成很多障碍。所以，Bridgic设计了单独的数据流，也就是Parameter Binding机制（稍后细讲）。

对于第二个问题，虽然共享状态和数据流没有直接的逻辑关系，但是假如系统里存在一个共享状态池或memory，那么确实可以消除对数据流的依赖。在这种工作方式下，控制流驱动的每个执行步骤都去读写这份共享状态，从而使得在执行步骤之间不再需要显示地传递数据。我们认为，在系统的最底层如果存在一个共享的全局状态，是违反了Open-closed原则的[4]，这种耦合会随着软件层次逐步向上放大，不利于构建大规模运行的软件。当然，禁用全局状态，这并不妨碍在上层场景明确的语境下提供类似共享记忆之类的机制。

综上，Brigic采用了控制流+数据流混合的模式：
* 基于DDG的编排，决定控制流。
* Parameter Binding机制，决定数据流。

对于Parameter Binding机制的设计，我们严格遵循了「灵活易用」的原则，力求实现最自然的编程体验。这个机制包含了三个部分：
* Arguments Mapping： 具有直接依赖关系的worker之间的参数映射。
* Arguments Injection： 不具有直接依赖关系的worker之间的参数注入。
* Inputs Propagation： automa的入参向下传播的机制。

[<img src="/assets/images_bridgic_reflection/parameter_binding.png" style="width:600px" alt="Parameter Binding机制" />](/assets/images_bridgic_reflection/parameter_binding.png)

可以从下面的一段代码示例中体会Parameter Binding的用法：

```python
from bridgic.core.automa import GraphAutoma, worker
from bridgic.core.automa.args import ArgsMappingRule, From

class DataProcessor(GraphAutoma):
    @worker(is_start=True)
    async def generate_data(self, bound: int) -> list:
        return list(range(1, bound + 1))

    @worker(dependencies=["generate_data"])
    async def calculate(self, data: list) -> dict:
        return {"sum": sum(data), "count": len(data)}

    @worker(dependencies=["calculate"], args_mapping_rule=ArgsMappingRule.UNPACK, is_output=True)
    async def output(self, bound: From(key="generate_data"), sum: int, count: int) -> str:
        return f"The bound is {bound}. The length of data is {count} and their sum is {sum}."
```

**Human-in-the-Loop**

Bridgic针对两种不同的技术场景，为长程智能体的开发提供了两套human-in-the-loop的机制：

* 场景一：client端和server端之间具备长连接的能力，且系统能够以某种方式做到会话保持。Bridgic提供了**Feedback Request Mechanism**，支持异步await及恢复。
* 场景二：client端和server端之间不需要保持会话。Bridgic提供了**Human Interaction Mechanism**，支持automa的序列化、中断、持久化、反序列化。

关于human-in-the-loop的系统化论述，请参阅《[一文讲透AI Agent开发中的human-in-the-loop
](https://mp.weixin.qq.com/s/fNN32CGANMeAr_wlvhxtWA)》；实现原理请参阅《[人类在环智能体源码展示：企业报销工作流举例](https://mp.weixin.qq.com/s/XRW-pYoXPNHJO72kIETjxA)》。

**高度可定制化**

很多同学可能看到过下面的这幅漫画。在提供开箱即用的同时，让Agent开发者拥有对prompt的完全控制，是Bridgic的设计原则之一。我们坚信这是实现优秀的[上下文工程](https://mp.weixin.qq.com/s/nyD5Vc59FYO_ZUD8fSquJw)的前提。

[<img src="/assets/images_bridgic_reflection/show_me_prompt.png" style="width:400px" alt="Show Me the Prompt漫画" />](/assets/images_bridgic_reflection/show_me_prompt.png)

### 使用AI框架的目的

工程师们关注AI框架，通常来说有三种情况：

* 第一，**做原型开发**。很多时候，公司内一个AI项目能否立项，很大程度上取决于能够实现出来的效果怎么样。所以在真正立项之前，通常需要工程师先实现一个原型，快速验证一下技术上的可行性。这个时候，你就不能说，先花个几天时间学会如何使用框架，好容易理解了一大堆概念之后，才开始真正干活儿。开发原型最重要的就是要快。**Bridgic是一个能够快速上手的框架**，使用起来很自然。基本上你拿过开发文档来看一眼，就可以直接上手coding了。

* 第二，**在生产环境使用**。真的很认真地要上生产了，这个时候考虑因素就多了。AI框架要有足够的扩展性，开发者要能够对系统百分之百可控。有很多框架提供了开箱即用的一些模块，帮助你很快搭建起一个原型。但是，当你发现准确度不够想进一步调优的时候，却突然意识到这些模块都是一些黑盒，根本无从下手。这不是真正的软件复用。**Bridgic从底层支持基于组件化的软件复用，并提供足够开放的可定制化接口**，便于构建真正的生产级代码。

* 第三，**学习的目的**。AI时代，几乎所有的工程师都在转型。AI框架的代码中沉淀了很多AI编程模式，确实是个学习或入门AI编程的好材料。**Bridgic框架代码紧凑，底层概念设计统一、精简**，以异步编程为主线，同时支持多线程。一句话，Bridgic是学习AI编程、也是学习Python编程和异步编程的一份参考代码，很值得一读。

### 下载地址

Bridgic是一个强调动态性、强调组件化的AI编程框架，为智能体开发提供了一种崭新的实现。现在以最友好的MIT License开源了。

大家也知道，开源嘛，少不了为爱发电，觉得好的朋友给个star，表达下鼓励。

> [GitHub源码地址 ➜ https://github.com/bitsky-tech/bridgic](https://github.com/bitsky-tech/bridgic)  
> [官方文档地址 ➜ https://docs.bridgic.ai/](https://docs.bridgic.ai/)  

下面是我的微信，对Bridgic或Agent开发感兴趣，都欢迎加微讨论（加好友时请务必注明“来自公众号”哈）。

[<img src="/assets/personal_weixin_qr_code.jpg" style="width:400px" alt="张铁蕾的微信ID：zhtielei" />](/assets/my_weixin_public.jpg)

（正文完）

##### 参考文献：
* [1] Niko Nelissen. [Different types of workflows in data pipelines](https://medium.com/peliqan-io/different-types-of-workflows-in-data-pipelines-4b1d1aeb47fe).
* [2] From Bridgic Docs. [Basics](https://docs.bridgic.ai/latest/home/basics/).
* [3] From Wikipedia. [Dataflow programming](https://en.wikipedia.org/wiki/Dataflow_programming).
* [4] From Wikipedia. [Open–closed principle](https://en.wikipedia.org/wiki/Open%E2%80%93closed_principle).


**其它精选文章**：

* [一文讲透AI Agent开发中的human-in-the-loop](https://mp.weixin.qq.com/s/fNN32CGANMeAr_wlvhxtWA)
* [AI Agent时代的软件开发范式](https://mp.weixin.qq.com/s/vejqEv5hACcbT15b4Xe5LQ)
* [从Prompt Engineering到Context Engineering](https://mp.weixin.qq.com/s/nyD5Vc59FYO_ZUD8fSquJw)
* [AI Agent的概念、自主程度和抽象层次](https://mp.weixin.qq.com/s/dJAWleHyOWd8FPqH5ZqDWw)
* [技术变迁中的变与不变：如何更快地生成token？](https://mp.weixin.qq.com/s/BPnX0zOJr8PLAxlvKQBsxw)
* [科普一下：拆解LLM背后的概率学原理](https://mp.weixin.qq.com/s/gF-EAVn0sfaPgvHmRLW3Gw)
* [从GraphRAG看信息的重新组织](https://mp.weixin.qq.com/s/lCjSlmuseG_3nQ9PiWfXnQ)
* [企业AI智能体、数字化与行业分工](https://mp.weixin.qq.com/s/Uglj-w1nfe-ZmPGMGeZVfA)
* [分布式领域最重要的一篇论文，到底讲了什么？](https://mp.weixin.qq.com/s/FZnJLPeTh-bV0amLO5CnoQ)
