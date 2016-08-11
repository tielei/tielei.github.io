---
layout: post
category: "other"
title: "技术的正宗与野路子"
date: 2016-08-10 01:00:00 +0800
published: true
---

> 黄衫女子的武功似乎与周芷若乃是一路，飘忽灵动，变幻无方，但举手抬足之间却是正而不邪，如说周芷若形似鬼魅，那黄衫女子便是态拟神仙。

这段描写出自《倚天屠龙记》第三十八回。

<!--more-->

“九阴神抓”本是《九阴真经》中的上乘武功，但当初梅超风夫妇由于拿到的《九阴真经》不完整，学不到里面的内功心法，硬是把这门上乘武功练到了邪路上，于是就成了“九阴白骨爪”。周芷若为求速成，也练就了这门邪功。

但黄衫女子乃出身武林名门（相传是杨过和小龙女的后人），自然修炼的是正宗的《九阴真经》。虽然武功路数与周芷若本同属一脉，但更加“醇真深厚”，自然也更胜一筹。这是金庸武侠中“正宗”武功胜过“野路子”的一个典型案例。

那么，这是否能够说明，“正宗”一定强于“野路子”呢？

且慢！

喜欢金庸武侠的朋友，可还记得《越女剑》中的阿青？

阿青本是一名牧羊女，却在牧羊时巧遇一头会使竹棒的白猿。在与白猿的玩耍嬉闹中，她硬是悟得了高超的剑法，竟能以一人之力敌两千越甲！

就是这样一个从野路子练出来的柔弱女子，即使按广大金庸迷的保守估计，她也能在整个金庸武侠图谱中至少排名前五！

---

做技术，犹如修习一门武功。

历数我周围的技术牛人（牛不到一定程度的先不算），他们中既有名牌大学计算机科班毕业的，也有半路出家转行过来的。

但他们都有一个共同特点：他们在遇到问题后，思考片刻，总是能一下子切中要害，在表达上也往往一语中的。这也包括那些平常不善言辞的程序员。反观那些“更一般”的程序员（其中不乏科班毕业的），他们经常很难抓住问题的本质，表达起来也总是说不到点子上。

可见，“正宗”还是“野路子”，并不在出身。

写到这里，我终于自己长出了一口气。我出身一个极普通的农民家庭，既不是书香门第，也不是技匠世家。记得在大学一年级的上机编程课上，我才发现自己原来根本不会用键盘打字。相比那些初中高中就把计算机玩得很溜的同学，我算野路子吗？

好了，那“正宗”还是“野路子”，不在出身在什么呢？

在于学习和思考的方法。

据我观察，技术牛人的学习方法和思考方式，大体类似。

思考方式，是个很难说清的东西。所以，本文我们重点来讨论讨论学习的方法。

---

面对一项新技术的时候，我们怎样去学习才能循序渐进，最终理解得深刻？

让我们先把可供自学的资料列出来，分析一下：

* Tutorial（入门教程）。由该项技术的官网提供。通常是英文的。这份资料是给初次接触该项技术的人看的，一般是一步一步地教你完成某些例子。当我们说某项技术对于新手不太友好的时候，一般也是因为这项技术的Tutorial部分做得不够好。
* Specification，简称Spec。这是集中体现该项技术的设计思想的东西，是高度抽象的描述。这个一般也是一份完备的、系统的描述，包含该项技术涉及到的方方面面。这部分资料在不同的地方叫法不同，在相对简单的技术项目中，也可能没有；在另一些情况下，这部分资料混杂在其它文档资料之中；它还可能以论文（paper）的形式出现。
* API Reference。大而全的API索引和文档，针对不同的语言接口可能提供多份。当我们使用这项技术进行编程的时候，API Reference自然是个离不开的、总是要不停去查询的一份资料。
* 别人写的技术博客。质量良莠不齐，到底有没有价值，我们要学会去分辨。
* 技术书籍。跟技术博客类似，质量有好有坏。稍后我们和技术博客放在一起来分析。
* Source Code。如果我们要学习的技术是开源的，那么很幸运，我们能得到源代码。这是一份终极资料。

