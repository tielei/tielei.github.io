---
layout: post
category: "distributed_system"
title: "条分缕析分布式：因果一致性"
date: 2020-12-22 00:00:00 +0800
published: true
---

在上一篇文章《[条分缕析分布式：浅析强弱一致性](https://mp.weixin.qq.com/s/3odLhBtebF4cm58hl-87JA)》中，我们重点讨论了顺序一致性、线性一致性和最终一致性这几个概念。本文我们将继续深入，详细探讨另一种一致性模型——因果一致性，并在这个过程中逐步逼近分布式系统最深层的事件排序的本质。沿着这个方向，如果我们走得稍微再远一点，就会触达我们所生活的这个宇宙的时空本质，以及因果律的本质（这才是真正有意思的地方）。

回到现实，《Designing Data-Intensive Applications》[1]一书的作者在他的书中提到，基于因果一致性构建分布式数据库系统，是未来一个非常有前景的研究方向。而且，估计很少有人注意到，我们经常使用的ZooKeeper，其实就在session维度上提供了因果一致性的保证[2]。理解「因果一致性」的概念，有助于我们对于分布式系统的认识更进一层。

<!--more-->

### 为什么要考虑因果一致性？

结合[上一篇文章](https://mp.weixin.qq.com/s/3odLhBtebF4cm58hl-87JA)的讨论，我们再把一致性模型的来历简单梳理一下。

早期的分布式系统设计者，为了让使用系统的开发者能以比较简单的方式来使用系统，希望分布式系统能提供单一系统视图 (SSI，*single-system image*)[3]，即系统“表现得就好像只有一个单一的副本”。线性一致性和顺序一致性就是沿着这个思路设计的。满足线性一致性或顺序一致性的系统，对读写操作的排序呈现全局唯一的一种次序。

然而，系统为了维持这种全局排序的一致性是有成本的，必然需要在副本节点之间做很多通信和协调工作。这降低了系统的可用性（*availability*）和性能。于是，在一致性、可用性、系统性能之间进行权衡的结果，就是降低系统提供的一致性保障，转向了最终一致性[4]。

不过最终一致性提供的一致性保障是如此之弱，它放弃了所有的*safety*属性（具体讨论见[上一篇文章](https://mp.weixin.qq.com/s/3odLhBtebF4cm58hl-87JA)）。这给系统的使用带来了额外的困难。面向最终一致性系统进行编程，需要随时关注数据不一致的情况。加州大学伯克利分校在2013年有一篇非常不错的论文[3]，对于如何在最终一致性系统上构建应用，进行了非常深入的研究。文章指出了两种思路：
* 针对可能出现的数据不一致情况实施补偿措施 (*compensation*)。这需要在分布式系统之上的应用层面进行额外的处理，是非常容易出错且费时费力的。
* 基于CALM定理和CRDTs，完全消除补偿操作。但这样做其实限制了应用编程能够使用的操作类型，也就限制了系统能力。这种做法涉及到大量细节，我们不打算在这里深入讨论，有兴趣的读者可以仔细去阅读论文[3]。

总之，为了提高系统可用性和系统性能，人们放弃了强一致性，采取了几乎最弱的一类一致性模型（最终一致性），但也引来了新的问题，牺牲了系统能力或系统使用的便利性。那么，到底有没有必要一定采取这么「弱」的一致性模型呢？有没有可能在最终一致性的基础上增加一点*safety*属性，提供稍强一点的一致性，但同时也不至于对系统可用性和性能产生明显的损害呢？

基于最新的研究，这是有可能的。这个问题的答案就是本文接下来要讨论的因果一致性。

### 因果一致性的通俗解释


### 因果一致性的精确定义


### 因果一致性的匪夷所思之处


### 更进一步


（正文完）

*后记*



##### 参考文献：

* [1] Martin Kleppmann,《Designing Data-Intensive Applications》, 2017.
* [2] Martin Kleppmann, "Please Stop Calling Databases CP or AP", 2015.
* [3] Peter Bailis, Ali Ghodsi, "Eventual Consistency Today: Limitations, Extensions, and Beyond", 2013.
* [4] Werner Vogels, "Eventually Consistent", 2008.



**其它精选文章**：

* [条分缕析分布式：到底什么是一致性？](https://mp.weixin.qq.com/s/qnvl_msvw0XL7hFezo2F4w)
* [漫谈分布式系统、拜占庭将军问题与区块链](https://mp.weixin.qq.com/s/tngWdvoev8SQiyKt1gy5vw)
* [基于Redis的分布式锁到底安全吗](https://mp.weixin.qq.com/s/4CUe7OpM6y1kQRK8TOC_qQ)
* [看得见的机器学习：零基础看懂神经网络](https://mp.weixin.qq.com/s/chHSDuwg20LyOcuAr26MXQ)
* [给普通人看的机器学习(一)：优化理论](https://mp.weixin.qq.com/s/-lJyRREez1ITxomizuhPAw)
* [漫谈业务与平台](https://mp.weixin.qq.com/s/gPE2XTqTHaN8Bg7NnfOoBw)
* [在技术和业务中保持平衡](https://mp.weixin.qq.com/s/OUdH5RxiRyvcrFrbLOprjQ)
* [三个字节的历险](https://mp.weixin.qq.com/s/6Gyzfo4vF5mh59Xzvgm4UA)