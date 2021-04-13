---
layout: post
category: "distributed_system"
title: "号称分布式领域最重要的一篇论文，到底讲了什么？"
date: 2021-04-11 00:00:00 +0800
published: true
---

正在阅读本文的读者们，可能之前已经读过了我写的有关[线性一致性、顺序一致性](https://mp.weixin.qq.com/s/3odLhBtebF4cm58hl-87JA)以及[因果一致性](https://mp.weixin.qq.com/s/wkXsRufVsbKqTwjzTgNqYQ)的分析文章。这些一致性模型的关键在于，它们定义了一个系统在分布式环境下对于读写操作的某种排序规则。

<!--more-->

没错，分布式系统内的事件排序，涉及到最深层的本质问题。图灵奖得主Lamport在1978年发表的经典论文，《Time, Clocks, and the Ordering of Events in a Distributed System》[1]，正是对这些本质问题的一个系统化的阐述。

今天，我们就来一起研究一下，这篇号称分布式领域最具影响力的论文，到底讲了什么。

### 为什么这篇论文如此重要？

先讲一个小故事。

两位研究人员Paul Johnson和Bob Thomas在1975年发表了一篇论文[2]，提出了一种基于消息时间戳的分布式算法。Lamport看到这篇论文后，很快就发现了算法存在的一些问题。他向论文作者指出了错误并帮助修正了算法。

在Lamport的自述中，他之所以能够指出算法的错误，是因为他对相对论有比较深入的理解[3]。他一眼就看透了Paul Johnson和Bob Thomas的算法的本质，用他自己的话来讲：

> I realized that the essence of Johnson and Thomas’s algorithm was the use of timestamps to provide a total ordering of events that was consistent with the causal order.  
> (译文：我意识到，Johnson和Thomas提出的算法的本质在于使用时间戳来提供事件的一种全局排序，而这种排序是和因果顺序保持一致的。)

在认识到这个「本质」之后，Lamport写成了《Time, Clocks, and the Ordering of Events in a Distributed System》[1]这篇论文，后来成为了分布式领域的经典论文，也是Lamport被引用次数最多的论文。

要理解这件事相关的描述，必须对事件偏序、因果性、相对论等概念有基本的了解。但这不是我们目前的重点（相关讨论会在下一章节开始）。现在你只要记住，这篇论文之所以经典，是因为它揭示了分布式系统的某些深层本质，深深地影响了人们对于分布式系统的思考方式。

当然，这篇论文除了理论意义和历史价值之外，它与业界一些重要的分布式系统实践也都有紧密的联系。比如，在大规模的分布式环境下产生单调递增的时间戳，是个很难的问题，而谷歌的全球级分布式数据库Spanner就解决了这个问题，甚至能够在跨越遍布全球的多个数据中心之间高效地产生单调递增的时间戳。做到这一点，靠的是一种称为TrueTime的机制，而这种机制的理论基础就是Lamport这篇论文中的物理时钟算法（两者之间有千丝万缕的联系）。再比如，这篇论文中定义的「Happened Before」关系，不仅在分布式系统设计中成为考虑不同事件之间关系的基础，而且在多线程编程模型中也是重要的概念。另外，还有让很多人忽视的一点是，利用分布式状态机来实现数据复制的通用方法（State Machine Replication，简称SMR），其实也是这篇论文首创的。

总之，如果在整个分布式的技术领域中，你只有精力阅读一篇论文，那一定要选这一篇了。只有理解了这篇论文中揭示的这些涉及时间、时钟和排序的概念，我们才能真正在面对分布式系统的设计问题时游刃有余。

### 分布式系统中的事件和偏序关系

从论文的题目看，《Time, Clocks, and the Ordering of Events in a Distributed System》，论文主要是讲三个基础概念：时间（Time）、时钟（Clock）、事件排序（Ordering of Events）。它们之间的关系大概是：
* 一个分布式系统由很多进程组成，而一个进程可以看成是一个事件序列。所以说，事件是一个抽象概念，根据应用场景不同，程序运行发生的任何事情都可以表示成事件。比如，根据论文中举的例子，一个子程序开始执行，可以看成是一个事件；一条机器指令的执行，也可以看成一个事件。
* 时间是一个物理学上的概念。每个事件发生的时候，都对应时间的某个数值。而根据相对论，时空是不可分割的，时间必须与空间一起讨论才有意义。
* 时钟分两种，一种是物理时钟（Physical Clock），或者叫实时时钟（Real Clock）；另一种是逻辑时钟（Logical Clock）。物理时钟是对时间的一种度量；现实中的物理时钟肯定是有误差的。而逻辑时钟是跟物理时间无关的，用于对每一个发生的事件指派一个单调递增的数值，是系统执行节拍的一种内部表示。
* 两个不同的事件，可能具有先后关系，它们之间是能够排序的；也可能两个事件之间根本无法按照先后关系来排序。也就是说，事件排序是偏序的（Partial Ordering）。

论文实际上是从事件开始讲起的。进程的执行被看成是一连串事件的持续发生。随后，事件之间的排序问题就很自然地被提出来了。联系我们日常的系统设计实践，我们就经常需要对分布式系统中的不同事件的发生次序进行比较。比如我们在之前的文章中讨论的各种一致性模型，主要就是给予不同读写操作（事件）一个合理的排序；再比如为了实现串行化（Serializability）的事务隔离性，也需要判定各个事务操作之间的排序。这些排序问题，可能涉及到在一个进程内部的多个事件之间排序，这通常还是比较容易的；同时还可能涉及到对发生在不同进程（位于不同节点上）上的事件进行排序，这通常就没有那么直观了。

如果我们说事件a在事件b之前发生，直觉上的含义大概是：事件a发生的时间比事件b发生的时间要早。然而，这种判定事件之间次序的方式，是依赖物理时间的。这要求我们必须引入物理时钟才行，而物理时钟不可能百分之百精确。

因此，Lamport在定义事件之间的关系的时候特意避开了物理时间。这就是著名的「Happened Before」关系（用符号“→”来表示）。见下面进程P、Q和R的消息时空图（注意图中自下而上时间递增）：

[<img src="/assets/photos_causal_consistency/lamport_distributed_processes.png" style="width:400px" alt="Lamport的进程收发消息举例" />](/assets/photos_causal_consistency/lamport_distributed_processes.png)

结合上图我们举例解释一下「Happened Before」关系：
* 同一进程内部先后发生的两个事件之间，具有「Happened Before」关系。比如，在进程*Q*内部，*q*<sub>2</sub>表示一个消息接收事件，*q*<sub>4</sub>表示另一个消息的发送事件，*q*<sub>2</sub>排在*q*<sub>4</sub>前面执行，所以*q*<sub>2</sub>→*q*<sub>4</sub>。
* 同一个消息的发送事件和接收事件，具有「Happened Before」关系。比如，*p*<sub>1</sub>和*q*<sub>2</sub>分别表示同一个消息的发送事件和接收事件，所以*p*<sub>1</sub>→*q*<sub>2</sub>；同理，*q*<sub>4</sub>→*r*<sub>3</sub>。
* 「Happened Before」满足传递关系。比如，由*p*<sub>1</sub>→*q*<sub>2</sub>，*q*<sub>2</sub>→*q*<sub>4</sub>和*q*<sub>4</sub>→*r*<sub>3</sub>，可以推出*p*<sub>1</sub>→*r*<sub>3</sub>。

这种「Happened Before」关系的关键在于，它是一种偏序关系。也就是说，并不是所有事件之间都具有「Happened Before」关系。比如*p*<sub>1</sub>和*q*<sub>1</sub>两个事件就是无法比较的，*q*<sub>4</sub>和*r*<sub>2</sub>也是无法比较的。

相信阅读过上一篇文章《[条分缕析分布式：因果一致性和相对论时空](https://mp.weixin.qq.com/s/wkXsRufVsbKqTwjzTgNqYQ)》的读者，已经发现了这里的「Happened Before」关系定义与因果一致性中的因果顺序定义非常相似。实际上，因果一致性的概念[4]相当于将「Happened Before」关系应用在了读写操作之上。

Lamport在论文中是这样描述与因果性的关系的：

> Another way of viewing the definition is to say that a→b means that it is possible for event a to causally affect event b. Two events are concurrent if neither can causally affect the other.  
> (译文：看待「Happened Before」关系的另一种方式，相当于是说，a→b意味着事件a**有可能**在因果性上对事件b产生影响。如果两个事件谁也无法影响对方，那么它们就属于并发关系。)

最后要说明的是，「Happened Before」关系，几乎是分布式系统中最基础的一个概念。Lamport的论文后面的其他概念和算法，也都是以这个偏序关系为基础建立起来的。你可能已经注意到，我们在介绍「Happened Before」关系之前，在描述中有几次使用了「先后关系」这个字眼来描述两个事件之间的关系。现在我们知道，「先后关系」是一个非正式的描述，而「Happened Before」才是用于描述两个事件之间关系的最规范的、也是唯一正确的概念。这个概念清晰地表达一种偏序而非全序关系，规定了哪些事件之间不可比较，哪些事件之间具有「Happened Before」关系。随着我们对于分布式系统设计经验的不断丰富，我们会发现这一概念将贯彻到对于分布式系统设计的任何细节中去。

### 逻辑时钟

前面我们提到过，Lamport在定义事件之间的「Happened Before」关系时特意避开了物理时间。这也就意味着，对事件的「发生时间」进行度量，只能根据逻辑时钟。

逻辑时钟相当于一个函数，对于每一个发生的事件，它都能给出一个对应的数值（即给这个事件打上了一个时间戳）。用符号来表示的话就是：事件a发生时对应的时钟值（时间戳）是C〈a〉。

为什么要定义逻辑时钟这个概念呢？我们前面讨论过，在分布式系统中我们经常需要对不同的事件进行排序。那么，为了实现这种排序操作，我们很自然地就需要对事件的发生进行一种数值上的度量。我们希望，可以通过比较事件的时间戳数值大小，来判断事件发生的次序（即「Happened Before」关系）。这就好比我们通过看钟表上显示的数值来确定时间的流逝一样。

当然，逻辑时钟在给事件打时间戳的时候，必须要满足一定条件的。这个过程必须能在一定程度上反映出事件之间的「Happened Before」关系。论文这一部分最重要的就是定义了一个时钟条件（Clock Condition），如下：
* 对于任意的事件a和b：如果a→b，那么必须满足C〈a〉 \< C〈b〉。

只有满足这个时钟条件的逻辑时钟，才是真正有效的。

[<img src="/assets/photos_time_clocks/space_time_with_logical_clock.png" style="width:400px" alt="标注了逻辑时钟的消息时空图" />](/assets/photos_time_clocks/space_time_with_logical_clock.png)

为了更直观地说明逻辑时钟的含义，现在我们重新看一下前面的消息时空图（上图）。我们在图上用蓝色字体在方括号中标注了一些数字，而且在每个消息收发事件旁边都标了一个。这些数字表示某个逻辑时钟给对应的事件打的时间戳。

如果仔细检查的话，会发现图中标注的逻辑时钟是符合前面的时钟条件的。举几个例子：
* 考察进程Q内部的两个事件，*q*<sub>2</sub>→*q*<sub>4</sub>，而C〈*q*<sub>2</sub>〉 = 52 < C〈*q*<sub>4</sub>〉 = 54。
* 再考察同一个消息的发送事件和接收事件，*p*<sub>1</sub>→*q*<sub>2</sub>，而C〈*p*<sub>1</sub>〉 = 40 < C〈*q*<sub>2</sub>〉 = 52。

现在我们已经直观地看到了一个合理、有效的逻辑时钟是什么样子。至于这个逻辑时钟是怎么实现出来的（比如各个事件的时间戳的具体数值是怎么产生的），论文中给出了一种实现，我们这里就不展开讨论这些细节了。但我们需要尤其注意的是，逻辑时钟的时钟条件，是一个单向的条件，反过来是不成立的。比如：
* 我们有C〈*p*<sub>3</sub>〉 = 53 < C〈*q*<sub>4</sub>〉 = 54，但不能说明*p*<sub>3</sub>→*q*<sub>4</sub>成立。也就是说，虽然对任意两个事件来说，它们各自对应的时间戳在数值上都可以比较大小，但据此并不能得到两个事件之间存在「Happened Before」关系。从本质上看，时钟条件的这种单向推导逻辑，是由「Happened Before」关系的偏序特性所决定的。

### 为什么又需要全局排序？

我们简单回顾一下前一个章节的思路。最开始，我们引入逻辑时钟，是希望可以通过比较事件的时间戳数值大小，来判断事件之间的「Happened Before」关系。然而，最后由于时钟条件的单向推导逻辑的限制，我们发现，不能根据两个事件对应的时间戳在数值上的大小来推断出它们之间是否存在「Happened Before」关系。真是一个矛盾的结果！

导致这个矛盾的原因，还是在于「Happened Before」的偏序性。对于不具有「Happened Before」关系的两个事件来说，它们对应的时间戳数值比较大小，是没有意义的。但是，确实可以根据两个时间戳的大小，来为两个事件「指定」一个次序。这个次序是人为指定的，并不是客观上要求的。还是拿前面的消息时空图来举个例子：*p*<sub>3</sub>和*q*<sub>4</sub>这两个事件，它们之间不存在「Happened Before」关系。但是，我们发现C〈*p*<sub>3</sub>〉 = 53，C〈*q*<sub>4</sub>〉 = 54，而53 < 54，所以我们人为指定一个次序，即认为*p*<sub>3</sub>是在*q*<sub>4</sub>之前发生的。实际上，由于这两个事件之间不存在「Happened Before」关系，我们不管是认为*p*<sub>3</sub>在*q*<sub>4</sub>之前发生，还是认为*q*<sub>4</sub>在*p*<sub>3</sub>之前发生，都没有大碍。

现在，我们就引入了另外一个问题：如果我们按照逻辑时钟给出的时间戳从小到大把所有事件都排成一个序列，那么就得到了分布式系统中所有事件的全局排序。下面我们把前面进程P、Q和R的消息时空图中的所有事件，按照时间戳进行全局的大排序，会得到：
* *p*<sub>1</sub> => *r*<sub>1</sub> => *r*<sub>2</sub> => *q*<sub>1</sub> => *p*<sub>2</sub> => *q*<sub>2</sub> => *p*<sub>3</sub> => *q*<sub>3</sub> => *q*<sub>4</sub> => *q*<sub>5</sub> => *r*<sub>3</sub> => *p*<sub>4</sub> => *q*<sub>6</sub> => *r*<sub>4</sub> => *q*<sub>7</sub>

在这个排序中，所有事件之间的「Happened Before」关系都被保持住了；而本来不存在「Happened Before」关系的事件之间，我们也依据时间戳的大小，通过人为指定的方式得到了一个次序。总之，我们得到了所有事件的一种全局排序，而这种排序是和「Happened Before」关系（即因果顺序）保持一致的。

那么，这样一种全局排序有什么用呢？实际上，这是实现任何分布式系统的一种通用方法。只要我们获得了所有事件的全局排序，那么各种一致性模型对于读写操作所呈现的排序要求，很自然就能得到满足。回想一下我们在之前的文章《[条分缕析分布式：浅析强弱一致性](https://mp.weixin.qq.com/s/3odLhBtebF4cm58hl-87JA)》中的分析，线性一致性和顺序一致性所要求的，正是要把所有读写操作（对应这里的事件）重排成一个全局线性有序的序列。

实际上，之所以前面设计出了逻辑时钟，目的就是为了得到一种事件全局排序的机制。而更近一步，事件的全局排序结合状态机复制（State Machine Replication）的思想，几乎可以为任何分布式系统的设计提供思路。关于这一点，Lamport曾经写下了如下的句子[3]：
> It didn’t take me long to realize that an algorithm for totally ordering events could be used to implement any distributed system. A distributed system can be described as a particular sequential state machine that is implemented with a network of processors. The ability to totally order the input requests leads immediately to an algorithm to implement an arbitrary state machine by a network of processors, and hence to implement any distributed system.  
> (译文：我很快就意识到，对事件进行全局排序的算法，可以用于实现任何分布式系统。一个分布式系统可以被看作是一个由处理器网络实现的序列状态机。对输入请求进行全局排序的能力一旦具备，我们立即就能推导出使用处理器网络实现任意一个状态机的算法，因此可以用于实现任何分布式系统。)

### 基于逻辑时钟进行全局排序，有什么问题？


### 时间本身预示了一种偏序

因果性

### 物理时钟同步算法


### 我们这个世界


### 小结


（正文完）

##### 参考文献：

* [1] Leslie Lamport, "Time, Clocks, and the Ordering of Events in a Distributed System", 1978.
* [2] Paul R. Johnson, Robert H. Thomas, "[Robert H. Thomas](https://www.rfc-archive.org/getrfc.php?rfc=677){:target="_blank"}", 2015.
* [3] Leslie Lamport, <https://www.microsoft.com/en-us/research/publication/time-clocks-ordering-events-distributed-system/>{:target="_blank"}.
* [4] Mustaque Ahamad, Gil Neiger, James E. Burns, et al, "Causal Memory: Definitions, Implementation and Programming", 1994.

**其它精选文章**：

* [漫谈分布式系统、拜占庭将军问题与区块链](https://mp.weixin.qq.com/s/tngWdvoev8SQiyKt1gy5vw)
* [基于Redis的分布式锁到底安全吗](https://mp.weixin.qq.com/s/4CUe7OpM6y1kQRK8TOC_qQ)
* [知识的三个层次](https://mp.weixin.qq.com/s/HnbBeQKG3SibP6q8eqVVJQ)
* [看得见的机器学习：零基础看懂神经网络](https://mp.weixin.qq.com/s/chHSDuwg20LyOcuAr26MXQ)
* [给普通人看的机器学习(一)：优化理论](https://mp.weixin.qq.com/s/-lJyRREez1ITxomizuhPAw)
* [漫谈业务与平台](https://mp.weixin.qq.com/s/gPE2XTqTHaN8Bg7NnfOoBw)
* [在技术和业务中保持平衡](https://mp.weixin.qq.com/s/OUdH5RxiRyvcrFrbLOprjQ)
* [三个字节的历险](https://mp.weixin.qq.com/s/6Gyzfo4vF5mh59Xzvgm4UA)