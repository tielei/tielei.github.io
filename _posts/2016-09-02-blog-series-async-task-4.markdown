---
layout: post
category: [ios,android]
title: "Android和iOS开发中的异步处理（四）——异步任务和队列"
date: 2016-09-02 01:00:00 +0800
published: true
---

本文是系列文章《[Android和iOS开发中的异步处理](/posts/blog-series-async-task-1.html)》的第四篇。在本篇文章中，我们主要讨论在客户端编程中经常使用的队列结构，它的异步编程方式以及相关的接口设计问题。

<!--more-->

前几天，有位同事跑过来一起讨论一个技术问题。情况是这样的，他最近在开发一款手游，用户在客户端上的每次操作都需要向服务器同步数据。本来按照传统的网络请求处理方式，用户发起操作后，需要等待操作完成，这时界面要显示一个请求等待的过程（比如转菊花）。当请求完成了，客户端显示层才更新，用户也才能发起下一个操作。但是，这个游戏要求用户能在短时间内连续做很多操作。如果每个操作都要经历一个请求等待的过程，无疑体验是很糟糕的。

其实呢，这里就需要一个操作任务队列。用户不用等待一个操作完成，而是只要把操作放入队列里，就可以继续进行下一步操作了。只是，当队列中有操作出错时，需要进入一个统一的错误处理流程。当然，服务器也要配合进行一些处理，比如要更加慎重地对待操作去重问题。

本文要讨论的就是跟队列有关的那些问题。

注：本系列文章中出现的代码已经整理到GitHub上（持续更新），代码库地址为：

* <https://github.com/tielei/AsyncProgrammingDemos>{:target="_blank"}

其中，当前这篇文章中出现的Java代码，位于com.zhangtielei.demos.async.programming.queueing这个package中。

### 概述

在客户端编程中，使用队列的场景其实是很多的。这里我们列举其中几个。

* 发送聊天消息。现在一般的聊天软件都允许用户连续输入多条聊天消息，也就是说，用户不用等待前一条消息发送成功了，再键入第二条消息。系统会保证用户的消息有序，而且由于网络状况不好而发送失败的消息会经历若干次重试，从而保证消息尽力送达。这其实背后有一个消息发送队列，它对消息进行排队处理，并且在错误发生时进行有限的重试。
* 一次上传多张照片。如果用户能够一次性选中多张照片进行上传操作，这个上传过程时间会比较长，一般需要一个或多个队列。队列的重试功能还能够允许文件的断点续传（当然这要求服务端要有相应的支持）。
* 将关键的高频操作异步化，提升体验。比如前面提到的那个游戏连续操作的例子，再比如微信朋友圈发照片或者评论别人，都不需要等待本次网络请求结束，就可以进行后面的操作。这背后也隐藏着一个队列机制。

为了讨论方便，我们把这种对一系列操作进行排队，并具备一定失败重试能力的队列称为“任务队列”。

下面本文分三个章节来讨论异步任务和任务队列的相关话题。

* 介绍传统的线程安全队列TSQ（Thread-Safe Queue）。
* 适合客户端编程环境的无锁队列。这一部分遵循异步任务的经典回调方式（Callback）来设计接口。关于异步任务的回调相关的详细讨论，请参见这个系列的[第二篇](/posts/blog-series-async-task-2.html)。
* 基于RxJava响应式编程的思想实现的队列。在这一部分，我们会看到RxJava对于异步任务的接口设计会产生怎样的影响。

### Thread-Safe Queue

在多线程的环境下，提到队列就不能不提TSQ。它是一个很经典的工具，在不同的线程之间提供了一条有序传输数据的通道。它的结构图如下所示。

[<img src="/assets/photos_async_task/tsq_showing.png" style="width:600px" alt="TSQ结构图" />](/assets/photos_async_task/tsq_showing.png)

消费者和生产者分属不同的线程，这样消费者和生产者才能解耦，生产不至于被消费所阻塞。如果把TSQ用于任务队列，那么生产相当于启动（调度）任务，消费相当于任务的真正执行。

