---
layout: post
category: [ios,android]
title: "iOS和Android开发中的异步处理（一）——概述"
date: 2016-03-20 19:09:00 +0800
published: true
---

本文是我打算完成的一个系列《iOS和Android开发中的异步处理》的开篇。

从2012年开始开发[微爱](http://welove520.com){:target="_blank"}软件的第一个iOS版本计算，我和整个团队接触iOS和Android开发已经差不多有4年时间了。现在回过头来总结，iOS和Android开发与其它领域的开发相比，有什么独特的特征呢？一个合格的iOS或Android开发人员，应该具备哪些技能呢？

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

现在假设我们要维护一个客户端到服务器的TCP长连接。这个连接在网络状态发生变化时能够自动进行重连。首先，我们需要一个能监听网络状态变化的类，这个类叫做Reachability，它的代码如下：

{% highlight objc linenos %}
//
//  Reachability.h
//
#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

extern NSString *const networkStatusNotificationInfoKey;
extern NSString *const kReachabilityChangedNotification;

typedef NS_ENUM(uint32_t, NetworkStatus) {
    NotReachable = 0,
    ReachableViaWiFi = 1,
    ReachableViaWWAN = 2
};

@interface Reachability : NSObject {
@private
    SCNetworkReachabilityRef reachabilityRef;
}

/**
 * 开始网络状态监听
 */
- (BOOL)startNetworkMonitoring;
/**
 * 结束网络状态监听
 */
- (BOOL)stopNetworkMonitoring;
/**
 * 同步获取当前网络状态
 */
- (NetworkStatus) currentNetworkStatus;
@end

//
//  Reachability.m
//
#import "Reachability.h"
#import <sys/socket.h>
#import <netinet/in.h>

NSString *const networkStatusNotificationInfoKey = @"networkStatus";
NSString *const kReachabilityChangedNotification = @"NetworkReachabilityChangedNotification";

@implementation Reachability

- (instancetype)init {
    self = [super init];
    if (self) {
        struct sockaddr_in zeroAddress;
        memset(&zeroAddress, 0, sizeof(zeroAddress));
        zeroAddress.sin_len = sizeof(zeroAddress);
        zeroAddress.sin_family = AF_INET;
        
        reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);

    }
    
    return self;
}

