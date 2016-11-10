---
layout: post
category: "other"
title: "互联网风雨十年，我所经历的技术变迁"
date: 2016-11-10 01:00:00 +0800
published: true
---

美国当地时间2016年10月4日，谷歌在一个新品发布会上首次提出了AI-First(人工智能优先)战略[1]。在过去的十年，谷歌一直秉承的是Mobile-First的发展思路，而未来的十年，则会迎来一场新的革命。这将是比移动互联网规模更为宏大的一场技术革命，如今，我们正站在历史的分界点上。

<!--more-->

互联网的发展就像一列高速运转起来的火车，在技术、创意和资本的相互推动下，保持着巨大的惯性一路向前。面对这个持续变化中的世界，这其中的从业者们，也只有时刻保持学习的心态，才能跟得上前进的步伐。而对于技术人员来说，随着每一次技术沿革，庞大的、不断发展的技术体系在我们面前展现出了纷繁复杂的技术分支，让每一个初窥门径的人都感到眼花缭乱。我们该学习什么，该放弃什么，哪些技术昙花一现，而哪些技术真正拥有持久的生命力，是每个人都面临的课题。

历史是一面镜子。在我们身后，由智能手机和移动互联网引发的这场变革，已经逐步走向成熟，如今仍在发挥它的威力；而在我们前面，一场以人工智能为核心的技术革命，正蓄势待发。*这是个好时光，很适合回忆。*就让我们短暂地停下来，回首过去，重温一下那些年我们所经历过的技术变迁。

---

2007年1月，当我从学校毕业进入Motorola工作的时候，公司所在的部门正致力于Linux-Java平台的研发。Linux-Java平台实际上是一个基于Linux内核的手机操作系统，它的底层是经过裁剪的Linux kernel，中间是由C和C++实现的各种支撑框架，而上层应用可以使用Java来实现，跑在JVM里面。

我当时所在的team，就是负责Linux-Java平台上Multimedia Library的研发，工作中经常涉及到的技术是OpenMAX[2]和GStreamer[3]。OpenMAX是一个多媒体技术标准，用于对一些多媒体基础功能进行抽象，从而保持可移植性，同时充分利用底层硬件以提高性能。OpenMAX对上层提供的是一个一个抽象的组件(component)，比如camera, codec, mixer，而GStreamer则处于更上层，将这些组件组合成pipeline，共同来完成更复杂的多媒体任务。在今天的Android系统上，OpenMAX和GStreamer仍然在多媒体方面是两项不可或缺的技术。

历史上，Motorola很早就开始尝试制造基于Linux系统的手机了，比如2003年发布的A760[4]，可以算是世界上第一款使用Linux系统的手机设备。但是，Motorola的Linux-Java平台最终并没有获得成功，后来随着苹果iPhone的推出和Android系统的出现，而不得不中途夭折。

而在iPhone出现之前，主流的手机操作系统是Symbian OS[5]。那是一个相对封闭的系统，对第三方开发者很不友好。上层应用可以使用Java来开发，但是是非常受限的J2ME环境。记得当时我试图学习使用J2ME写一些程序，发现它功能非常简单，基本只能运行很简单的jar包，连本地存储都没有。比如你要实现一个电子书的应用，那么你必须把电子书的资源也打包到jar里面去。

对于智能手机行业来说，2007年绝对是个特殊的年份。在这一年的1月份，以触摸屏为主要交互方式的iPhone第一次公开亮相，并在半年后开始售卖。而同时，Android系统也在同一年的11月份正式对外发布。并且，谷歌发起了一个联盟，称为Open Handset Alliance (OHA) [6]，联合了众多的科技企业（其中包括Motorola），以Android系统为核心共同制定手机设备的开放标准。

2007之后的几年里，在全球范围内，智能手机的革命开始了，而移动互联网的大幕也从此拉开。

---




技术革命，它只会默默地到来。


##### 参考文献：

* [1] <https://yourstory.com/2016/10/google-ai-strategy/>{:target="_blank"}
* [2] <https://www.khronos.org/openmax/>{:target="_blank"}
* [3] <https://gstreamer.freedesktop.org/>{:target="_blank"}
* [4] <https://en.wikipedia.org/wiki/Motorola_A760>{:target="_blank"}
* [5] <https://en.wikipedia.org/wiki/Symbian_OS>{:target="_blank"}
* [6] <https://en.wikipedia.org/wiki/Open_Handset_Alliance>{:target="_blank"}

（完）

**其它精选文章**：

* [Redis内部数据结构详解(6)——skiplist](/posts/blog-redis-skiplist.html)
* [你需要了解深度学习和神经网络这项技术吗？](/posts/blog-neural-nets.html)
* [论人生之转折](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261385&idx=1&sn=56b335b4f33546c5baa41a1c7f1b6551#rd)
* [技术的正宗与野路子](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261357&idx=1&sn=ebb11a1623e00ca8e6ad55c9ad6b2547#rd)
* [程序员的那些反模式](/posts/blog-programmer-anti-pattern.html)
* [程序员的宇宙时间线](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261318&idx=1&sn=f7588db0d44a1c1842674d6465ca709e#rd)
* [Android端外推送到底有多烦？](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261350&idx=1&sn=6cea730ef5a144ac243f07019fb43076#rd)
* [Android和iOS开发中的异步处理（四）——异步任务和队列](/posts/blog-series-async-task-4.html)
* [用树型模型管理App数字和红点提示](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261255&idx=1&sn=01ab92edada77803fc4ab7a575453d97&scene=19#wechat_redirect)