消费者线程运行在一个循环当中，它不停地尝试从队列里取数据，如果没有数据，则阻塞在队列头上。这种阻塞操作需要依赖操作系统的一些原语。

利用队列进行解耦，是一个很重要的思想。往大的方面说，TSQ的思想推广到进程之间，就相当于在分布式系统里经常使用的Message Queue。它对于异构服务之间的解耦，以及屏蔽不同服务之间的性能差异，可以起到关键作用。

而TSQ在客户端编程中比较少见，原因包括：

* 它需要额外启动一个单独的线程作为消费者。
* 更适合客户端环境的“**主线程->异步线程->主线程**”的编程模式（参见这个系列的[第一篇](/posts/blog-series-async-task-1.html)中Run Loop那一章节的相关描述），使得生产者和消费者可以都运行在主线程中，这样就不需要一个Thread-Safe的队列，而是只需要一个普通队列就行了（下一章要讲到）。

我们在这里提到TSQ，主要是因为它比较经典，也能够和其它方式做一个对比。我们在这里就不给出它的源码演示了，想了解细节的同学可以参见GitHub。GitHub上的演示代码使用了JDK中现成的TSQ的实现：LinkedBlockingQueue。

### 基于Callback的任务队列

[<img src="/assets/photos_async_task/callback_queue_showing.png" style="width:600px" alt="基于Callback的队列的结构图" />](/assets/photos_async_task/callback_queue_showing.png)


如上图所示，生产者和消费者都运行在一个线程，即主线程。按照这种思路来实现任务队列，我们需要执行的任务本身必须是异步的，否则整个队列的任务就没法异步化。

我们定义要执行的异步任务的接口如下：

```java
public interface Task {
    /**
     * 唯一标识当前任务的ID
     * @return
     */
    String getTaskId();

    /**
     * 由于任务是异步任务, 那么start方法被调用只是启动任务;
     * 任务完成后会回调TaskListener.
     *
     * 注: start方法需在主线程上执行.
     */
    void start();

    /**
     * 设置回调监听.
     * @param listener
     */
    void setListener(TaskListener listener);

    /**
     * 异步任务回调接口.
     */
    interface TaskListener {
        /**
         * 当前任务完成的回调.
         * @param task
         */
        void taskComplete(Task task);
        /**
         * 当前任务执行失败的回调.
         * @param task
         * @param cause 失败原因
         */
        void taskFailed(Task task, Throwable cause);
    }
}
```

由于`Task`是一个异步任务，所以我们为它定义了一个回调接口`TaskListener`。

`getTaskId`是为了得到一个能唯一标识当前任务的ID，便于对不同任务进行精确区分。

另外，为了更通用的表达失败原因，我们这里选用一个Throwable对象来表达（注：在实际编程中这未必是一个值得效仿的做法，具体情况请具体分析）。

有人可能会说：这里把`Task`接口定义成异步的，那如果想执行一个同步的任务该怎么办？这其实很好办。把同步任务改造成异步任务是很简单的，有很多种方法（反过来却很难）。

任务队列的接口，定义如下：

```java
public interface TaskQueue {
    /**
     * 向队列中添加一个任务.
     *
     * @param task
     */
    void addTask(Task task);

    /**
     * 设置监听器.
     * @param listener
     */
    void setListener(TaskQueueListener listener);

    /**
     * 销毁队列.
     * 注: 队列在最后不用的时候, 应该主动销毁它.
     */
    void destroy();

    /**
     * 任务队列对外监听接口.
     */
    interface TaskQueueListener {
        /**
         * 任务完成的回调.
         * @param task
         */
        void taskComplete(Task task);
        /**
         * 任务最终失败的回调.
         * @param task
         * @param cause 失败原因
         */
        void taskFailed(Task task, Throwable cause);
    }
}
```

任务队列`TaskQueue`本身的操作也是异步的，`addTask`只是将任务放入队列，至于它什么时候完成（或失败），调用者需要监听`TaskQueueListener`接口。

需要注意的一点是，`TaskQueueListener`的`taskFailed`，与前面`TaskListener`的`taskFailed`不同，它表示任务在经过一定次数的失败后，最终放弃重试从而最终失败。而后者只表示那个任务一次执行失败。

