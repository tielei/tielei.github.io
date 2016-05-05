---
layout: post
category: "android"
title: "用一张图解释RxJava中的线程控制"
date: 2016-04-24 12:10:00 +0800
published: true
---

上周五和团队一起讨论了[RxJava](https://github.com/ReactiveX/RxJava){:target="_blank"}的用法和实现机制。在讨论中，@坚坚老师 问了一个有趣的问题：如果调用链中包含多个subscribeOn和observeOn，会是什么情况？

<!--more-->

这实际上是一个至关重要的问题，因为在任何情况下，我们都应该弄清楚我们写的每一行代码到底是运行在哪个线程上。这个问题绝对不能含糊。

假设有下面这段伪代码：

{% highlight java linenos %}
Observable.create(...)
	.lift1(...)
	.subscribeOn(scheduler1)
	.lift2(...)
	.observeOn(scheduler2)
	.lift3(...)
	.subscribeOn(scheduler3)
	.lift4(...)
	.observeOn(scheduler4)
	.doOnSubscribe(...)
	.subscribeOn(scheduler5)
	.observeOn(scheduler6)
	.subscribe(...);
{% endhighlight %}

那么在这段代码中：

* lift1, lift2, lift3, lift4指定的代码分别在哪个线程执行？
* doOnSubscribe指定的代码在哪个线程执行？
* 产生事件的代码（create指定的代码）在哪个线程执行？
* 消费事件的代码（subscribe指定的代码）在哪个线程执行？

相信很多同学会觉得这段代码多少有些令人晕眩，在实际中是不太可能出现的。确实，实际中的代码大都没有这么复杂，但弄清它有助于我们理解整个RxJava的实现流程。

[<img src="/assets/photos_rxjava/rxjava_flow.png" style="width:500px" alt="RxJava流程图" />](/assets/photos_rxjava/rxjava_flow.png)

上面这幅图表达了一个典型的RxJava调用链中控制流的传递过程。它可以分成两个阶段：

1. 驱动阶段。整个异步事件流的触发由subscribe开始。它发起了一个反向驱动过程，跨过每一个中间的Observable和OnSubscribe，到达第一个Observable（产生事件的源头）。对应图中的(1)和(2)。
2. 事件发射阶段。第一个Observable开始产生事件，然后事件流就开始正向传递，经过每一个中间的Observable，最终到达Subscriber（事件的消费者）。对应图中的(3)。

我们分析一下这整个流程，其中有几点需要特别说明一下：

* 图中的(1)对应的是调用前一级Observable的OnSubscribe.call，是个无返回值的方法，因此可以切换线程，从而变为异步的。所以用虚线表示。
* 图中的(2)对应的是lift操作指定的Operator.call，是个有返回值的方法（输入一个Subscriber，返回一个新的Subscriber）。因此，它只能同步调用，不能切换线程。所以用实线表示。
* 图中的(3)对应的是调用后一级Observable对应的Subscriber（onNext, onCompleted, onError），也都是无返回值的方法，因此可以切换线程，从而变为异步的。所以也用虚线表示。
* observeOn是基于lift实现的，且切换线程的动作发生在Subscriber（onNext, onCompleted, onError），因此它影响(3)流程上在它后面的所有lift变换。
* subscribeOn不是基于lift实现的，它直接在调用前一级Observable的OnSubscribe时切换线程。因此，它影响(1)流程上在它前面的所有OnSubscribe调用，直到产生事件的源头；然后，(3)流程上的所有lift操作也会在新切换到的线程上，直到碰到一个observeOn操作。
* doOnSubscribe稍微特殊一点。它虽然是基于lift实现的，但它所指定的代码发生在Operator.call中，不像其它的lift操作（比如filter, map, reduce等），它们指定的代码发生在Subscriber。因此它的执行线程受它后面的subscribeOn的影响。

根据上面的分析，就很容易得到下面的结论了：

* 产生事件的代码（create指定的代码）和doOnSubscribe指定的代码，在它们后面最近的一个subscribeOn指定的Scheduler上执行；如果它们后面没有subscribeOn了，那么它们就在调用subscribe方法的那一个线程上执行。
* 普通的lift操作（比如filter, map, reduce等）和消费事件的代码（subscribe指定的代码），在它们前面最近的一个observeOn指定的Scheduler上执行；如果它们前面没有observeOn了，那么它们就在整个调用链的第一个subscribeOn指定的Scheduler上执行；如果没找到subscribeOn调用，那么它们就在调用subscribe方法的那一个线程上执行。

把这些结论应用在本文开始的那段代码上，我们很快能得到：

* 产生事件的代码（create指定的代码）在scheduler1上执行；
* lift1和lift2指定的代码在scheduler1上执行；
* lift3和lift4指定的代码在scheduler2上执行；
* doOnSubscribe指定的代码在scheduler5上执行；
* 消费事件的代码（subscribe指定的代码）在scheduler6上执行。
