---
layout: post
category: "server"
title: "Redis内部数据结构详解(4)——ziplist"
date: 2016-07-06 01:00:00 +0800
published: true
---

本文是《[Redis内部数据结构详解](/posts/blog-redis-dict.html)》系列的第四篇。在本文中，我们首先介绍一个新的Redis内部数据结构——ziplist，然后在文章后半部分我们会讨论一下在robj, dict和ziplist的基础上，Redis对外暴露的hash结构是怎样构建起来的。 

我们在讨论中还会涉及到两个Redis配置（在redis.conf中的ADVANCED CONFIG部分）：

{% highlight java %}
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

各个部分在内存上是前后相邻的，它们分别的含义如下：

* &lt;zlbytes>: 32bit，表示ziplist占用的字节总数（也包括&lt;zlbytes>本身占用的4个字节）。
* &lt;zltail>: 32bit，表示ziplist表中最后一项（entry）在ziplist中的偏移字节数。&lt;zltail>的存在，使得我们可以很方便地找到最后一项（不用遍历整个ziplist），从而可以在ziplist尾端快速地执行push或pop操作。
* &lt;zllen>: 16bit， 表示ziplist中数据项（entry）的个数。zllen字段因为只有16bit，所以可以表达的最大值为2^16-1。这里需要特别注意的是，如果ziplist中数据项个数超过了16bit能表达的最大值，ziplist仍然可以来表示。那怎么表示呢？这里做了这样的规定：如果zllen小于等于2^16-2（也就是不等于2^16-1），那么zllen就表示ziplist中数据项的个数；否则，也就是zllen等于16bit全为1的情况，那zllen就不表示数据项个数了，这时候要想知道ziplist中数据项总数，那么必须对ziplist从头到尾遍历各个数据项，才能计数出来。
* &lt;entry>: 表示真正存放数据的数据项，长度不定。一个数据项（entry）也有它自己的内部结构，这个稍后再解释。
* &lt;zlend>: ziplist最后1个字节，是一个结束标记，值固定等于255。

上面的定义中还值得注意的一点是：&lt;zlbytes>, &lt;zltail>, &lt;zllen>既然占据多个字节，那么在存储的时候就有大端（big endian）和小端（little endian）的区别。ziplist采取的是小端模式来存储，这在下面我们介绍具体例子的时候还会再详细解释。

我们再来看一下每一个数据项&lt;entry>的构成：

**&lt;prevrawlen>&lt;len>&lt;data>**

我们看到在真正的数据（&lt;data>）前面，还有两个字段：

* prevrawlen: 表示前一个数据项占用的总字节数。这个字段的用处是为了让ziplist能够从后向前遍历（从后一项的位置，只需向前偏移prevrawlen个字节，就找到了前一项）。这个字段采用变长编码。
* len: 表示当前数据项的数据长度（即&lt;data>部分的长度）。也采用变长编码。

那么prevrawlen和len是怎么进行变长编码的呢？各位读者打起精神了，我们终于讲到了ziplist的定义中最繁琐的地方了。

先说prevrawlen。它有两种可能，或者是1个字节，或者是5个字节：

1. 如果前一个数据项占用字节数小于254，那么prevrawlen就只用一个字节来表示，这个字节的值就是前一个数据项的占用字节数。
2. 如果前一个数据项占用字节数大于等于254，那么prevrawlen就用5个字节来表示，其中第1个字节的值是254（作为这种情况的一个标记），而后面4个字节组成一个整型值，来真正存储前一个数据项的占用字节数。

有人会问了，为什么没有255的情况呢？

这是因为：255已经定义为ziplist结束标记&lt;zlend>的值了。在ziplist的很多操作的实现中，都会根据数据项的第1个字节是不是255来判断当前是不是到达ziplist的结尾了，因此一个正常的数据的第1个字节（也就是prevrawlen的第1个字节）是不能够取255这个值的，否则就冲突了。

而len字段就更加复杂了，它根据第1个字节的不同，总共分为9种情况（下面的表示法是按二进制表示）：

