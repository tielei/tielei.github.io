---
layout: post
category: "ml"
title: "技术变迁中的变与不变：如何更快地生成token？"
date: 2024-06-02 00:00:00 +0800
published: true
---

*未来何时到来，取决于我们能以多快的速度生成 token。*

随着GenAI的发展，我们迎来了一个崭新的技术时代。同时，由于LLM庞大的参数规模，在现代的AI系统中，LLM的推理 (inference) 性能就变得格外重要。提升LLM推理的性能，更快地生成token，意味着运营成本的降低。

<!--more-->

在本文中，围绕LLM推理服务的性能问题，我们将从以下几个方面展开讨论：
* 首先，**我们应该关心哪些性能指标？**跟传统的系统相比，有什么异同？问题的答案决定了系统设计目标，也决定了我们进一步思考的方向。
* 从性能的角度出发，如何理解系统的本质？我们追求fundamental的东西——那些不随着技术变迁而变化的原则。这要求我们透过系统表层的千变万化，**从底层逻辑的层面对系统进行建模**。
* 从理论回到现实，以vLLM为例，我们讨论一下，真实的推理系统是**做了哪些重要的优化**以提升性能的。在这部分，我们也会讨论一些影响推理性能的参数配置。
* 最后，我们结合前面分析的过程，**展开讨论下系统设计中的抽象思维**。这是比具体的知识更重要的东西。

### 再谈吞吐量和响应时间

我们应该关心哪些性能指标？这是系统设计中一个非常重要的问题。而且，这不是一个新问题。想想跑在互联网上的那些应用系统，诸如搜索引擎、Feeds流、电商交易系统，我们当时是怎么描述系统的性能的？

很多人会想到QPS (queries per second) 或 TPS (transactions per second)。没错，它们表达了系统的一个重要的性能指标，称为**吞吐量 (Throughput)**。QPS或TPS都是系统**吞吐量**的度量单位，表达了单位时间内系统所能处理的请求数。也可以用requests per second来表示。

吞吐量为什么重要？因为它表达了系统整体的处理能力。吞吐量越高，系统就可以用更少的资源来处理同样的请求，也就意味着更低的单位成本。

然而，我们只考虑吞吐量够用吗？答案是否定的。现代的系统很多都是在线系统 (online serving)，不仅要求单位时间内尽量服务尽可能多的请求（用户），也要求单个请求的**响应时间 (Response Time)**越短越好。所以，我们得到另外一个性能指标——**响应时间**。

通常来说，一个系统，它的吞吐量越高，请求的平均响应时间也越短。你可能会问：两者是不是倒数的关系？比如，1秒钟处理了10个请求，也就是吞吐量是10 requests/s，那么平均每个请求的响应时间是不是1/10 = 0.1s呢？

不完全是。如果系统完全是串行执行的，前一个请求处理完才能处理下一个请求，那么确实响应时间是0.1s。但是，现代系统都有一定的并行执行能力，这就让情况不同了。假设一个系统内部有10个并行的、独立的、同构的 (parallel, independent, homogeneous) 的**服务通道 (service channel)**，那么10个请求可以并行执行，每个请求都执行1s，也可以在1s内将10个请求都执行完。这样算起来的话，系统的吞吐量是10 requests/s，而平均响应时间是1s。这也是Cary Millsap在十几年前的一篇经典blog[1]中举的一个例子。

因此，从吞吐量不能推导出响应时间。**我们需要同时使用吞吐量和响应时间来表征一个系统**。我们大体上可以这样理解：
* 吞吐量关注系统整体性能，与系统的成本有关。
* 响应时间关注单个请求，跟用户的体验有关。

现在，我们来看LLM的推理系统，情况有没有变化。当然，有些东西没有变。我们仍然应该关注吞吐量和响应时间，它们对于系统性能的表征能力，跟什么类型的系统无关，跟技术的新旧也无关。

但是，毕竟现代的LLM推理系统也有一些不一样的地方。最大的一个不同在于，LLM生成的是一个长的sequence，一个token一个token的流式输出。这是由Decoder-Only的语言模型架构所具有的自回归式的 (auto-regressive) 生成方式所决定的。这也意味着，LLM推理系统对于请求的响应，存在一个显著的持续时间（若干秒、十几秒，甚至几十秒）。

在我们前面的分析中，那些互联网时代的「旧系统」，请求的响应时间通常是非常短的，以毫秒计。因此我们以request作为吞吐量和响应时间的计量基本单位。切换到LLM推理系统，一个请求本身包含很多token，同时会生成很多token。我们仍然可以以 requests/s 来表示吞吐量，但业界通常换算成token的粒度，也就是大家常说的 tokens/s。

那么，响应时间怎么表示呢？仍然是换算成token粒度，且业界常用的词汇是**延迟 (Latency)**。比如，在PagedAttention的论文中[2]，作者使用了 **Normalized Latency**这个度量，它定义为：每个请求的端到端的延迟（也就是系统从收到一个请求直到最后一个token生成完毕的持续时间）除以生成的token数，再对于所有请求计算平均值，度量单位是s/token。

前面我们说过，响应时间跟用户体验有关。因此，判断响应时间的度量单位是否合理，也应该从用户体验的角度来考虑。对于一个典型的LLM应用来说，通常第一个token的生成延迟（系统从收到一个请求直到第一个token生成完毕的持续时间）会比较高，远大于相邻token之间的生成延迟。而第一个token何时生成，是一个比较重要的用户体验。所以呢，我建议把**首token的生成延迟**也作为系统响应时间的另外一个度量。

总结一下，对于LLM的推理系统来说，我们需要使用三个性能指标来表征：
* **每秒生成的token数 (tokens/s)**，作为吞吐量的度量。
* **首token的生成延迟**，作为响应时间的一个度量。
* **Normalized Latency**，作为响应时间的另一个度量。


### 对系统的性能如何建模？



### vLLM做了哪些优化？



### 变与不变






（正文完）

##### 参考文献：

* [1] Cary Millsap. 2010. [Thinking Clearly About Performance](https://carymillsap.blogspot.com/2010/02/thinking-clearly-about-performance.html).
* [2] Woosuk Kwon, et al. 2023. [Efficient Memory Management for Large Language Model Serving with PagedAttention](https://arxiv.org/abs/2309.06180).



**其它精选文章**：

* [对于2024年初的大模型，我们期待什么？](https://mp.weixin.qq.com/s/T_IOrCouYIX4jqCteSd9Yw)
* [知识的三个层次](https://mp.weixin.qq.com/s/HnbBeQKG3SibP6q8eqVVJQ)
* [看得见的机器学习：零基础看懂神经网络](https://mp.weixin.qq.com/s/chHSDuwg20LyOcuAr26MXQ)
* [内卷、汉明问题与认知迭代](https://mp.weixin.qq.com/s/rgKkJ5wI5G5BZ6lIJZj7WA)
* [在技术和业务中保持平衡](https://mp.weixin.qq.com/s/OUdH5RxiRyvcrFrbLOprjQ)
* [分布式领域最重要的一篇论文，到底讲了什么？](https://mp.weixin.qq.com/s/FZnJLPeTh-bV0amLO5CnoQ)
* [漫谈分布式系统、拜占庭将军问题与区块链](https://mp.weixin.qq.com/s/tngWdvoev8SQiyKt1gy5vw)
* [三个字节的历险](https://mp.weixin.qq.com/s/6Gyzfo4vF5mh59Xzvgm4UA)