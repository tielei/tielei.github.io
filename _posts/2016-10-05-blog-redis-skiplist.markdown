---
layout: post
category: "server"
title: "Redis内部数据结构详解(6)——skiplist"
date: 2016-10-05 23:40:00 +0800
published: true
---

本文是《[Redis内部数据结构详解](/posts/blog-redis-dict.html)》系列的第六篇。在本文中，我们围绕一个Redis的内部数据结构——skiplist展开讨论。


Redis里面使用skiplist是为了实现sorted set这种对外的数据结构。sorted set提供的操作非常丰富，可以满足非常多的应用场景。这也意味着，sorted set相对来说实现比较复杂。同时，skiplist这种数据结构对于很多人来说都比较陌生，因为大部分学校里的算法课都没有对这种数据结构进行过详细的介绍。因此，为了介绍得足够清楚，本文会比《[Redis内部数据结构详解](/posts/blog-redis-dict.html)》系列的其它几篇花费更多的篇幅。

本文将大体分成三个部分进行介绍：

1. 介绍经典的skiplist数据结构，并进行简单的算法分析。我会尝试尽量使用通俗易懂的语言进行描述。
2. 讨论Redis里的skiplist的具体实现。为了支持sorted set本身的一些要求，在经典的skiplist基础上，Redis里的相应实现做了若干改动。
3. 讨论sorted set是如何在skiplist, dict和ziplist基础上构建起来的。

<!--more-->

我们在讨论中还会涉及到两个Redis配置（在redis.conf中的ADVANCED CONFIG部分）：

```
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
```

我们在讨论中会详细解释这两个配置的含义。

注：本文讨论的代码实现基于Redis源码的3.2分支。

### skiplist数据结构简介

skiplist本质上也是一种查找结构，用于解决算法中的查找问题（Searching），即根据给定的key，快速查到它所在的位置（或者对应的value）。

我们在《Redis内部数据结构详解》系列的[第一篇](/posts/blog-redis-dict.html)中介绍dict的时候，曾经讨论过：一般查找问题的解法分为两个大类：一个是基于各种平衡树，一个是基于哈希表。但skiplist却比较特殊，它没法归属到这两大类里面。

skiplist，顾名思义，首先它是一个list。实际上，它是在有序链表的基础上发展起来的。

我们先来看一个有序链表，如下图：



（完）


**其它精选文章**：

* [Redis内部数据结构详解(5)——quicklist](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261335&idx=1&sn=053d72a348be2e78040f3847f4092d92&scene=19#wechat_redirect)
* [论人生之转折](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261385&idx=1&sn=56b335b4f33546c5baa41a1c7f1b6551#rd)
* [技术的正宗与野路子](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261357&idx=1&sn=ebb11a1623e00ca8e6ad55c9ad6b2547#rd)
* [程序员的那些反模式](/posts/blog-programmer-anti-pattern.html)
* [编程世界的熵增原理](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261372&idx=1&sn=89c5b0fa1e9e339ee220d0c30001d01a#rd)
* [程序员的宇宙时间线](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261318&idx=1&sn=f7588db0d44a1c1842674d6465ca709e#rd)
* [Android端外推送到底有多烦？](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261350&idx=1&sn=6cea730ef5a144ac243f07019fb43076#rd)
* [Android和iOS开发中的异步处理（四）——异步任务和队列](/posts/blog-series-async-task-4.html)
* [用树型模型管理App数字和红点提示](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261255&idx=1&sn=01ab92edada77803fc4ab7a575453d97&scene=19#wechat_redirect)
* [一张图读懂RxJava中的线程控制](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=509777575&idx=1&sn=9ace4885f32a1f274e4be8d839700486&scene=19#wechat_redirect)
* [宇宙尽头的描述符（下）](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261342&idx=1&sn=0adc539ce9b4632aac96a447b7431532#rd)
