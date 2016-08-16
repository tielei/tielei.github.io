---
layout: post
category: [ios,android]
title: "Android和iOS开发中的异步处理（一）——概述"
date: 2016-03-20 19:09:00 +0800
published: true
---

本文是我打算完成的一个系列《Android和iOS开发中的异步处理》的开篇。

从2012年开始开发[微爱](http://welove520.com){:target="_blank"}App的第一个iOS版本计算，我和整个团队接触iOS和Android开发已经差不多有4年时间了。现在回过头来总结，iOS和Android开发与其它领域的开发相比，有什么独特的特征呢？一个合格的iOS或Android开发人员，应该具备哪些技能呢？

<!--more-->

如果仔细分辨，iOS和Android客户端的开发工作仍然可以分为“前端”和“后端”两大部分（就如同服务器的开发可以分为“前端”和“后端”一样）。

所谓“前端”工作，就是与UI界面更相关的部分，比如组装页面、实现交互、播放动画、开发自定义控件等等。显然，为了能游刃有余地完成这部分工作，开发人员需要深入了解跟系统有关的“前端”技术，主要包含三大部分：

* 渲染绘制（解决显示内容的问题）
* layout（解决显示大小和位置的问题）
* 事件处理（解决交互的问题）

而“后端”工作，则是隐藏在UI界面背后的东西。比如，操纵和组织数据、缓存机制、发送队列、生命周期设计和管理、网络编程、推送和监听，等等。这部分工作，归根结底，是在处理“逻辑”层面的问题，它们并不是iOS或Android系统所特有的东西。然而，有一大类问题，在“后端”编程中占据了极大的比重，这就是如何对“异步任务”进行“异步处理”。

尤其值得指出的是，大部分客户端开发人员，他们所经历的培训、学习经历和开发经历，似乎都更偏重“前端”部分，而在“后端”编程的部分存在一定的空白。因此，本文会尝试把与“后端”编程紧密相关的“异步处理”问题进行总结概括。

本文是系列文章《Android和iOS开发中的异步处理》的第一篇，表面上看起来话题不算太大，却至关重要。当然，如果我打算强调它在客户端编程中的重要性，我也可以说：纵观整个客户端编程的过程，无非就是在对各种“异步任务”进行“异步处理”而已——至少，对于与系统特性无关的那部分来说，我这么讲是没有什么大的问题的。

那么，这里的“异步处理”，到底指的是什么呢？

我们在编程当中，经常需要执行一些异步任务。这些任务在启动后，调用者不用等待任务执行完毕即可接着去做其它事情，而任务什么时候执行完是不确定的，不可预期的。本文要讨论的就是​在处理这些异步任务过程中所可能涉及到的方方面面。

为了让所要讨论的内容更清楚，先列一个提纲如下：

* （一）概述——​介绍常见的异步任务，以及为什么这个话题如此重要。

* （二）​[异步任务的回调](/posts/blog-series-async-task-2.html)——讨论跟回调接口有关的一系列话题，比如错误处理、线程模型、透传参数、回调顺序等。

* （三）[执行多个异步任务](/posts/blog-series-async-task-3.html)​

* （四）异步任务和队列

* （五）异步任务的取消和暂停，以及start ID​——Cancel掉正在执行的异步任务，实际上非常困难。

* （六）关于封屏与不封屏

* （七）Android Service实例分析——Android Service提供了一个执行异步任务的严密框架 （后面也许会再多提供一些其它的实例分析，加入到这个系列中来）。

显然，本篇blog要讨论的是提纲的第（一）部分。

下面，我们先从一个具体的小例子开始：Android中的Service Binding。

```java
public class ServiceBindingDemoActivity extends Activity {
    private ServiceConnection serviceConnection = new ServiceConnection() {
        @Override
        public void onServiceDisconnected(ComponentName name) {
            //解除Activity与Service的引用和监听关系
            ...
        }

        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            //建立Activity与Service的引用和监听关系
            ...
        }
    };

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
        ...

        unbindService(serviceConnection);
    }
}
```

上面的例子展示了Activity和Service之间进行交互的一个典型用法。Activity在onResume的时候与Service绑定，在onPause的时候与Service解除绑定。在绑定成功后，onServiceConnected被调用，这时Activity拿到传进来的IBinder的实例（service参数），便可以通过方法调用的方式与Service进行通信（进程内或跨进程）。比如，这时在onServiceConnected中经常要进行的操作可能包括：将IBinder记录下来存入Activity的成员变量，以备后续调用；调用IBinder获取Service的当前状态；设置回调方法，以监听Service后续的事件变化；等等，诸如此类。

这个过程表面看上去无懈可击。但是，如果考虑到bindService是一个“异步”调用，上面的代码就会出现一个逻辑上的漏洞。也就是说，bindService被调用只是相当于启动了绑定过程，它并不会等绑定过程结束才返回。而绑定过程何时结束（也即onServiceConnected被调用），是无法预期的，这取决于绑定过程的快慢。而按照Activity的生命周期，在onResume之后，onPause也随时会被执行。这样看来，在bindService执行完后，可能onServiceConnected会先于onPause执行，也可能onPause会先于onServiceConnected执行。

当然，在一般情况下，onPause不会那么快执行，因此onServiceConnected一般都会赶在onPause之前执行。但是，从“逻辑”的角度，我们却不能完全忽视另外一种可能性。实际上它真的有可能发生，比如刚打开页面就立即退到后台，这种可能性便能以极小的概率发生。一旦发生，最后执行的onServiceConnected会建立起Activity与Service的引用和监听关系。这时应用很可能是在后台，而Activity和IBinder却可能仍互相引用着对方。这可能造成Java对象长时间释放不掉，以及其它一些诡异的问题。

这里还有一个细节，最终的表现其实还取决于系统的unbindService的内部实现。当onPause先于onServiceConnected执行的时候，onPause先调用了unbindService。如果unbindService在调用后能够严格保证ServiceConnection的回调不再发生，那么最终就不会造成前面说的Activity和IBinder相互引用的情况出现。但是，unbindService似乎没有这样的对外保证，而且根据个人经验，在Android系统的不同版本中，unbindService在这一点上的行为还不太一样。

像上面的分析一样，我们只要了解了异步任务bindService所能引发的所有可能情况，那就不难想出类似如下的应对措施。

```java
public class ServiceBindingDemoActivity extends Activity {
    /**
     * 指示本Activity是否处于running状态：执行过onResume就变为running状态。
     */
    private boolean running;

    private ServiceConnection serviceConnection = new ServiceConnection() {
        @Override
        ​public void onServiceDisconnected(ComponentName name) {
            //解除Activity与Service的引用和监听关系
            ...
        }

        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            if (running) {
                //建立Activity与Service的引用和监听关系
                ...                
            }
        }​​
    };

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
        ...

        unbindService(serviceConnection);

    }
}
```

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

@end
{% endhighlight %}

上述代码封装了Reachability类的接口。当调用者想开始网络状态监听时，就调用startNetworkMonitoring；监听完毕就调用stopNetworkMonitoring。我们设想中的长连接正好需要创建和调用Reachability对象来处理网络状态变化。它的代码的相关部分可能会如下所示（类名ServerConnection；头文件代码忽略）：

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

有人可能会说，dispatch_async执行的block中不应该直接引用self，而应该使用weak-strong dance. 也就是把dispatch_async那段代码改成下面的形式：

{% highlight objc linenos %}
        __weak ServerConnection *wself = self;
        dispatch_async(socketQueue, ^{
            __strong ServerConnection *sself = wself;
            [sself reconnect];
        });
{% endhighlight %}

这样改有没有效果呢？根据我们上面的分析，显然没有。ServerConnection的dealloc仍然在非主线程上执行，上面的问题也依然存在。weak-strong dance被设计用来解决循环引用的问题，但不能解决我们这里碰到的异步任务延迟的问题。

实际上，即使把它改成下面的形式，仍然没有效果。

{% highlight objc linenos %}
        __weak ServerConnection *wself = self;
        dispatch_async(socketQueue, ^{
            [wself reconnect];
        });
{% endhighlight %}

即使拿weak引用（wself）来调用reconnect方法，它一旦执行，也会造成ServerConnection的引用计数增加。结果仍然是dealloc在非主线程上执行。

那既然dealloc在非主线程上执行会造成问题，那我们强制把dealloc里面的代码调度到主线程执行好了，如下：

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

个人认为：**并不是所有的销毁工作都适合写在dealloc里**。

dealloc最擅长的事，自然还是释放内存，比如调用各个成员变量的release（在ARC中这个release也省了）。但是，如果要依赖dealloc来维护一些作用域更广（超出当前对象的生命周期）的变量或过程，则不是一个好的做法。原因至少有两点：

- dealloc的执行可能会被延迟，无法确保精确的执行时间；
- 无法控制dealloc是否会在主线程被调用。

比如上面的ServerConnection的例子，业务逻辑自己肯定知道应该在什么时机去停止监听网络状态，而不应该依赖dealloc来完成它。

另外，对于dealloc可能会在异步线程执行的问题，我们应该特别关注它。对于不同类型的对象，我们应该采取不同的态度。比如，对于起到View角色的对象，我们的正确态度是：**不应该允许dealloc在异步线程执行的情况出现**。为了避免出现这种情况，我们应该竭力避免在View里面直接启动异步任务，或者避免在生命周期更长的异步任务中对View产生强引用。

在上面两个例子中，问题出现的根源在于异步任务。我们仔细思考后会发现，在讨论异步任务的时候，我们必须关注一个至关重要的问题，即**条件失效问题**。当然，这也是一个显而易见的问题：当一个异步任务真正执行的时候（或者一个异步事件真正发生的时候），境况很可能已与当初调度它时不同，或者说，它当初赖以执行或发生的条件可能已经失效。

在第一个Service Binding的例子中，异步绑定过程开始调度的时候（bindService被调用的时候），Activity还处于Running状态（在执行onResume）；而绑定过程结束的时候（onServiceConnected被调用的时候），Activity却已经从Running状态中退出（执行过了onPause，已经又解除绑定了）。

在第二个网络监听的例子中，当异步重连任务结束的时候，外部对于ServerConnection实例的引用已经不复存在，实例马上就要进行销毁过程了。继而造成停止监听时的Run Loop也不再是原来那一个了。

在开始下一节有关异步任务的正式讨论之前，我们有必要对iOS和Android中经常碰到的异步任务做一个总结。

1. 网络请求​。由于网络请求耗时较长，通常网络请求接口都是异步的（例如iOS的NSURLConnection，或Android的Volley）。一般情况下，我们在主线程启动一个网络请求，然后被动地等待请求成功或者失败的回调发生（意味着这个异步任务的结束），最后根据回调结果更新UI。从启动网络请求，到获知明确的请求结果（成功或失败），时间是不确定的。

2. 通过线程池机制主动创建的异步任务。对于那些需要较长时间同步执行的任务（比如读取磁盘文件这种延迟高的操作，或者执行大计算量的任务），我们通常依靠系统提供的线程池机制把这些任务调度到异步线程去执行，以节约主线程宝贵的计算时间。关于这些线程池机制，在iOS中，我们有GCD（dispatch_async）、NSOperationQueue；在Android上，我们有JDK提供的传统的ExecutorService，也有Android SDK提供的AsyncTask​。不管是哪种实现形式，我们都为自己创造了大量的异步任务。

3. Run Loop调度任务。在iOS上，我们可以调用NSObject的若干个performSelectorXXX方法将任务调度到目标线程的Run Loop上去异步执行（performSelectorInBackground:withObject:除外）。类似地，在Android上，我们可以调用Handler的post/sendMessage方法或者View的post方法将任务异步调度到对应的Run Loop上去。实际上，不管是iOS还是Android系统，一般客户端的基础架构中都会为主线程创建一个Run Loop（当然，非主线程也可以创建Run Loop）。它可以让长时间存活的线程周期性地处理短任务，而在没有任务可执行的时候进入睡眠，既能高效及时地响应事件处理，又不会耗费多余的CPU时间。同时，更重要的一点是，Run Loop模式让客户端的多线程编程逻辑变得简单。客户端编程比服务器编程的多线程模型要简单，很大程度上要归功于Run Loop的存在。在客户端编程中，当我们想执行一个长的同步任务时，一般先通过前面（2）中提及的线程池机制将它调度到异步线程，在任务执行完后，再通过本节提到的Run Loop调度方法或者GCD等机制重新调度回主线程的Run Loop上。这种“**主线程->异步线程->主线程**”的模式，基本成为了客户端多线程编程的基本模式。这种模式规避了多个线程之间可能存在的复杂的同步操作，使处理变得简单。在后面第（三）部分——执行多个异步任务，我们还有机会继续探讨这个话题。

4. 延迟调度任务。这一类任务在指定的某个时间段之后，或者在指定的某个时间点开始执行，可以用于实现类似重试队列之类的结构。延迟调度任务有多种实现方式。​在iOS中，NSObject的performSelector:withObject:afterDelay:，GCD的dispatch_after或dispatch_time，另外，还有NSTimer；在Android中，Handler的postDelayed和postAtTime，View的postDelayed，还有老式的java.util.Timer，此外，安卓中还有一个比较重的调度器——能在任务调度执行时自动唤醒程序的AlarmService。

5. 跟系统实现相关的异步行为。这类行为种类繁多，这里举几个例子。比如：安卓中的startActivity是一个异步操作，从调用后到Activity被创建和显示，仍有一小段时间。再如：Activity和Fragment的生命周期是异步的，即使Activity的生命周期已经到了onResume，你还是不知道它所包含的Fragment的生命周期走到哪一步了（以及它的view层次有没有被创建出来）。再比如，在iOS和Android系统上都有监听网络状态变化的机制（本文前面的第二个代码例子中就有涉及），网络状态变化回调何时执行就是一个异步事件。这些异步行为同样需要统一完整的异步处理。

本文在最后还需要澄清一个关于题目的问题。​这个系列虽命名为《Android和iOS开发中的异步处理》，但是对于异步任务的处理这个话题，实际中并不局限于“iOS或Android开发”中，比如在服务器的开发中也是有可能遇到的。在这个系列中我所要表达的，更多的是一个抽象的逻辑，并不局限于iOS或Android某种具体的技术。只是，在iOS和Android的前端开发中，异步任务被应用得如此广泛，以至于我们应该把它当做一个更普遍的问题来对待了。