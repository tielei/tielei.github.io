---
layout: post
category: "server"
title: "Redis内部数据结构详解(2)——sds"
date: 2016-06-05 07:30:00 +0800
published: true
---

本文是《[Redis内部数据结构详解](/posts/blog-redis-dict.html)》系列的第二篇，讲述Redis中使用最多的一个基础数据结构：sds。

不管在哪门编程语言当中，字符串都几乎是使用最多的数据结构。sds正是在Redis中被广泛使用的字符串结构，它的全称是Simple Dynamic String。与其它语言环境中出现的字符串相比，它具有如下显著的特点：

* 可动态扩展内存。sds表示的字符串其内容可以修改，也可以追加。在很多语言中字符串会分为mutable和immutable两种，显然sds属于mutable类型的。
* 二进制安全（Binary Safe）。sds能存储任意二进制数据，而不仅仅是可打印字符。
* 与传统的C语言字符串类型兼容。这个的含义接下来马上会讨论。

<!--more-->

看到这里，很多对Redis有所了解的同学可能已经产生了一个疑问：Redis已经对外暴露了一个字符串结构，叫做string，那这里所说的sds到底和string是什么关系呢？可能有人会猜：string是基于sds实现的。这个猜想已经非常接近事实，但在描述上还不太准确。有关string和sds之间关系的详细分析，我们放在下一篇讲robj的时候再讲。现在为了方便讨论，让我们先暂时简单地认为，string的底层实现就是sds。

在讨论sds的具体实现之前，我们先站在Redis使用者的角度，来观察一下string所支持的一些主要操作。下面是一个操作示例：

[<img src="/assets/photos_redis/redis_string_op_examples.png" style="width:400px" alt="Redis string操作示例" />](/assets/photos_redis/redis_string_op_examples.png)

以上这些操作都比较简单，我们简单解释一下：

* 初始的字符串的值设为"tielei"。
* 第3步通过append命令对字符串进行了追加，变成了"tielei zhang"。
* 然后通过setbit命令将第53个bit设置成了1。bit的偏移量从左边开始算，从0开始。其中第48～55bit是中间空格那个字符，它的ASCII码是0x20。将第53个bit设置成1之后，它的ASCII码变成了0x24，打印出来就是'$'。因此，现在字符串的值变成了"tielei$zhang"。
* 最后通过getrange取从倒数第5个字节到倒数第1个字节的内容，得到"zhang"。

这些命令的实现，有一部分是和sds的实现有关的。下面我们开始详细讨论。

#### sds的数据结构定义

我们知道，在C语言中，字符串是以'\0'字符结尾（NULL结束符）的字符数组来存储的，通常表达为字符指针的形式（char *）。它不允许字节0出现在字符串中间，因此，它不能用来存储任意的二进制数据。

我们可以在sds.h中找到sds的类型定义：

{% highlight c %}
typedef char *sds;
{% endhighlight %}

肯定有人感到困惑了，竟然sds就等同于char *？我们前面提到过，sds和传统的C语言字符串保持类型兼容，因此它们的类型定义是一样的，都是char *。在有些情况下，需要传入一个C语言字符串的地方，也确实可以传入一个sds。但是，sds和char *并不等同。sds是Binary Safe的，它可以存储任意二进制数据，不能像C语言字符串那样以字符'\0'来标识字符串的结束，因此它必然有个长度字段。但这个长度字段在哪里呢？实际上sds还包含一个header：

{% highlight c linenos %}
struct __attribute__ ((__packed__)) sdshdr5 {
    unsigned char flags; /* 3 lsb of type, and 5 msb of string length */
    char buf[];
};
struct __attribute__ ((__packed__)) sdshdr8 {
    uint8_t len; /* used */
    uint8_t alloc; /* excluding the header and null terminator */
    unsigned char flags; /* 3 lsb of type, 5 unused bits */
    char buf[];
};
struct __attribute__ ((__packed__)) sdshdr16 {
    uint16_t len; /* used */
    uint16_t alloc; /* excluding the header and null terminator */
    unsigned char flags; /* 3 lsb of type, 5 unused bits */
    char buf[];
};
struct __attribute__ ((__packed__)) sdshdr32 {
    uint32_t len; /* used */
    uint32_t alloc; /* excluding the header and null terminator */
    unsigned char flags; /* 3 lsb of type, 5 unused bits */
    char buf[];
};
struct __attribute__ ((__packed__)) sdshdr64 {
    uint64_t len; /* used */
    uint64_t alloc; /* excluding the header and null terminator */
    unsigned char flags; /* 3 lsb of type, 5 unused bits */
    char buf[];
};
{% endhighlight %}

sds一共有5种类型的header。之所以有5种，是为了能让不同长度的字符串可以使用不同大小的header。这样，短字符串就能使用较小的header，从而节省内存。

一个sds字符串的完整结构，由在内存地址上前后相邻的两部分组成：

* 一个header。通常包含字符串的长度(len)、最大容量(alloc)和flags。sdshdr5有所不同。
* 一个字符数组。这个字符数组的长度等于最大容量+1。真正有效的字符串数据，其长度通常小于最大容量。在真正的字符串数据之后，是空余未用的字节（一般以字节0填充），允许在不重新分配内存的前提下让字符串数据向后做有限的扩展。在真正的字符串数据之后，还有一个NULL结束符，即ASCII码为0的'\0'字符。这是为了和传统C字符串兼容。之所以字符数组的长度比最大容量多1个字节，就是为了在字符串长度达到最大容量时仍然有1个字节存放NULL结束符。

sds的数据结构，我们有必要非常仔细地去解析它。

除了sdshdr5之外，其它4个header的结构都包含3个字段：

* len: 表示字符串的真正长度。
* alloc: 表示字符串

字符串通常在程序运行中使用频率非常高，





下篇提要：
string和sds的关系
-两个层面的
-string基于sds+robj实现
-sds用在很多很多别的地方

