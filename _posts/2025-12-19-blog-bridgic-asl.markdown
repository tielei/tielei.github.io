---
layout: post
category: "ml"
title: "【开源】智能体编程语言ASL——重构智能体开发体验"
date: 2025-12-19 00:00:00 +0800
published: true
---

与传统的软件系统不同，智能体是天然具有「结构」的。

首先，单智能体内部，可以包含LLM、工作worker、工具等一系列内部模块。其次，多智能体是由多个子智能体组合而成的，不管是「agent as tool」还是其他的组合模式。第三，确定性的workflow和高自主性的agentic模块，在实际生产中是很可能出现在同一个系统中被组合使用的。这些都呈现出某种「结构」性信息。

<!--more-->

我们知道，**普通的编程语言善于表达「逻辑」，而非「结构」**！今天，我们以开源[Bridgic](https://docs.bridgic.ai/) 的[动态拓扑编排机制](https://mp.weixin.qq.com/s/FNAS-xp1RYAQfZj2nXLSCg)为基础，在其上构建了一门全新的**智能体编程语言——ASL (Agent Structure Language)** 。

话不多说，先上代码，感受一下它的样子。

```python
class Chatbot(ASLAutoma):
    with graph as g:
        # Define the `split_solve` sub-graph
        with graph as split_solve:
            b = break_down_query
            q = query_answer    
            +b >> ~q

        merge = merge_answers
        +split_solve >> ~merge
```

> 💾 注意：为讲解方便，以上只贴出了核心代码片段。下载完整可运行的代码请移步Bridgic项目首页，代码在README中：  
> [点击这里下载源码 ➜ https://github.com/bitsky-tech/bridgic](https://github.com/bitsky-tech/bridgic)

上面的这段ASL代码是什么意思呢？其实它的含义是非常直观的。它所表达的智能体结构如下图所示：

[<img src="/assets/images_bridgic_asl/chatbot_asl_structure.png" alt="Chatbot Structure Defined by ASL" width="75%" />](/assets/images_bridgic_asl/chatbot_asl_structure.png)

初识ASL，我们逐行地解释一下：

- 上面这段ASL定义了一个智能体，叫`Chatbot`。它内部嵌套了一个子工作流，叫`split_solve`。
- `with graph as split_solve`，表示打开了一个子图，名字为`split_solve`。然后就可以在它上面注册worker节点并指定依赖关系。
- `split_solve`内部由两个worker组成，一个是`break_down_query`，一个是`query_answer`。前者是把用户输入拆分成子查询，后者是分别回答各个子查询（具体代码可以查看前面的下载链接）。
- `b = break_down_query`，表示注册一个worker，并指定唯一的名字 (key) 为 `b`。`q = query_answer`的含义类似。
- `+b >> ~q`，这个表达式浓缩了很多信息。`+b`表示它是个start worker，编排的时候它会第一个执行。`~q`表示它是个output worker，会输出最终结果。`>>`表示依赖关系，具体到这个表达式，表示`b`执行完了再执行`q`。
- `with graph as g`，表示打开了最外层的一个图层`g`。在这个图层里，`split_solve`被整体当做一个worker来编排。
- `merge = merge_answers`，表示在最外层的图层中注册一个worker，并指定唯一的名字 (key) 为 `merge`。它具体做的事情是，把前面各个子查询的问答数据合并，得到一个最终的答案（具体代码从前面的链接下载）。
- `+split_solve >> ~merge`，表示`split_solve`作为start worker，执行完了再执行`merge`。而且，`merge`是个output worker。

现在回过头来，再重新对比一下前面的ASL代码和Chatbot的结构图，你会发现，ASL的表达能力已经**非常接近于所见即所得 (WYSIWYG)** ！构建一个智能体，不再需要add_node / add_worker，不再需要add_edge / add_dependency，这些看起来奇奇怪怪的调用统统都可以不要了！真的是一眼秒懂💡

接下来，本文分成三个部分进行介绍：
* 介绍Bridgic的API层次（和ASL的位置）。
* ASL的典型用法（包括如何表达动态路由和动态拓扑）。
* 讨论ASL设计背后的思考。

### Bridgic的API层次

加入ASL之后，Bridgic的编程视图就相对比较完整了。现在我们可以讲一讲Bridgic的API设计层次了。

[<img src="/assets/images_bridgic_asl/bridgic_api_hierarchy.png" alt="Bridgic API Hierarchy" width="75%" />](/assets/images_bridgic_asl/bridgic_api_hierarchy.png)

首先是 **Core API**，它是Bridgic最底层的编排架构所暴露的编程API。开发者如果直接使用这一层API，那么他需要调用`add_worker`、`add_dependency`等API，来显式地组装动态图结构。

当然，对比其他智能体框架，Bridgic的Core API这一层具有鲜明的特点：它构建于[动态拓扑](https://mp.weixin.qq.com/s/FNAS-xp1RYAQfZj2nXLSCg)之上，因此天然就**取消了建图后不必要的「编译」操作**。也就说，你调用完`add_worker`等API将图的初始结构建立起来之后，立即就可以去运行它。而且在运行过程中，你仍然可以调用Core API里面的任何接口来继续修改拓扑。真正做到了 **No Compilation Needed**! 这样的设计还有其他好处，你甚至可以混合使用Core API和它上层的其他API形式，来操纵Bridgic的底层动态有向图[DDG (Dynamic Directed Graph)](https://mp.weixin.qq.com/s/FNAS-xp1RYAQfZj2nXLSCg) 。

另外值得注意的是，Bridgic提供的一些核心能力，都根植于Core API这一层。比如说，对于[可观测性能力的集成](https://mp.weixin.qq.com/s/TjEt1bhbnPK46JugHOdBVA)；再比如，对于[序列化和反序列化](https://mp.weixin.qq.com/s/fNN32CGANMeAr_wlvhxtWA)能力的支持，都在这一层。这样的话，我们不管是直接使用Core API还是更上层的API开发出来的智能体，都天生具备可观测能力，天生支持长程智能体的human-in-the-loop。

在Core API之上，Bridgic又提供了两种API：

* 一个是**Declarative API （声明式API）**。指的是通过`@worker`这样的Python装饰器来构建智能体的编程方式。
* 另一个就是**ASL (Agent Structure Language)** ，一门全新的智能体开发语言，把模块化和组件化编程的思想发挥到了极致。我们随后就会介绍它的诸多特性。

在进一步讨论之前，我们将前面的`Chatbot`的例子分别用Bridgic的三种API进行改写，来对比一下各自的优劣势。如下图（点击看大图）：

[<img src="/assets/images_bridgic_asl/compare.jpg" alt="Bridgic三种API代码示例比较" width="100%" />](/assets/images_bridgic_asl/compare.jpg)

以上对比图中需要补充的一些点：
* 使用`@worker`装饰器的方式并不支持结构的嵌套。因此，上图最右侧的代码在`Chatbot`中直接调用`split_solve.arun`的做法，是不推荐的。这可能会造成Bridgic底层依赖结构信息的一些核心能力工作不正常，比如tracing和human-in-the-loop。如果非要实现将`SplitSolveAgent`嵌套在`Chatbot`的结构里面，只能和Core API配合一起使用。
* ASL的表达能力比较灵活，上图最左侧的ASL代码示例不止有一种写法。比如，它还可以写成下面的样子（一种更模块化的写法）：

```python
class SplitSolveAgent(ASLAutoma):
    with graph as g:
        b = break_down_query
        q = query_answer

        +b >> ~q

class Chatbot(ASLAutoma):
    with graph as g:
        split_solve = SplitSolveAgent()
        merge = merge_answers

        +split_solve >> ~merge
``` 

### ASL的典型用法

#### 1，表达动态路由（分支）

```python
class SimpleRouter(ASLAutoma):
    with graph as g:
        start = routing_request
        hq = handle_question
        hg = handle_general

        +start, ~hq, ~hg
```

`+start`表示它是个start worker；`~hq`和`~hg`表示它们都是output worker。但是，这三个worker之间的依赖关系不是静态指定的。`routing_request`方法里面通过`ferry_to`来实现动态路由：

```python
async def routing_request(
    request: str,
    automa: GraphAutoma = System("automa"),
) -> str:
    if "?" in request:  # Route using a simple rule that checks for "?"
        automa.ferry_to("hq", question=request)
    else:
        automa.ferry_to("hg", question=request)
```

#### 2，表达并行与合并

```python
class AdderAutoma(ASLAutoma):
    with graph as g:
        s = worker_1
        w2 = worker_2
        w3 = worker_3
        o = sum

        +s >> ( w2 & w3 ) >> ~o
```

这段ASL代码表达的拓扑如下图所示：

[<img src="/assets/images_bridgic_orchestration/static_orchestration_example.png" alt="静态编排图例AdderAutoma" width="60%" />](/assets/images_bridgic_orchestration/static_orchestration_example.png)

#### 3，表达动态拓扑

ASL另一个强大的地方在于，它能用一种声明式的方式来表达动态拓扑。下面是代码示例：

```python
async def produce_task(user_input: int) -> List[int]:
    tasks = [i for i in range(user_input)]
    return tasks

async def task_handler(sub_task: int) -> int:
    res = sub_task + 1
    return res

class DynamicGraph(ASLAutoma):
    with graph(user_input=ASLField(type=int)) as g:
        producer = produce_task

        with concurrent(tasks = ASLField(type=list, dispatching_rule=ResultDispatchingRule.IN_ORDER)) as c:
            dynamic_handler = lambda tasks: (
                task_handler *Settings(key=f"handler_{task}")
                for task in tasks
            )

        +producer >> ~c
```

在这段ASL代码中，我们在`concurrent`容器内部动态创建了多个执行`task_handler`的worker实例。这些实例的个数等到运行时才能根据输入参数确定下来，因此`DynamicGraph`实现了一个在执行过程中仍然在动态改变的拓扑结构。如下图所示：

[<img src="/assets/images_bridgic_asl/dynamic_topo.png" alt="ASL动态拓扑示例" width="50%" />](/assets/images_bridgic_asl/dynamic_topo.png)


#### 4，ASL更多用法

ASL还有很多灵活的表达方式，限于篇幅不一一介绍了。详情参见文末给出的文档链接。

### ASL设计背后的思考

为什么会有ASL？

要回答这个问题，我们就需要追溯到智能体与传统软件系统的本质区别上去。我在之前的文章《[我亲手开发的一个AI框架，谈下背后的思考](https://mp.weixin.qq.com/s/d2lADFG5m8pZ31v8epUhHQ)》中总结过，不同的Agentic系统，它们会呈现出来各种不同程度的自主性。而再往实现层面走近一步，我们会发现，这些不同自主程度的智能体，它们不是凭空产生的，而是由更低维度的、待编排的结构组合而成的。这些待编排的「结构」，成为智能体的基本执行单元，在Bridgic里称之为worker。

总之，智能体是呈现出「结构」的。首先，确定性的workflow有它的结构，worker之间存在预定义好的依赖关系；其次，自主agent也有它的结构，包含工具、模型、planner，等等元素；第三，workflow和自主agent可以组成更大的系统，在这一层面也展现出某种结构。

为了清晰地表达智能体的这种「结构」特征，我们发现，传统编程语言的表达能力是不够的。因此，对智能体的表达方式需要被重构，于是就有了ASL。有了它之后，**一个智能体的「执行逻辑」和「结构」这两部分，就可以分别使用最恰当的方式来表达：前者使用Python代码，而后者就使用ASL**。

有人会问，既然要表达结构，那为什么不使用可视化编排（或搭建）呢？回到[智能体的自主性本质](https://mp.weixin.qq.com/s/dJAWleHyOWd8FPqH5ZqDWw)，LLM带来的自主性（执行路径需要根据执行动态现场确定），才是智能体时代软件开发中「新」的特性。未来的开发范式，肯定是朝着更动态性、更自主性的系统架构方向发展。而可视化编排，通常要求在程序执行之前就编排出整个Workflow的结构，这对于自主系统的支持是非常有限的。我宁愿把可视化编排看成是上一个时代的遗产，而非未来的新事物。

另外，使用Python装饰器（类似`@worker`），也是表达智能体（尤其是workflow）的常见的一种方式。但这种方式同样不具有足够的表达能力（详见本文前面对Bridgic的三种API的比较）。

当然，ASL还有很多待完善之处。未来它会往哪个方向进化呢？我们当前并不能准确预测。但是，它一定是向着更agentic的方向生长出更多的能力。在未来，ASL所编排的也一定不仅仅是静态的流程；也许，它需要编排的是某种「元认知」层面的东西。

### 源码下载

> [Bridgic源码地址 ➜ https://github.com/bitsky-tech/bridgic](https://github.com/bitsky-tech/bridgic)  
> [Bridgic文档地址 ➜ https://docs.bridgic.ai/](https://docs.bridgic.ai/)  
> [ASL教程地址 ➜ https://docs.bridgic.ai/latest/tutorials/items/asl/quick_start/](https://docs.bridgic.ai/latest/tutorials/items/asl/quick_start/)  

### 加入技术交流群

我建了一个“Bridgic开源技术交流群”，后面会在群里发布项目的开发进展及计划，并讨论相关技术。感兴趣的朋友可以扫描下面的二维码进群。如果二维码过期，请加微信ID: zhtielei，备注“来自Bridgic社区”。

[<img src="/assets/bridgic_group_chat_qr_code.png" style="width:300px" alt="Bridgic技术交流群二维码" />](/assets/bridgic_group_chat_qr_code.png)

（正文完）

**其它精选文章**：

* [谈谈智能体开发和可观测性](https://mp.weixin.qq.com/s/TjEt1bhbnPK46JugHOdBVA)
* [基于动态拓扑的Agent编排，原理解析+源码下载](https://mp.weixin.qq.com/s/FNAS-xp1RYAQfZj2nXLSCg)
* [【开源】我亲手开发的一个AI框架，谈下背后的思考](https://mp.weixin.qq.com/s/d2lADFG5m8pZ31v8epUhHQ)
* [一文讲透AI Agent开发中的human-in-the-loop](https://mp.weixin.qq.com/s/fNN32CGANMeAr_wlvhxtWA)
* [AI Agent时代的软件开发范式](https://mp.weixin.qq.com/s/vejqEv5hACcbT15b4Xe5LQ)
* [AI Agent的概念、自主程度和抽象层次](https://mp.weixin.qq.com/s/dJAWleHyOWd8FPqH5ZqDWw)
* [技术变迁中的变与不变：如何更快地生成token？](https://mp.weixin.qq.com/s/BPnX0zOJr8PLAxlvKQBsxw)
* [科普一下：拆解LLM背后的概率学原理](https://mp.weixin.qq.com/s/gF-EAVn0sfaPgvHmRLW3Gw)
* [分布式领域最重要的一篇论文，到底讲了什么？](https://mp.weixin.qq.com/s/FZnJLPeTh-bV0amLO5CnoQ)