我们重点讨论`TaskQueue`的实现，而`Task`的实现我们这里不关心，我们只关心它的接口。`TaskQueue`的实现代码如下：

```java
public class CallbackBasedTaskQueue implements TaskQueue, Task.TaskListener {
    private static final String TAG = "TaskQueue";

    /**
     * Task排队的队列. 不需要thread-safe
     */
    private Queue<Task> taskQueue = new LinkedList<Task>();

    private TaskQueueListener listener;
    private boolean stopped;

    /**
     * 一个任务最多重试次数.
     * 重试次数超过MAX_RETRIES, 任务则最终失败.
     */
    private static final int MAX_RETRIES = 3;
    /**
     * 当前任务的执行次数记录(当尝试超过MAX_RETRIES时就最终失败)
     */
    private int runCount;

    @Override
    public void addTask(Task task) {
        //新任务加入队列
        taskQueue.offer(task);
        task.setListener(this);

        if (taskQueue.size() == 1 && !stopped) {
            //当前是第一个排队任务, 立即执行它
            launchNextTask();
        }
    }

    @Override
    public void setListener(TaskQueueListener listener) {
        this.listener = listener;
    }

    @Override
    public void destroy() {
        stopped = true;
    }

    private void launchNextTask() {
        //取当前队列头的任务, 但不出队列
        Task task = taskQueue.peek();
        if (task == null) {
            //impossible case
            Log.e(TAG, "impossible: NO task in queue, unexpected!");
            return;
        }

        Log.d(TAG, "start task (" + task.getTaskId() + ")");
        task.start();
        runCount = 1;
    }

    @Override
    public void taskComplete(Task task) {
        Log.d(TAG, "task (" + task.getTaskId() + ") complete");
        finishTask(task, null);
    }

    @Override
    public void taskFailed(Task task, Throwable error) {
        if (runCount < MAX_RETRIES && !stopped) {
            //可以继续尝试
            Log.d(TAG, "task (" + task.getTaskId() + ") failed, try again. runCount: " + runCount);
            task.start();
            runCount++;
        }
        else {
            //最终失败
            Log.d(TAG, "task (" + task.getTaskId() + ") failed, final failed! runCount: " + runCount);
            finishTask(task, error);
        }
    }

    /**
     * 一个任务最终结束(成功或最终失败)后的处理
     * @param task
     * @param error
     */
    private void finishTask(Task task, Throwable error) {
        //回调
        if (listener != null && !stopped) {
            try {
                if (error == null) {
                    listener.taskComplete(task);
                }
                else {
                    listener.taskFailed(task, error);
                }
            }
            catch (Throwable e) {
                Log.e(TAG, "", e);
            }
        }
        task.setListener(null);

        //出队列
        taskQueue.poll();

        //启动队列下一个任务
        if (taskQueue.size() > 0 && !stopped) {
            launchNextTask();
        }
    }

}
```

在这个实现中，我们需要注意的几点是：

* 进出队列的所有操作（`offer`, `peek`, `take`）都运行在主线程，所以队列数据结构不再需要线程安全。我们选择了LinkedList的实现。
* 任务的启动执行，依赖两个机会：
  * 任务进队列`addTask`的时候，如果原来队列为空（当前任务是第一个任务），那么启动它；
  * 一个任务执行完成（成功了，或者最终失败了）后，如果队列里有排队的其它任务，那么取下一个任务启动执行。
* 任务一次执行失败，并不算失败，还要经过若干次重试。如果重试次数超过`MAX_RETRIES`，才算最终失败。`runCount`记录了当前任务的累计执行次数。

`CallbackBasedTaskQueue`的代码揭示了任务队列的基本实现模式。

任务队列对于失败任务的重试策略，大大提高了最终成功的概率。在GitHub上的演示程序中，我把`Task`的失败概率设置得很高（高达80%），在重试3次的配置下，当任务执行的时候仍然有比较大的概率能最终执行成功。

### 基于RxJava的任务队列

关于RxJava到底有什么用？网上有很多讨论。

