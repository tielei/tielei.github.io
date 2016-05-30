---
layout: post
category: "server"
title: "Redis内部数据结构详解(1)——dict"
date: 2016-05-29 05:30:00 +0800
published: true
---

如果你使用过Redis，一定会像我一样对它的内部实现产生兴趣。《Redis内部数据结构详解》是我准备写的一个系列，也是我个人对于之前研究Redis的一个阶段性总结，着重讲解Redis在内存中的数据结构实现（暂不涉及持久化的话题）。Redis本质上是一个数据结构服务器（data structures server），以高效的方式实现了多种现成的数据结构，研究它的数据结构和基于其上的算法，对于我们自己提升局部算法的编程水平有很重要的参考意义。

当我们在本文中提到Redis的“数据结构”，可能是在两个不同的层面来讨论它。

<!--more-->

第一个层面，是从使用者的角度。比如：

* string
* list
* hash
* set
* sorted set

这一层面也是Redis暴露给外部的调用接口。

第二个层面，是从内部实现的角度，属于更底层的实现。比如：

* dict
* sds
* ziplist
* quicklist
* skiplist

第一个层面的“数据结构”，Redis的官方文档(<http://redis.io/topics/data-types-intro>{:target="_blank"})有详细的介绍。本文的重点在于讨论第二个层面，Redis数据结构的内部实现，以及这两个层面的数据结构之间的关系：Redis如何通过组合第二个层面的各种基础数据结构来实现第一个层面的更高层的数据结构。

在讨论任何一个系统的内部实现的时候，我们都要先明确它的设计原则，这样我们才能更深刻地理解它为什么会进行如此设计的真正意图。在本文接下来的讨论中，我们主要关注以下几点：

* 存储效率（memory efficiency）。Redis是专用于存储数据的，它对于计算机资源的主要消耗就在于内存，因此节省内存是它非常非常重要的一个方面。这意味着Redis一定是非常精细地考虑了压缩数据、减少内存碎片等问题。
* 快速响应时间（fast response time）。与快速响应时间相对的，是高吞吐量（high throughput）。Redis是用于提供在线访问的，对于单个请求的响应时间要求很高，因此快速响应时间是比高吞吐量更重要的目标。有时候，这两个目标是矛盾的。
* 单线程（single-threaded）。Redis的性能瓶颈不在于CPU资源，而在于内存访问和网络IO。而采用单线程的设计带来的好处是，极大简化了数据结构和算法的实现。相反，Redis通过异步IO和pipelining等机制来实现高速的并发访问。显然，单线程的设计，对于单个请求的快速响应时间也提出了更高的要求。

本文是《Redis内部数据结构详解》系列的第一篇，讲述Redis一个重要的基础数据结构：dict。

dict是一个用于维护key和value映射关系的数据结构，与很多语言中的Map或dictionary类似。Redis的一个database中所有key到value的映射，就是使用一个dict来维护的。不过，这只是它在Redis中的一个用途而已，它在Redis中被使用的地方还有很多。比如，一个Redis hash结构，当它的field较多时，便会采用dict来存储。再比如，Redis配合使用dict和skiplist来共同维护一个sorted set。这些细节我们后面再讨论，在本文中，我们集中精力讨论dict本身的实现。

dict本质上是为了解决算法中的查找问题（Searching），一般查找问题的解法分为两个大类：一个是基于各种平衡树，一个是基于哈希表。我们平常使用的各种Map或dictionary，大都是基于哈希表实现的。在不要求数据有序存储，且能保持较低冲突概率的前提下，基于哈希表的查找性能能做到非常高效，接近O(1)，而且实现简单。

在Redis中，dict也是一个基于哈希表的算法。和传统的哈希算法类似，它采用某个哈希函数从key计算得到在哈希表中的位置，采用拉链法解决冲突，并在装载因子（load factor）超过预定值时自动扩展内存，引发重哈希（rehashing）。Redis的dict实现最显著的一个特点，就在于它的重哈希。它采用了一种称为增量式重哈希（incremental rehashing）的方法，在需要扩展内存时避免一次性对所有key进行重哈希，而是将重哈希操作分散到对于dict的各个增删改查的操作中去。这种方法能做到每次只对一小部分key进行重哈希，而每次重哈希之间不影响dict的操作。dict之所以这样设计，是为了避免重哈希期间单个请求的响应时间剧烈增加，这与前面提到的“快速响应时间”的设计原则是相符的。

下面进行详细介绍。

#### dict的数据结构定义

为了实现增量式重哈希（incremental rehashing），dict的数据结构里包含两个哈希表。在重哈希期间，数据从第一个哈希表向第二个哈希表迁移。

dict的C代码定义如下（出自Redis源码dict.h）：

{% highlight c linenos %}
typedef struct dictEntry {
    void *key;
    union {
        void *val;
        uint64_t u64;
        int64_t s64;
        double d;
    } v;
    struct dictEntry *next;
} dictEntry;

typedef struct dictType {
    unsigned int (*hashFunction)(const void *key);
    void *(*keyDup)(void *privdata, const void *key);
    void *(*valDup)(void *privdata, const void *obj);
    int (*keyCompare)(void *privdata, const void *key1, const void *key2);
    void (*keyDestructor)(void *privdata, void *key);
    void (*valDestructor)(void *privdata, void *obj);
} dictType;

/* This is our hash table structure. Every dictionary has two of this as we
 * implement incremental rehashing, for the old to the new table. */
typedef struct dictht {
    dictEntry **table;
    unsigned long size;
    unsigned long sizemask;
    unsigned long used;
} dictht;

typedef struct dict {
    dictType *type;
    void *privdata;
    dictht ht[2];
    long rehashidx; /* rehashing not in progress if rehashidx == -1 */
    int iterators; /* number of iterators currently running */
} dict;
{% endhighlight %}

为了能更清楚地展示dict的数据结构定义，我们用一张结构图来表示它。如下。

