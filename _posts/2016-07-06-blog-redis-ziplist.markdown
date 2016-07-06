---
layout: post
category: "server"
title: "Redis内部数据结构详解(4)——ziplist"
date: 2016-07-06 01:00:00 +0800
published: true
---

本文是《[Redis内部数据结构详解](/posts/blog-redis-dict.html)》系列的第四篇。在本文中，我们首先介绍一个新的Redis内部数据结构——ziplist，然后在文章后半部分我们会讨论一下在robj, dict和ziplist的基础上，Redis对外暴露的hash结构是怎样构建起来的。 

我们在讨论中还会涉及到两个Redis配置（在redis.conf中的ADVANCED CONFIG部分）：

{% highlight %}
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
{% endhighlight %}

本文的后半部分会对这两个配置做详细的解释。

<!--more-->

#### 什么是ziplist

Redis官方对于ziplist的定义是（出自ziplist.c的文件头部注释）：

> The ziplist is a specially encoded dually linked list that is designed to be very memory efficient. It stores both strings and integer values,  where integers are encoded as actual integers instead of a series of  characters. It allows push and pop operations on either side of the list  in O(1) time.

翻译一下就是说：ziplist是一个经过特殊编码的双向链表，它的设计目标就是为了提高存储效率。ziplist可以用于存储字符串或整数，其中整数是按真正的二进制表示进行编码的，而不是编码成字符串序列。它能以O(1)的时间复杂度在表的两端提供push和pop操作。

实际上，ziplist充分体现了Redis对于存储效率的追求。一个普通的双向链表，链表中每一项都占用独立的一块内存，各项之间用地址指针（或引用）连接起来。这种方式会带来大量的内存碎片。而ziplist却是将表中每一项存放在前后连续的地址空间内，一个ziplist整体占用一大块内存。它是一个表（list），但其实不是一个链表（linked list）。

另外，ziplist为了在细节上节省内存，对于值的存储采用了变长的编码方式，大概意思是说，对于大的整数，就多用一些字节来存储，而对于小的整数，就少用一些字节来存储。我们接下来很快就会讨论到这些实现细节。

#### ziplist的数据结构定义

ziplist的数据结构组成是本文要讨论的重点。实际上，ziplist还是稍微有点复杂的，它复杂的地方就在于它的数据结构定义。一旦理解了数据结构，它的一些操作也就比较容易理解了。

我们接下来先从总体上介绍一下ziplist的数据结构定义，然后举一个实际的例子，通过例子来解释ziplist的构成。如果你看懂了这一部分，本文的任务就算完成了一大半了。

从宏观上看，ziplist的内存结构如下：

**&lt;zlbytes>&lt;zltail>&lt;zllen>&lt;entry>...&lt;entry>&lt;zlend>**

各个部分在内存上是前后相邻的，它们分的含义如下：

* &lt;zlbytes>: 32bit，表示ziplist占用的字节总数（也包括&lt;zlbytes>本身占用的4个字节）。
* &lt;zltail>: 32bit，表示ziplist表中最后一项（entry）在ziplist中的偏移字节数。&lt;zltail>的存在，使得我们可以很方便地找到最后一项（不用遍历整个ziplist），从而可以在ziplist尾端快速地执行push或pop操作。
* &lt;zllen>: 16bit， 表示ziplist中数据项（entry）的个数。zllen字段因为只有16bit，所以可以表达的最大值为2^16-1。这里需要特别注意的是，如果ziplist中数据项个数超过了16bit能表达的最大值，ziplist仍然可以来表示。那怎么表示呢？这里做了这样的规定：如果zllen小于等于2^16-2（也就是不等于2^16-1），那么zllen就表示ziplist中数据项的个数；否则，也就是zllen等于16bit全为1的情况，那zllen就不表示数据项个数了，这时候要想知道ziplist中数据项总数，那么必须对ziplist从头到尾遍历各个数据项，才能计数出来。
* &lt;entry>: 表示真正存放数据的数据项，长度不定。一个数据项（entry）也有它自己的内部结构，这个稍后再解释。
* &lt;zlend>: ziplist最后1个字节，是一个结束标记，值固定等于255。

小端

我们再


