---
layout: post
category: "distributed_system"
title: "号称分布式领域最重要的一篇论文，到底讲了什么？"
date: 2021-04-11 00:00:00 +0800
published: true
---

正在阅读本文的读者们，可能之前已经读过了我写的有关[线性一致性、顺序一致性](https://mp.weixin.qq.com/s/3odLhBtebF4cm58hl-87JA)以及[因果一致性](https://mp.weixin.qq.com/s/wkXsRufVsbKqTwjzTgNqYQ)的分析文章。这些一致性模型的关键在于，它们定义了一个系统在分布式环境下对于读写操作的某种排序规则。

<!--more-->

没错，分布式系统内的事件排序，涉及到最深层的本质问题。图灵奖得主Lamport在1978年发表的经典论文，《Time, Clocks, and the Ordering of Events in a Distributed System》[1]，正是对这些本质问题的一个系统化的阐述。

今天，我们就来一起研究一下，这篇号称分布式领域最具影响力的论文，到底讲了什么。

### 为什么这篇论文如此重要？

先讲一个小故事。

两位研究人员Paul Johnson和Bob Thomas在1975年发表了一篇论文[2]，提出了一种基于消息时间戳的分布式算法。Lamport看到这篇论文后，很快就发现了算法存在的一些问题。他向论文作者指出了错误并帮助修正了算法。

在Lamport的自述中，他之所以能够指出算法的错误，是因为他对相对论有比较深入的理解[3]。他一眼就看透了Paul Johnson和Bob Thomas的算法的本质，用他自己的话来讲：

> I realized that the essence of Johnson and Thomas’s algorithm was the use of timestamps to provide a total ordering of events that was consistent with the causal order.  
> (译文：我意识到，Johnson和Thomas提出的算法的本质在于使用时间戳来提供事件的一种全局排序，而这种排序是和因果顺序保持一致的。)

在认识到这个「本质」之后，Lamport写成了《Time, Clocks, and the Ordering of Events in a Distributed System》[1]这篇论文，后来成为了分布式领域的经典论文，也是Lamport被引用次数最多的论文。

要理解这件事相关的描述，必须对事件偏序、因果性、相对论等概念有基本的了解。但这不是我们目前的重点（相关讨论会在下一章节开始）。现在你只要记住，这篇论文之所以经典，是因为它揭示了分布式系统的某些深层本质，深深地影响了人们对于分布式系统的思考方式。

当然，这篇论文除了理论意义和历史价值之外，它与业界一些重要的分布式系统实践也都有紧密的联系。比如，在大规模的分布式环境下产生单调递增的时间戳，是个很难的问题，而谷歌的全球级分布式数据库Spanner就解决了这个问题，甚至能够在跨越遍布全球的多个数据中心之间高效地产生单调递增的时间戳。做到这一点，靠的是一种称为TrueTime的机制，而这种机制的理论基础就是Lamport这篇论文中的物理时钟算法（两者之间有千丝万缕的联系）。再比如，这篇论文中定义的「happened before」关系，不仅在分布式系统设计中成为考虑不同事件之间关系的基础，而且在多线程编程模型中也是重要的概念。另外，还有让很多人忽视的一点是，利用分布式状态机来实现数据复制的通用方法（State Machine Replication，简称SMR），其实也是这篇论文首创的。

总之，如果在整个分布式的技术领域中，你只有精力阅读一篇论文，那一定要选这一篇了。只有理解了这篇论文中揭示的这些涉及时间、时钟和排序的概念，我们才能真正在面对分布式系统的设计问题时游刃有余。

### 时间、时钟和排序


### 逻辑时钟和偏序


### 为什么又需要全局排序？

可以解决任意分布式问题。是通用的方法。

### 基于逻辑时钟进行全局排序，又什么问题？


### 时间本身预示了一种偏序

因果性

### 物理时钟同步算法


### 我们这个世界


### 小结


（正文完）

##### 参考文献：

* [1] Leslie Lamport, "Time, Clocks, and the Ordering of Events in a Distributed System", 1978.
* [2] Paul R. Johnson, Robert H. Thomas, "[Robert H. Thomas](https://www.rfc-archive.org/getrfc.php?rfc=677){:target="_blank"}", 2015.
* [3] Leslie Lamport, <https://www.microsoft.com/en-us/research/publication/time-clocks-ordering-events-distributed-system/>{:target="_blank"}.



* [1] Martin Kleppmann,《Designing Data-Intensive Applications》, 2017.
* [2] Martin Kleppmann, "Please Stop Calling Databases CP or AP", 2015.
* [3] Peter Bailis, Ali Ghodsi, "Eventual Consistency Today: Limitations, Extensions, and Beyond", 2013.
* [4] Werner Vogels, "Eventually Consistent", 2008.
* [5] Prince Mahajan, Lorenzo Alvisi, Mike Dahlin, "Consistency, Availability, and Convergence", 2011.
* [6] Peter Bailis, Ali Ghodsi, et al, "Bolt-on Causal Consistency", 2013.
* [7] Mustaque Ahamad, Gil Neiger, James E. Burns, et al, "Causal Memory: Definitions, Implementation and Programming", 1994.

**其它精选文章**：

* [漫谈分布式系统、拜占庭将军问题与区块链](https://mp.weixin.qq.com/s/tngWdvoev8SQiyKt1gy5vw)
* [基于Redis的分布式锁到底安全吗](https://mp.weixin.qq.com/s/4CUe7OpM6y1kQRK8TOC_qQ)
* [知识的三个层次](https://mp.weixin.qq.com/s/HnbBeQKG3SibP6q8eqVVJQ)
* [看得见的机器学习：零基础看懂神经网络](https://mp.weixin.qq.com/s/chHSDuwg20LyOcuAr26MXQ)
* [给普通人看的机器学习(一)：优化理论](https://mp.weixin.qq.com/s/-lJyRREez1ITxomizuhPAw)
* [漫谈业务与平台](https://mp.weixin.qq.com/s/gPE2XTqTHaN8Bg7NnfOoBw)
* [在技术和业务中保持平衡](https://mp.weixin.qq.com/s/OUdH5RxiRyvcrFrbLOprjQ)
* [三个字节的历险](https://mp.weixin.qq.com/s/6Gyzfo4vF5mh59Xzvgm4UA)