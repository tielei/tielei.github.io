---
layout: post
category: "server"
title: "Redis内部数据结构详解(5)——quicklist"
date: 2016-07-21 01:00:00 +0800
published: true
---

本文是《[Redis内部数据结构详解](/posts/blog-redis-dict.html)》系列的第四篇。在本文中，我们介绍Redis内部数据结构——quicklist。Redis对外暴露的list数据类型，它底层实现所依赖的内部数据结构就是quicklist。 

我们在讨论中还会涉及到两个Redis配置（在redis.conf中的ADVANCED CONFIG部分）：

```
list-max-ziplist-size -2
list-compress-depth 0
```

我们在讨论中会详细解释这两个配置的含义。

注：本文讨论的quicklist实现基于Redis源码的3.2分支。

<!--more-->

#### quicklist概述

Redis对外暴露的上层list数据类型，经常被用作队列使用。比如它支持的如下一些操作：

* `lpush`: 在左侧（即列表头部）插入数据。
* `rpop`: 在右侧（即列表尾部）删除数据。
* `rpush`: 在右侧（即列表尾部）插入数据。
* `lpop`: 在左侧（即列表头部）删除数据。

这些操作都是O(1)时间复杂度的。

当然，list也支持在任意中间位置的存取操作，比如`lindex`和`linsert`，但它们都需要对list进行遍历，所以时间复杂度较高。

概况起来，list具有这样的一些特点：它是一个有序列表，便于在表的两端追加和删除数据，而对于中间位置的存取具有O(N)的时间复杂度。这不正是一个双向链表所具有的特点吗？

list的内部实现quicklist正是一个双向链表。在quicklist.c的文件头部注释中，是这样描述quicklist的：

> A doubly linked list of ziplists

它确实是一个双向链表，而且是一个ziplist的双向链表。

什么意思呢？


长列表需求


[Writing a simple Twitter clone with PHP and Redis](http://redis.io/topics/twitter-clone){:target="_blank"}





