---
layout: post
category: "other"
title: "给普通人看的机器学习原理(一)"
date: 2019-12-03 00:00:00 +0800
published: true
---

相信大家已经注意到了，本文的题目强调了：这是写给「普通人」看的机器学习原理。

为什么一定要写给普通人看呢？我想了想，大致有三个原因：

<!--more-->

1. 机器学习算法非常有意思，它代表了一种全新的思维方式，所以，你应该了解它。站在机器学习的视角，这个世界的一切都是概率。而传统的基于if/else的规则，则相形见绌。
2. 普通大众对于机器学习算法的认识，长期以来形成了两种截然相反的观点。其中一种观点认为，机器学习意味着艰深的数学，那是「科学家」们搞的东西，普通人根本无法理解；另一种观点则认为，机器学习的门槛已经变得如此之低了，一个普通工程师通过拖拖拽拽就能建起一个模型，把数据灌进去然后就能跑起来，整个过程根本不需要数学。甚至业界的算法专家们也戏谑地称自己为「调参工程师」。这些观点到底对不对，我们先不做过多的探讨。然而关键的一点是，一件事，我们如果不了解它，就永远无法形成正确的认识，更无法向大众澄清它的真相。
3. 把专业的知识讲给普通人，这本身就是很有挑战性的事情。要做到既深入（不是浮于表面），又能通俗易懂，这中间需要填补大量的认知gap。所以说，这件事本身就很酷！

我曾经在《[分层的概念——认知的基石](https://mp.weixin.qq.com/s/yLdRuhIWfLOnLPJSDocEhQ){:target="_blank"}》一文中跟大家讨论过，知识是分层次的。因此，在开始之前，我们必须首先决定当前这篇文章的描述是建立在一个什么样的层次基础之上的。同一件事，对一名工程师和一名非技术人员，讲述的方式肯定截然不同。综合考虑，我还是认为，读者应该主要是从事编程工作的工程师，否则，文章的描述就不可能深入下去。在这里，我们假设，作为读者的你，对于如何把一个实际问题转变成可以运行的程序应该有足够的经验，而且曾经在大学课程里面至少学过高等数学和概率论。

还有一个问题：机器学习的概念如此广泛，我们从哪里开始呢？

如果我们从基础概念开始讲起，那么文章会变得冗长无趣，而且跟任何一本机器学习的教科书没有太大区别。任何可能涉及抽象概念的讨论，总得有个切入点。因此，我打算采取一个比较新的方式。接下来，我会选取一个具体的机器学习模型，以解释清楚它的工作原理为目标，来组织文章的的章节。这个模型不能太简单，只有这样，我们才有机会在讨论它的过程中，涉及到机器学习的各个方面。总之，我选择的模型是一个非常有代表性的机器学习模型——GBDT。选择它还有一个原因，那就是GBDT在推荐系统的设计中有着非常广泛的应用。

虽然我们从具体的模型开始，但是，等我们真正地深入讨论之后就会发现，具体的模型其实并不重要，重要的是蕴含在整个过程里的设计思想。它们才是我们更需要关注的东西。

此外，还有一个令人举棋不定的决策要做，那就是文章中要不要出现公式？显然，每出现一个公式，都会吓跑一部分读者，最终本文也就没法完成“给普通人讲述机器学习”的目标了。但是，机器学习毕竟是与数学关联比较紧密的学科。如果本文一个公式也不出现，那么它就跟一般的科普文章没有什么区别了。我还是希望能跟读者进行稍微深入一些的探讨的。况且，在很多时候，一个公式真的胜过千言万语。

经过仔细权衡，我力求在文中少出现公式。即使出现公式的地方，我也尽量做到：就算你跳过公式，也能继续阅读。

### GBDT概述

GBDT这个模型有很多不同的名字：
* GBDT: Gradient Boosted Decision Tree；
* GBRT: Gradient Boosted Regression Tree；
* GBM: Gradient Boosting Machine；
* MART: Multiple Additive Regression Tree；

除了这些名字之外，有时候它也被简单地称为Gradient Tree Boosting。这个模型真正的出处，是来源于Jerome H. Friedman的一篇论文：
* 《Greedy Function Approximation: A Gradient Boosting Machine》

从论文的题目可以看出，作者对于这个模型的称呼是GBM。

GBDT相对来说是一个比较复杂的模型，它的理论构成如下图所示：



### Gradient Descent


（正文完）

##### 参考文献：

* [1] <https://en.wikipedia.org/wiki/Benjamin_Rush>{:target="_blank"}
* [2] <https://en.wikipedia.org/wiki/Limey>{:target="_blank"}

**其它精选文章**：

* [用统计学的观点看世界：从找不到东西说起](https://mp.weixin.qq.com/s/W6hSnQPiZD1tKAou3YgDQQ)
* [漫谈业务与平台](https://mp.weixin.qq.com/s/gPE2XTqTHaN8Bg7NnfOoBw)
* [漫谈分布式系统、拜占庭将军问题与区块链](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261626&idx=1&sn=6b32cc7a7a62bee303a8d1c4952d9031&chksm=844791e3b33018f595efabf6edbaa257dc6c5f7fe705e417b6fb7ac81cd94e48d384a694640f#rd)
* [光年之外的世界](https://mp.weixin.qq.com/s/zUgMSqI8QhhrQ_sy_zhzKg)
* [技术的正宗与野路子](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261357&idx=1&sn=ebb11a1623e00ca8e6ad55c9ad6b2547#rd)
* [三个字节的历险](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261541&idx=1&sn=2f1ea200389d82e7340a5b4103968d7f&chksm=84479e3cb330172a6b2285d4199822143ad05ef8e8c878b98d4ee4f857664c3d15f54e0aab50#rd)
* [做技术的五比一原则](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261555&idx=1&sn=3662a2635ecf6f67185abfd697b1057c&chksm=84479e2ab330173cebe16826942b034daec79ded13ee4c03003d7bef262d4969ef0ffb1a0cfb#rd)
* [知识的三个层次](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261491&idx=1&sn=cff9bcc4d4cc8c5e642309f7ac1dd5b3&chksm=84479e6ab330177c51bbf8178edc0a6f0a1d56bbeb997ab1cf07d5489336aa59748dea1b3bbc#rd)