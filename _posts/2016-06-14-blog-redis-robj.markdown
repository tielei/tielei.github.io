---
layout: post
category: "server"
title: "Redis内部数据结构详解(3)——robj"
date: 2016-06-14 18:30:00 +0800
published: true
---

本文是《[Redis内部数据结构详解](/posts/blog-redis-dict.html)》系列的第三篇，讲述在Redis实现中的一个基础数据结构：robj。

那到底什么是robj呢？它有什么用呢？

<!--more-->

从Redis的使用者的角度来看，一个Redis节点包含多个database（非cluster模式下默认是16个，cluster模式下只能是1个），而一个database维护了从key space到object space的映射关系。这个映射关系的key是string类型，而value可以是多种数据类型，比如：string, list, hash等。我们可以看到，key的类型固定是string，而value可能的类型是多个。

而从Redis内部实现的角度来看，在前面第一篇文章中，我们已经提到过，一个database内的这个映射关系是用一个dict来维护的。dict的key固定用一种数据结构来表达就够了，这就是动态字符串sds。而value则比较复杂，为了在同一个dict内能够存储不同类型的value，这就需要一个通用的数据结构，这个通用的数据结构就是robj（全名是redisObject）。举个例子：如果value是一个list，那么它的内部存储结构是一个quicklist（quicklist的具体实现我们放在后面的文章讨论）；如果value是一个string，那么它的内部存储结构一般情况下是一个sds。当然实际情况更复杂一点，比如一个string类型的value，如果它的值是一个数字，那么Redis内部还会把它转成long型来存储，从而减小内存使用。而一个robj既能表示一个sds，也能表示一个quicklist，甚至还能表示一个long型。

#### robj的数据结构定义

在server.h中我们找到跟robj定义相关的代码，如下（注意，本系列文章中的代码片段全部来源于Redis源码的3.2分支）：

{% highlight c %}
/* Object types */
#define OBJ_STRING 0
#define OBJ_LIST 1
#define OBJ_SET 2
#define OBJ_ZSET 3
#define OBJ_HASH 4

/* Objects encoding. Some kind of objects like Strings and Hashes can be
 * internally represented in multiple ways. The 'encoding' field of the object
 * is set to one of this fields for this object. */
#define OBJ_ENCODING_RAW 0     /* Raw representation */
#define OBJ_ENCODING_INT 1     /* Encoded as integer */
#define OBJ_ENCODING_HT 2      /* Encoded as hash table */
#define OBJ_ENCODING_ZIPMAP 3  /* Encoded as zipmap */
#define OBJ_ENCODING_LINKEDLIST 4 /* Encoded as regular linked list */
#define OBJ_ENCODING_ZIPLIST 5 /* Encoded as ziplist */
#define OBJ_ENCODING_INTSET 6  /* Encoded as intset */
#define OBJ_ENCODING_SKIPLIST 7  /* Encoded as skiplist */
#define OBJ_ENCODING_EMBSTR 8  /* Embedded sds string encoding */
#define OBJ_ENCODING_QUICKLIST 9 /* Encoded as linked list of ziplists */

#define LRU_BITS 24
typedef struct redisObject {
    unsigned type:4;
    unsigned encoding:4;
    unsigned lru:LRU_BITS; /* lru time (relative to server.lruclock) */
    int refcount;
    void *ptr;
} robj;
{% endhighlight %}

一个robj包含如下5个字段：

* type: 对象的数据类型。占4个bit。可能的取值有5种：OBJ_STRING, OBJ_LIST, OBJ_SET, OBJ_ZSET, OBJ_HASH，分别对应Redis对外暴露的5种数据结构（即我们在第一篇文章中提到的第一个层面的5种数据结构；从使用者的角度）。
* encoding: 对象的内部表示方式（也可以称为编码）。占4个bit。可能的取值有10种，即前面代码中的10个OBJ_ENCODING_XXX常量。
* lru: 做LRU替换算法用，占24个bit。这个不是我们这里讨论的重点，暂时忽略。
* refcount: 引用计数。它允许robj对象在某些情况下被共享。
* ptr: 数据指针。指向真正的数据。比如，一个代表string的robj，它的ptr可能指向一个sds结构；一个代表list的robj，它的ptr可能指向一个quicklist。

这里特别需要仔细察看的是encoding字段。对于同一个type，还可能对应不同的encoding，这说明同样的一个数据类型，可能存在不同的内部表示方式。而不同的内部表示，在内存占用和查找性能上会有所不同。

比如，当type = OBJ_STRING的时候，表示这个robj存储的是一个string，这时encoding可以是下面3种中的一种：

* OBJ_ENCODING_RAW: string采用原生的表示方式，即用sds来表示。
* OBJ_ENCODING_INT: string采用数字的表示方式，实际上是一个long型。
* OBJ_ENCODING_EMBSTR: string采用一种特殊的嵌入式的sds来表示。接下来我们会讨论到这个细节。

再举一个例子：当type = OBJ_HASH的时候，表示这个robj存储的是一个hash，这时encoding可以是下面2种中的一种：

* OBJ_ENCODING_HT: hash采用一个dict来表示。
* OBJ_ENCODING_ZIPLIST: hash采用一个ziplist来表示（quicklist的具体实现我们放在后面的文章讨论）。

本文剩余主要部分将针对表示string的robj对象，围绕它的3种不同的encoding来深入讨论。前面代码段中出现的所有10种encoding，在这里我们先简单解释一下，在这个系列后面的文章中，我们应该还有机会碰到它们。