1. \|00pppppp\| - 1 byte。第1个字节最高两个bit是00，那么len字段只有1个字节，剩余的6个bit用来表示长度值，最高可以表示63 (2^6-1)。
2. \|01pppppp\|qqqqqqqq\| - 2 bytes。第1个字节最高两个bit是01，那么len字段占2个字节，总共有14个bit用来表示长度值，最高可以表示16383 (2^14-1)。
3. \|10______\|qqqqqqqq\|rrrrrrrr\|ssssssss\|tttttttt\| - 5 bytes。第1个字节最高两个bit是10，那么len字段占5个字节，总共使用32个bit来表示长度值（6个bit舍弃不用），最高可以表示2^32-1。需要注意的是：在前三种情况下，&lt;data>都是按字符串来存储的；从下面第4种情况开始，&lt;data>开始变为按整数来存储了。
4. \|11000000\| - 1 byte。len字段占用1个字节，值为0xC0，后面的数据&lt;data>存储为2个字节的int16_t类型。
5. \|11010000\| - 1 byte。len字段占用1个字节，值为0xD0，后面的数据&lt;data>存储为4个字节的int32_t类型。
6. \|11100000\| - 1 byte。len字段占用1个字节，值为0xE0，后面的数据&lt;data>存储为8个字节的int64_t类型。
7. \|11110000\| - 1 byte。len字段占用1个字节，值为0xF0，后面的数据&lt;data>存储为3个字节长的整数。
8. \|11111110\| - 1 byte。len字段占用1个字节，值为0xFE，后面的数据&lt;data>存储为1个字节的整数。
9. \|1111xxxx\| - - (xxxx的值在0001和1101之间)。这是一种特殊情况，xxxx从1到13一共13个值，这时就用这13个值来表示真正的数据。注意，这里是表示真正的数据，而不是数据长度了。也就是说，在这种情况下，后面不再需要一个单独的&lt;data>字段来表示真正的数据了，而是&lt;len>和&lt;data>合二为一了。另外，由于xxxx只能取0001和1101这13个值了（其它可能的值和其它情况冲突了，比如0000和1110分别同前面第7种第8种情况冲突，1111跟结束标记冲突），而小数值应该从0开始，因此这13个值分别表示0到12，即xxxx的值减去1才是它所要表示的那个整数数据的值。

好了，ziplist的数据结构定义，我们介绍了完了，现在我们看一个具体的例子。

[<img src="/assets/photos_redis/redis_ziplist_sample.png" style="width:600px" alt="Redis Ziplist Sample" />](/assets/photos_redis/redis_ziplist_sample.png)

上图是一份真实的ziplist数据。我们逐项解读一下：

* 这个ziplist一共包含33个字节。字节编号从byte[0]到byte[32]。图中每个字节的值使用16进制表示。
* 头4个字节（0x21000000）是按小端（little endian）模式存储的&lt;zlbytes>字段。什么是小端呢？就是指数据的低字节保存在内存的低地址中（参见维基百科词条[Endianness](https://en.wikipedia.org/wiki/Endianness){:target="_blank"}）。因此，这里&lt;zlbytes>的值应该解析成0x00000021，用十进制表示正好就是33。
* 接下来4个字节（byte[4..7]）是&lt;zltail>，用小端存储模式来解释，它的值是0x0000001D（值为29），表示最后一个数据项在byte[29]的位置（那个数据项为0x05FE14）。
* 再接下来2个字节（byte[8..9]），值为0x0004，表示这个ziplist里一共存有4项数据。
* 接下来6个字节（byte[10..15]）是第1个数据项。其中，prevrawlen=0，因为它前面没有数据项；len=4，相当于前面定义的9种情况中的第1种，表示后面4个字节按字符串存储数据，数据的值为"name"。
* 接下来8个字节（byte[16..23]）是第2个数据项，与前面数据项存储格式类似，存储1个字符串"tielei"。
* 接下来5个字节（byte[24..28]）是第3个数据项，与前面数据项存储格式类似，存储1个字符串"age"。
* 接下来3个字节（byte[29..31]）是最后一个数据项，它的格式与前面的数据项存储格式不太一样。其中，第1个字节prevrawlen=5，表示前一个数据项占用5个字节；第2个字节=FE，相当于前面定义的9种情况中的第8种，所以后面还有1个字节用来表示真正的数据，并且以整数表示。它的值是20（0x14）。
* 最后1个字节（byte[32]）表示&lt;zlend>，是固定的值255（0xFF）。

总结一下，这个ziplist里存了4个数据项，分别为：

* 字符串: "name"
* 字符串: "tielei"
* 字符串: "age"
* 整数: 20

（好吧，被你发现了~~我实际上当然不是20岁，我哪有那么年轻......）

实际上，这个ziplist是通过两个hset命令创建出来的。这个我们后半部分会再提到。

好了，既然你已经看到这了，说明你还是很有耐心的。可以先把本文收藏，休息一下，回头再看后半部分。

接下来我要贴一些代码了。