有人说，RxJava就是为了异步。这个当然没错，但说得不具体。

也有人说，RxJava的真正好处就是它提供的各种lift变换。还有人说，RxJava最大的用处是它的Schedulers机制，能够方便地切换线程。其实这些都不是革命性的关键因素。

那关键的是什么呢？我个人认为，是它**对于回调接口设计产生的根本性的影响：它消除了为每个异步接口单独定义回调接口的必要性**。

这里马上就有一个例子。我们使用RxJava对`TaskQueue`接口重新进行改写。


```java
public interface TaskQueue {
    /**
     * 向队列中添加一个任务.
     *
     * @param task
     * @param <R> 异步任务执行完要返回的数据类型.
     * @return 一个Observable. 调用者通过这个Observable获取异步任务执行结果.
     */
    <R> Observable<R> addTask(Task<R> task);

    /**
     * 销毁队列.
     * 注: 队列在最后不用的时候, 应该主动销毁它.
     */
    void destroy();
}
```
我们仔细看一看这个修改后的`TaskQueue`接口定义。

* 原来的回调接口`TaskQueueListener`没有了。
* 异步接口`addTask`原来没有返回值，现在返回了一个Observable。调用者拿到这个Observable，然后去订阅它（subscribe），就能获得任务执行结果（成功或失败）。**这里的改动很关键**。本来`addTask`什么也不返回，要想获得结果必须监听一个回调接口，这是典型的异步任务的运作方式。但这里返回一个Observable之后，让它感觉上非常类似一个同步接口了。再说得抽象一点，这个Observable是我们站在当下对于未来的一个指代，本来还没有运行的、发生在未来的虚无缥缈的任务，这时候有一个实实在在的东西被我们抓在手里了。而且我们还能对它在当下就进行很多操作，并可以和其它Observable结合。这是这一思想真正的强大之处。

相应地，`Task`接口本来也是一个异步接口，自然也可以用这种方式进行修改：

```java
/**
 * 异步任务接口定义.
 *
 * 不再使用TaskListener传递回调, 而是使用Observable.
 *
 * @param <R> 异步任务执行完要返回的数据类型.
 */
public interface Task <R> {
    /**
     * 唯一标识当前任务的ID
     * @return
     */
    String getTaskId();

    /**
     *
     * 启动任务.
     *
     * 注: start方法需在主线程上执行.
     *
     * @return 一个Observable. 调用者通过这个Observable获取异步任务执行结果.
     */
    Observable<R> start();
}
```

这里把改为RxJava的接口讨论清楚了，具体的队列实现反而不重要了。具体实现代码就不在这里讨论了，想了解详情的同学还是参见GitHub。注意GitHub的实现中用到了一个小技巧：把一个异步的任务封装成Observable，我们可以使用AsyncOnSubscribe。

### 总结

#### 再说一下TSQ

我们在文章开头讲述了TSQ，并指出它在客户端编程中很少被使用。但并不是说在客户端环境中TSQ就没有存在的意义。

实际上，客户端的Run Loop（即Android的Looper）本身就是一个TSQ，要不然它也没法在不同线程之间安全地传递消息和调度任务。正是因为客户端有了一个Run Loop，我们才有可能使用无锁的方式来实现任务队列。所以说，我们在客户端的编程，总是与TSQ有着千丝万缕的联系。