* OBJ_ENCODING_RAW: 最原生的表示方式。其实只有string类型才会用这个encoding值（表示成sds）。
* OBJ_ENCODING_INT: 表示成数字。实际用long表示。
* OBJ_ENCODING_HT: 表示成dict。
* OBJ_ENCODING_ZIPMAP: 是个旧的表示方式，已不再用。在小于Redis 2.6的版本中才有。
* OBJ_ENCODING_LINKEDLIST: 也是个旧的表示方式，已不再用。
* OBJ_ENCODING_ZIPLIST: 表示成ziplist。
* OBJ_ENCODING_INTSET: 表示成intset。用于set数据结构。
* OBJ_ENCODING_SKIPLIST: 表示成skiplist。用于sorted set数据结构。
* OBJ_ENCODING_EMBSTR: 表示成一种特殊的嵌入式的sds。
* OBJ_ENCODING_QUICKLIST: 表示成quicklist。用于list数据结构。

我们来总结一下robj的作用：

* 为多种数据类型提供一种统一的表示方式。
* 允许同一类型的数据采用不同的内部表示，从而在某些情况下尽量节省内存。
* 支持对象共享和引用计数。

#### string robj的编码过程

当我们执行Redis的set命令的时候，Redis首先将接收到的value值（string类型）表示成一个type = OBJ_STRING并且encoding = OBJ_ENCODING_RAW的robj对象，然后在存入内部存储之前先执行一个编码过程，试图将它表示成另一种更节省内存的encoding方式。这一过程的核心代码，是object.c中的tryObjectEncoding函数。


{% highlight c %}
robj *tryObjectEncoding(robj *o) {
    long value;
    sds s = o->ptr;
    size_t len;

    /* Make sure this is a string object, the only type we encode
     * in this function. Other types use encoded memory efficient
     * representations but are handled by the commands implementing
     * the type. */
    serverAssertWithInfo(NULL,o,o->type == OBJ_STRING);

    /* We try some specialized encoding only for objects that are
     * RAW or EMBSTR encoded, in other words objects that are still
     * in represented by an actually array of chars. */
    if (!sdsEncodedObject(o)) return o;

    /* It's not safe to encode shared objects: shared objects can be shared
     * everywhere in the "object space" of Redis and may end in places where
     * they are not handled. We handle them only as values in the keyspace. */
     if (o->refcount > 1) return o;

    /* Check if we can represent this string as a long integer.
     * Note that we are sure that a string larger than 21 chars is not
     * representable as a 32 nor 64 bit integer. */
    len = sdslen(s);
    if (len <= 21 && string2l(s,len,&value)) {
        /* This object is encodable as a long. Try to use a shared object.
         * Note that we avoid using shared integers when maxmemory is used
         * because every object needs to have a private LRU field for the LRU
         * algorithm to work well. */
        if ((server.maxmemory == 0 ||
             (server.maxmemory_policy != MAXMEMORY_VOLATILE_LRU &&
              server.maxmemory_policy != MAXMEMORY_ALLKEYS_LRU)) &&
            value >= 0 &&
            value < OBJ_SHARED_INTEGERS)
        {
            decrRefCount(o);
            incrRefCount(shared.integers[value]);
            return shared.integers[value];
        } else {
            if (o->encoding == OBJ_ENCODING_RAW) sdsfree(o->ptr);
            o->encoding = OBJ_ENCODING_INT;
            o->ptr = (void*) value;
            return o;
        }
    }

    /* If the string is small and is still RAW encoded,
     * try the EMBSTR encoding which is more efficient.
     * In this representation the object and the SDS string are allocated
     * in the same chunk of memory to save space and cache misses. */
    if (len <= OBJ_ENCODING_EMBSTR_SIZE_LIMIT) {
        robj *emb;

        if (o->encoding == OBJ_ENCODING_EMBSTR) return o;
        emb = createEmbeddedStringObject(s,sdslen(s));
        decrRefCount(o);
        return emb;
    }

    /* We can't encode the object...
     *
     * Do the last try, and at least optimize the SDS string inside
     * the string object to require little space, in case there
     * is more than 10% of free space at the end of the SDS string.
     *
     * We do that only for relatively large strings as this branch
     * is only entered if the length of the string is greater than
     * OBJ_ENCODING_EMBSTR_SIZE_LIMIT. */
    if (o->encoding == OBJ_ENCODING_RAW &&
        sdsavail(s) > len/10)
    {
        o->ptr = sdsRemoveFreeSpace(o->ptr);
    }

    /* Return the original object. */
    return o;
}
{% endhighlight %}

这段代码执行的主要操作包括：

* 第1步检查，检查type。确保只对string类型的对象进行操作。
* 第2步检查，检查encoding。sdsEncodedObject是定义在server.h中的一个宏，确保只对OBJ_ENCODING_RAW和OBJ_ENCODING_EMBSTR编码的string对象进行操作。
* 第3步检查，检查refcount。引用计数大于1的共享对象，在多处被引用。由于编码过程结束后robj的对象指针可能会变化（我们在前一篇介绍sdscatlen函数的时候提到过类似这种接口使用模式），这样对于引用计数大于1的对象，就需要更新所有地方的引用，这不容易做到。因此，对于计数大于1的对象不做编码处理。
* 试图将字符串转成64位的long。64位的long的能表达的数据范围是-2^63到2^63-1，十进制表达出来最长是20位数（包括负号）。这里判断小于等于21，似乎是写多了，实际判断小于等于20就够了（如果我算错了请一定告诉我哦）。string2l如果将字符串转成long转成功了，那么会返回1并且将转好的long存到value变量里。
* 在转成long成功时，又分为两种情况。


#### string robj的解码过程