为了让这些概念表达无误，我接下来多举一些例子。

#### Java语言

从来没有接触过Java语言的人，要想开始自学Java，从哪里开始呢？可以从Oracle官方提供的Tutorial入手：

* <http://docs.oracle.com/javase/tutorial/>{:target="_blank"} 

这份资料《The Java™ Tutorials 》，集中体现了Tutorial类型的资料的特点。它从最开始的编译和运行环境搭建说起，教你写出第一个Hello World，再用介绍的方式将Java各种语言特性（变量、类、泛型、Lambda表达式、JavaBeans，等等）进行讲解，同时还有对于JDK里常用API（集合类、多线程、IO等等）的介绍。

对初学者而言，需要的就是这样一份资料。即使你手头没有任何Java的入门书籍，读完这样的一份资料之后，一个新手基本就可以开始使用Java来编程了。

再看Spec：

* <http://docs.oracle.com/javase/specs/jls/se8/html/index.html>{:target="_blank"} 

这份文档，叫做《The Java® Language Specification》。是一份很典型的Spec，完备而规范。

任何讲Java语法的资料，包括各种书籍和前面提到的Tutorial，都只能涉及部分。而这份Spec，如果你能读通的话，那么与Java语言特性有关的所有一切，你就再也不用求人了。

JDK 8的API Reference:

* <http://docs.oracle.com/javase/8/docs/api/index.html>{:target="_blank"} 

用Java语言编程的时候，我们需要不断查阅的就是这份API Reference。我们平常一般是通过IDE来快速查看某个接口的文档说明。

#### Android开发

Android针对新手的Tutorial类型的资料，官网上称为Training：

* <https://developer.android.com/training/index.html>{:target="_blank"} 

[<img src="/assets/photos_learn/android_tutorial_training.png" style="width:600px" alt="Android Training" />](/assets/photos_learn/android_tutorial_training.png)

这份资料是典型的Tutorial。它教你制作第一个Android App，并针对若干个主题进行一步一步的教学。

下面这份资料在Android官网上被称为：API Guides。

* <https://developer.android.com/guide/index.html>{:target="_blank"} 

[<img src="/assets/photos_learn/android_spec_api_guides.png" style="width:600px" alt="Android API Guides" />](/assets/photos_learn/android_spec_api_guides.png)


它实际上是一份介于Tutorial和Spec之间的文档。它有很多Spec的特点，比如它介绍Android中的抽象的四大组件的概念，介绍资源尺寸的抽象（dp），介绍View层原理，等等。但是，跟前面看到的Java Spec相比，它没有那么规范和正式，描述也更随意一些，估计也算不上完备（但涉及到了Android技术的绝大部分）。

当我们对Android中某项具体技术存疑，或是有争论的时候，我们就需要来翻翻这份文档。因此，它基本可以归入Spec类型。

然后是Android SDK的API Reference：

* <https://developer.android.com/reference/packages.html>{:target="_blank"} 

这份API Reference的质量并不高，描述上过于简略，甚至模糊不清，其可读性跟前面提到的JDK 8的API Reference完全不在一个水平上。这也是一些开源项目的通病，不重视接口文档。

#### iOS开发

苹果在iOS开发方面给出的文档是相当丰富的，这也是一个闭源系统做得好的地方。

iOS开发的文档，很难区分出Tutorial和Spec这两个层面。它由很多文档组成，每个文档描述系统的某一方面。通常是在一个文档中，既有教学的部分，又有完备描述的部分。

针对完全的新手入门的话，下面这个文档，算是真正的一个Tutorial：