顺便说一句，Android中的android.os.Looper，最终会依赖Linux内核中大名鼎鼎的[epoll](http://www.devshed.com/c/a/BrainDump/Linux-Files-and-the-Event-Poll-Interface/){:target="_blank"}事件机制。

#### 本文的任务队列设计中所忽略的

本文的核心是要讲解任务队列的异步编程方式，所以忽略了一些设计细节。如果你要实现一个生产环境能使用的任务队列，可能还需要考虑以下这些点：

* 本文只设计了任务的成功和失败回调，没有执行进度回调。
* 本文没有涉及到任务取消和暂停的问题（我们下一篇文章会涉及这个话题）。
* 任务队列的一些细节参数应该是可以由使用者设置的，比如最大重试次数。
* 长生命周期的队列和短生命周期的页面之间的交互，本文没有考虑。在GitHub实现的演示代码中，为了简单起见，演示页面关闭后，任务队列也销毁了。但实际中不应该是这样的。关于“长短生命周期的交互”，我后来发现也是一个比较重要的问题，也许后面我们有机会再讨论。
* 在Android中，类似任务队列这种可能长时间后台运行的组件，一般外层会使用Service进行封装。
* 任务队列对于失败重试的处理，要求服务器慎重地对待去重问题。
* 监听到任务队列失败发生之后，错误处理变得复杂。

#### RxJava的优缺点

本文最后运用了RxJava对任务队列进行了重写。我们确实将接口简化了许多，省去了回调接口的设计，也让调用者能用统一的方式来处理异步任务。

但是，我们也需要注意到RxJava带来的一些问题：

* RxJava是个比较重的框架，它非常抽象，难以理解。它对于接口的调用者简单，而对于接口的实现者来说，是个难题。
* Observable依赖subscribe去驱动它的上游开始运行。也就是说，你如果只是添加一个任务，但不去观察它，它就不会执行！如果你只是想运行一个任务，但并不关心结果，那么，这办不到。举个不恰当的例子，这有点像量子力学，观察对结果造成影响......
* 受前一点影响，在本文给出的GitHub代码的实现中，第一个任务的真正启动运行，并不是在`addTask`中，而是有所延迟，延迟到调用者的subscribe开始执行后。而且其执行线程环境有可能受到调用者对于Schedulers的设置的影响（比如通过subscribeOn），有不在主线程执行的风险。
* RxJava在调试时会出现奇怪的、让人难以理解的调用栈。

考虑到RxJava带来的这些问题，如果我要实现一个完整功能的任务队列或者其它复杂的异步任务，特别是要把它开源出来的的时候，我有可能不会让它对RxJava产生绝对的依赖。而是有可能像[Retrofit](https://github.com/square/retrofit){:target="_blank"}那样，同时支持自己的轻量的异步机制和RxJava。

---

在本文结束之前，我再提出一个有趣的开放性问题。本文GitHub上给出的代码大量使用了匿名类（相当于Java 8的lambda表达式），这会导致对象之间的引用关系变得复杂。那么，对于这些对象的引用关系的分析，会是一个很有趣的话题。比如，这些引用关系开始是如何随着程序执行建立起来的，最终销毁的时候又是如何解除的？有没有内存泄露呢？

在下一篇，我们将讨论有关异步任务更复杂的一个问题：异步任务的取消。

（完）

**其它精选文章**：

* [技术的正宗与野路子](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261357&idx=1&sn=ebb11a1623e00ca8e6ad55c9ad6b2547#rd)
* [程序员的那些反模式](/posts/blog-programmer-anti-pattern.html)
* [编程世界的熵增原理](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261372&idx=1&sn=89c5b0fa1e9e339ee220d0c30001d01a#rd)
* [程序员的宇宙时间线](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261318&idx=1&sn=f7588db0d44a1c1842674d6465ca709e#rd)
* [Android端外推送到底有多烦？](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261350&idx=1&sn=6cea730ef5a144ac243f07019fb43076#rd)
* [Android和iOS开发中的异步处理（一）——开篇](/posts/blog-series-async-task-1.html)
* [用树型模型管理App数字和红点提示](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261255&idx=1&sn=01ab92edada77803fc4ab7a575453d97&scene=19#wechat_redirect)
* [一张图读懂RxJava中的线程控制](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=509777575&idx=1&sn=9ace4885f32a1f274e4be8d839700486&scene=19#wechat_redirect)
* [宇宙尽头的描述符（下）](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261342&idx=1&sn=0adc539ce9b4632aac96a447b7431532#rd)
* [Redis内部数据结构详解(5)——quicklist](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261335&idx=1&sn=053d72a348be2e78040f3847f4092d92&scene=19#wechat_redirect)
* [Redis内部数据结构详解(4)——ziplist](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261265&idx=1&sn=e105c4b86a5640c5fc8212cd824f750b#rd)