- (void)dealloc {
    if (reachabilityRef) {
        CFRelease(reachabilityRef);
    }
}

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info) {
    
    Reachability *reachability = (__bridge Reachability *) info;
    
    @autoreleasepool {
        NetworkStatus networkStatus = [reachability currentNetworkStatus];
        [[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityChangedNotification object:reachability userInfo:@{networkStatusNotificationInfoKey : @(networkStatus)}];
    }
}

- (BOOL)startNetworkMonitoring {
    SCNetworkReachabilityContext context = {0, (__bridge void * _Nullable)(self), NULL, NULL, NULL};
    
    if(SCNetworkReachabilitySetCallback(reachabilityRef, ReachabilityCallback, &context)) {
        if(SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
            return YES;
        }
        
    }
    
    return NO;
}

- (BOOL)stopNetworkMonitoring {
    return SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
}

- (NetworkStatus) currentNetworkStatus {
    //此处代码忽略...
}
{% endhighlight %}

上述代码封装了Reachability类的接口。当调用者想开始网络状态监听时，就调用startNetworkMonitoring；监听完毕就调用stopNetworkMonitoring。我们设想中的长连接正好需要创建和调用Reachability对象来处理网络状态监听。它的代码的相关部分可能会如下所示（类名ServerConnection；头文件代码忽略）：

{% highlight objc linenos %}
//
//  ServerConnection.m
//
#import "ServerConnection.h"
#import "Reachability.h"

@interface ServerConnection() {
    //用户执行socket操作的GCD queue
    dispatch_queue_t socketQueue;
    Reachability *reachability;
}
@end

@implementation ServerConnection

- (instancetype)init {
    self = [super init];
    if (self) {
        socketQueue = dispatch_queue_create("SocketQueue", NULL);
        
        reachability = [[Reachability alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStateChanged:) name:kReachabilityChangedNotification object:reachability];
        [reachability startNetworkMonitoring];
    }
    return self;
}

- (void)dealloc {
    [reachability stopNetworkMonitoring];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)networkStateChanged:(NSNotification *)notification {
    NetworkStatus networkStatus = [notification.userInfo[networkStatusNotificationInfoKey] unsignedIntValue];
    if (networkStatus != NotReachable) {
        //网络变化，重连
        dispatch_async(socketQueue, ^{
            [self reconnect];
        });
    }
}

- (void)reconnect {
    //此处代码忽略...
}
@end
{% endhighlight %}

长连接ServerConnection在初始化时创建了Reachability实例，并启动监听（调用startNetworkMonitoring），通过系统广播设置监听方法（networkStateChanged:）；当长连接ServerConnection销毁的时候（dealloc）停止监听（调用stopNetworkMonitoring）。

当网络状态发生变化时，networkStateChanged:会被调用，并且当前网络状态会被传入。如果发现网络变得可用了（非NotReachable状态），那么就异步执行重连操作。

这个过程看上去合情合理。但是这里面却隐藏了一个致命的问题。

在进行重连操作时，我们使用dispatch_async启动了一个异步任务。这个异步任务在启动后什么时候执行完，是不可预期的，这取决于reconnect操作执行的快慢。假设reconnect执行比较慢（对于涉及网络的操作，这是很有可能的），那么可能会发生这样一种情况：reconnect还在运行中，但ServerConnection即将销毁。也就是说，整个系统中所有其它对象对于ServerConnection的引用都已经释放了，只留下了dispatch_async调度时block对于self的一个引用。

这会导致什么后果呢？

这会导致：当reconnect执行完的时候，ServerConnection真正被释放，它的dealloc方法不在主线程执行！而是在socketQueue上执行。

而这接下来又会怎么样呢？这取决于Reachability的实现。

我们来重新分析一下Reachability的代码来得到这件事发生的最终影响。这个情况发生时，Reachability的stopNetworkMonitoring在非主线程被调用了。而当初startNetworkMonitoring被调用时却是在主线程的。现在我们看到了，startNetworkMonitoring和stopNetworkMonitoring如果前后不在同一个线程上执行，那么在它们的实现中的CFRunLoopGetCurrent()就不是指的同一个Run Loop。这已经在逻辑上发生“错误”了。在这个“错误”发生之后，stopNetworkMonitoring中的SCNetworkReachabilityUnscheduleFromRunLoop就没有能够把Reachability实例从原来在主线程上调度的那个Run Loop上卸下来。也就是说，此后如果网络状态再次发生变化，那么ReachabilityCallback仍然会执行，但这时原来的Reachability实例已经被销毁过了（由ServerConnection的销毁而销毁）。按上述代码的目前的实现，这时ReachabilityCallback中的info参数指向了一个已经被释放的Reachability对象，那么接下来发生崩溃也就不足为奇了。

有人可能会说，dispatch_async执行的block中不应该直接引用self，而应该使用weak strong dance. 也就是把dispatch_async那段代码改成下面的形式：

{% highlight objc linenos %}
        __weak ServerConnection *wself = self;
        dispatch_async(socketQueue, ^{
            __strong ServerConnection *sself = wself;
            [sself reconnect];
        });
{% endhighlight %}

这样改有没有效果呢？根据我们上面的分析，显然没有。ServerConnection的dealloc仍然在非主线程上执行，上面的问题也依然存在。weak strong dance被设计用来解决循环引用的问题，但不能解决我们这里碰到的异步任务延迟的问题。

实际上，即使把它改成下面的形式，仍然没有效果。

{% highlight objc linenos %}
        __weak ServerConnection *wself = self;
        dispatch_async(socketQueue, ^{
            [wself reconnect];
        });
{% endhighlight %}

即使拿weak引用（wself）来调用reconnect方法，它一旦执行，也会造成ServerConnection的引用计数增加。结果仍然是dealloc在非主线程上执行。

那既然dealloc在非主线程上执行会造成问题，那我们强制把dealloc里面的代码调用到主线程执行好了，如下：

{% highlight objc linenos %}
- (void)dealloc {
    dispatch_async(dispatch_get_main_queue(), ^{
        [reachability stopNetworkMonitoring];
    });
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
{% endhighlight %}

显然，在dealloc再调用dispatch_async的这种方法也是行不通的。因为在dealloc执行过之后，ServerConnection实例已经被销毁了，那么当block执行时，reachability就依赖了一个已经被销毁的ServerConnection实例。结果还是崩溃。

那不用dispatch_async好了，改用dispatch_sync好了。仔细修改后的代码如下：

{% highlight objc linenos %}
- (void)dealloc {
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [reachability stopNetworkMonitoring];
        });
    }
    else {
        [reachability stopNetworkMonitoring];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
{% endhighlight %}

经过“前后左右”打补丁，我们现在总算得到了一段可以基本能正常执行的代码了。然而，在dealloc里执行dispatch_sync这种可能耗时的“同步”操作，总不免令人胆战心惊。

那到底怎样做更好呢？

个人认为：**并不是所有销毁工作都适合写在dealloc里**。

比如上面的ServerConnection的例子，业务逻辑自己肯定知道应该在哪里

尤其是两个生命周期不等的情况。

