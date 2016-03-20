---
layout: post
category: [ios,android]
title: "iOS和Android开发中的异步处理（一）——概述"
date: 2016-03-20 19:09:00 +0800
published: true
---

本文是我打算完成的一个系列《iOS和Android开发中的异步处理》的开篇。

从2012年开始开发[微爱](http://welove520.com){:target="_blank"}软件的第一个iOS版本开始计算，我和整个团队接触iOS和Android开发已经差不多有4年时间了。现在回过头来总结，iOS和Android开发与其它领域的开发相比，有什么独特的特征呢？一个合格的iOS或Android开发人员，应该具备哪些技能呢？

<!--more-->

如果仔细分辨，iOS和Android客户端的开发工作仍然可以分为“前端”和“后端”两大部分（就如同服务器的开发可以分为“前端”和“后端”一样）。

所谓“前端”工作，就是与UI界面更相关的部分，比如组装页面、实现交互、播放动画、开发自定义控件等等。显然，为了能游刃有余地完成这部分工作，开发人员需要深入了解跟系统有关的“前端”技术，主要包含三大部分：

* 渲染绘制（解决显示内容的问题）
* layout（解决显示大小和位置的问题）
* 事件处理（解决交互的问题）

而“后端”工作，则是隐藏在UI界面背后的东西。比如，操纵和组织数据、缓存机制、发送队列、网络编程、推送和监听，等等。这部分工作，归根结底，是在处理“逻辑”层面的问题，它们并不是iOS或Android系统所特有的东西。然而，有一大类问题，在“后端”编程中占据了极大的比重，这就是如何对“异步任务”进行“异步处理”。

尤其值得指出的是，大部分客户端开发人员，他们所经历的培训、学习经历和开发经历，似乎都更偏重“前端”部分，而在“后端”编程的部分存在一定的空白。因此，本文会尝试把与“后端”编程紧密相关的“异步处理”问题进行总结概括。

本文是系列文章《iOS和Android开发中的异步处理》的第一篇，表面上看起来话题不算太大，却至关重要。当然，如果我打算强调它在客户端编程中的重要性，我也可以说：纵观整个客户端编程的过程，无非就是在对各种“异步任务”进行“异步处理”而已——至少，对于与系统特性无关的那部分来说，我这么讲是没有什么大的问题的。

那么，这里的“异步处理”，到底指的是什么呢？

我们在编程当中，经常需要执行一些异步任务。这些任务在启动后，调用者不用等待任务执行完毕即可接着去做其它事情，而任务什么时候执行完是不确定的，不可预期的。本文要讨论的就是​在处理这些异步任务过程中所可能涉及到的方方面面。

为了让所要讨论的内容更清楚，先列一个提纲如下：

* （一）概述——​介绍常见的异步任务，以及为什么这个话题如此重要。

* （二）​异步任务的回调——讨论跟回调有关的一些话题，比如线程模型，接口设计，透传参数，监听问题等

* （三）执行多个异步任务​

* （四）异步任务和队列

* （五）异步任务和start ID​——讨论如何对异步任务进行versioning的问题，以及它的必要性

* （六）异步任务的取消和暂停——cancel掉正在执行的异步任务，实际上非常困难

* （七）关于封屏与不封屏

* （八）Android Service实例分析——Android Service提供了一个执行异步任务的严密框架 （后面也许会再多提供一些其它的实例分析，加入到这个系列中来）

显然，本篇blog要讨论的是提纲的第（一）部分。

下面，我们先从一个具体的小例子开始：Android中的Service Binding。

{% highlight java linenos %}
public class MyActivity extends Activity {
    private ServiceConnection serviceConnection = new ServiceConnection() {
        @Override
        ​public void onServiceDisconnected(ComponentName name) {
            //解除Activity与Service的引用和监听关系
        }

        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            //建立Activity与Service的引用和监听关系
        }​​
    }

    @Override
    public void onResume() {
        super.onResume();

        Intent intent = new Intent(this, SomeService.class);
        bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);
    }

    @Override
    public void onPause() {
        super.onPause();

        //解除Activity与Service的引用和监听关系
        unbindService(serviceConnection);
    }
}
{% endhighlight %}

上面的例子展示了Activity和Service之间进行交互的一个典型用法。Activity在onResume的时候与Service绑定，在onPause的时候与Service解除绑定。在绑定成功后，onServiceConnected被调用，这时Activity拿到传进来的IBinder的实例（service参数），便可以通过方法调用的方式与Service进行通信（进程内或跨进程）。比如，这时在onServiceConnected中经常要进行的操作可能包括：将IBinder记录下来存入Activity的成员变量，以备后续调用；调用IBinder获取Service的当前状态；设置回调方法，以监听Service后续的事件变化；等等，诸如此类。

这个过程表面看上去无懈可击。但是，如果考虑到bindService是一个“异步”调用，上面的代码就会出现一个逻辑上的漏洞。也就是说，bindService被调用只是相当于启动了绑定过程，它并不会等绑定过程结束才返回。而绑定过程何时结束（也即onServiceConnected被调用），是无法预期的，这取决于绑定过程的快慢。而按照Activity的生命周期，在onResume之后，onPause也随时会被执行。这样看来，在bindService执行完后，可能onServiceConnected会先于onPause执行，也可能onPause会先于onServiceConnected执行。

当然，在一般情况下，onPause不会那么快执行，因此onServiceConnected一般都会赶在onPause之前执行。但是，从“逻辑”的角度，我们却不能完全忽视另外一种可能性。实际上它真的有可能发生，比如刚打开页面就立即退到后台，这种可能性便能以极小的概率发生。一旦发生，最后执行的onServiceConnected会建立起Activity与Service的引用和监听关系。这时应用很可能是在后台，而Activity和IBinder却可能仍互相引用着对方。这可能造成Java对象长时间释放不掉，以及其它一些诡异的问题。

像上面的分析一样，我们只要了解了异步任务bindService所能引发的所有可能情况，那就不难想出类似如下的应对措施。

{% highlight java linenos %}
public class MyActivity extends Activity {
    /**
     * 指示本Activity是否处于running状态：执行过onResume就变为running状态。
     */
    private boolean running;

    private ServiceConnection serviceConnection = new ServiceConnection() {
        @Override
        ​public void onServiceDisconnected(ComponentName name) {
            //解除Activity与Service的引用和监听关系
        }

        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            if (running) {
                //建立Activity与Service的引用和监听关系                
            }
        }​​
    }

    @Override
    public void onResume() {
        super.onResume();
        running = true;

        Intent intent = new Intent(this, SomeService.class);
        bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);
    }

    @Override
    public void onPause() {
        super.onPause();
        running = false;

        //解除Activity与Service的引用和监听关系
        unbindService(serviceConnection);

    }
}
{% endhighlight %}

下面我们再来看一个iOS的小例子。





尤其是两个生命周期不等的情况。