* [Start Developing iOS Apps (Swift)](https://developer.apple.com/library/ios/referencelibrary/GettingStarted/DevelopiOSAppsSwift/index.html){:target="_blank"} (https://developer.apple.com/library/ios/referencelibrary/GettingStarted/DevelopiOSAppsSwift/index.html)

其它各个文档也是介于Tutorial和Spec之间，更偏向Spec。比如：

* [App Programming Guide for iOS](https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Introduction/Introduction.html){:target="_blank"} (https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Introduction/Introduction.html)
* [View Controller Programming Guide for iOS](https://developer.apple.com/library/ios/featuredarticles/ViewControllerPGforiPhoneOS/index.html){:target="_blank"} (https://developer.apple.com/library/ios/featuredarticles/ViewControllerPGforiPhoneOS/index.html)
* [View Programming Guide for iOS](https://developer.apple.com/library/ios/documentation/WindowsViews/Conceptual/ViewPG_iPhoneOS/Introduction/Introduction.html){:target="_blank"} (https://developer.apple.com/library/ios/documentation/WindowsViews/Conceptual/ViewPG_iPhoneOS/Introduction/Introduction.html)
* [Core Animation Programming Guide](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CoreAnimation_guide/Introduction/Introduction.html){:target="_blank"} (https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CoreAnimation_guide/Introduction/Introduction.html)
* [Concurrency Programming Guide](https://developer.apple.com/library/ios/documentation/General/Conceptual/ConcurrencyProgrammingGuide/Introduction/Introduction.html){:target="_blank"} (https://developer.apple.com/library/ios/documentation/General/Conceptual/ConcurrencyProgrammingGuide/Introduction/Introduction.html)


然后是iOS的API Reference：

* <https://developer.apple.com/reference/>{:target="_blank"} 

如前所述，这份API Reference的可读性非常高，比Android SDK的要强多了。很多前后相关的概念，在这份API Reference的描述中，都有体现。

当然，除了developer.apple.com之外，iOS的文档也都可以通过XCode取到。

#### Redis

Redis的Tutorial是我见过的最好的Tutorial，它对初学者非常友好，不仅能读，还能执行。

* <http://try.redis.io/>{:target="_blank"} 

[<img src="/assets/photos_learn/redis_tutorial.png" style="width:600px" alt="Redis Tutorial" />](/assets/photos_learn/redis_tutorial.png)

Redis的Spec举例:

* [Redis Protocol specification](http://redis.io/topics/protocol){:target="_blank"} (http://redis.io/topics/protocol)
* [Redis Cluster Specification](http://redis.io/topics/cluster-spec){:target="_blank"} (http://redis.io/topics/cluster-spec)
* [Redis RDB Dump File Format](https://github.com/sripathikrishnan/redis-rdb-tools/wiki/Redis-RDB-Dump-File-Format){:target="_blank"} (https://github.com/sripathikrishnan/redis-rdb-tools/wiki/Redis-RDB-Dump-File-Format)

Redis的Commands Reference:

* <http://redis.io/commands>{:target="_blank"} 

#### TCP/HTTP

网络协议与前面的都不同，它不是一个实现，而是一种标准。

网络协议的Spec文档很明显，就是它们对应的RFC。如果你的工作经常涉及到使用某个网络协议，恐怕就需要找来RFC通读一遍了。

---

再来说一下技术博客和技术书籍。

现在网上的技术文章空前繁荣，想读都读不过来。胡峰同学在他的微信公众号“瞬息之间”上，发过一篇文章《技术干货的选择性问题》，讨论的就是技术人员在当前技术文章爆炸的情况下如何取舍的问题。

在这里，我们从另一个角度来讨论一下这个问题。如果一篇技术文章，仅仅是对于所涉及技术的官方文档（Tutorial或Spec）的复述，甚至只是个翻译，那么就价值不高。换句话说，如果我们能通过阅读官方文档学到同样的知识，那为什么要看你写的技术文章呢？官方文档自然更权威，直接阅读它能确保不会遗漏重要的东西。

那什么样的技术文章才有价值呢？大概可以说（未必那么准确），那些包涵了实践经验的，能将各个技术点综合起来产生思考，从而给人以启迪的。简单来说，就是有深度的。

当然，技术书籍也大体如此。

---

我们回过头来再看一下，各个学习资料之间的层次结构。

[<img src="/assets/photos_learn/learn_doc_hierarchy.png" style="width:600px" alt="学习资料的金字塔" />](/assets/photos_learn/learn_doc_hierarchy.png)

每当我们接触一项新的技术的时候，我们都要把手头的资料按照类似的这样一个金字塔结构进行分类。如果我们阅读了一些技术博客和技术书籍，那么也要清楚地知道它们涉及到的是金字塔中的哪些部分。

最开始，一般读完Tutorial之后，就基本能上手做一些开发工作了。然后一边开发，一边查阅API Reference。注意，从这时候起，你的老板就开始向你付工资了，因为你的工作已经能够产出成果了。

但是，工作一段时间之后，我们发现，似乎身边的技术牛人学东西都比较快，而且在很短的时间内就能对某项新技术达到很深的理解。这是为什么呢？

这并不是因为技术牛人阅读技术资料阅读得快，而是他们知道阅读正确的资料，从而很快能达到知识金字塔更高的一层。

我见过的很多技术牛人，他们如果不是把一项技术至少理解到Spec那个层次，他们是不敢随便写代码的。相反另一些人则从网上随意拷贝代码，并在自己不能完全理解的情况下用到项目中去。技术牛人们当然也参考网上的代码，但他们通常会确保它的每一部分都能安放在知识金字塔的某一部分，他们不容许那种不属于任何体系的知识孤岛的出现。

我们现在可以这样总结，技术的“野路子”，其实是知识结构的不完整和不系统造成的一种状态。只有当你冲破知识金字塔层层的障碍，迈向更高层次的时候，老板才开始向你付高价。

---

我们的大脑好比内存。

既然是内存，就装不下所有的知识。但应该能装下对于知识的索引，否则我们便没法工作了。

那么，这里就有一个选择性的问题：我们选择哪部分知识加载到“内存”里呢？

显然，应该优先选择重要的，对我们最有用的信息。

对于那些最核心的技术，我们应该做到：

* 通读Spec。读完就不再困惑。
* 重要部分的API Reference要通读。里面包含了很多跟实现有关的信息。
* 如果工作需要，还可能需要读到Source Code。特别是对于平常一直在使用的SDK，不一定从头到尾把源码读通，这样工作量太大且效率不高，但**一定要把你的开发环境设置成一点击某个调用的方法就能跳转进源码实现**。只有这样，你才能把平常开发的时间利用起来，随时随刻都点过去看源码。

对于剩下的知识里80%的部分，应该至少理解到Spec层次。只有这样，我们才能游刃有余地去使用它。

通读重要的Spec，在很多情况下，其实还是很有难度的。这需要毅力，和一点点英语基础。

按本文前面提到的例子，做Java的人有谁读过Java Spec？做Android的人有谁把developer.android.com上的API Guides都能通读下来？而做iOS的人，developer.apple.com上的各个Programming Guide又完整地读过几个？对于经常调用的SDK，你会有计划地去通读其中重要部分的API Reference吗？

能够把这一套做下来的，有可能不成为技术牛人吗？

---

到了文章最后了，总感觉还有些意犹未尽，脑海中似乎有些东西还是没有表达出来，也不确定本文描述的学习方式是不是适用于每位读者。仔细想想也难怪，学习本来就是一个复杂的问题，每个人并不是完全一样的套路。

但是，不管本文介绍的方法是“正宗”的路子，还是属于“野路子”，我在这里想要强调的一点是很明确的，那就是：要把知识梳理成系统的结构，要让头脑中的知识层次清楚，为此，我们需要阅读恰当的东西，需要不断地练习，需要克服种种困难。

成长没有捷径可走。需要的是一个一个坚实的突破。

（完）