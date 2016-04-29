---
layout: post
category: [ios,android]
title: "iOS和Android开发中的异步处理（二）——异步任务的回调"
date: 2016-04-09 15:07:00 +0800
published: true
---

本文是笔者的系列文章《[iOS和Android开发中的异步处理](/posts/blog-series-async-task-1.html)》的第二篇。在本篇文章中，我们主要讨论跟异步任务的回调有关的诸多问题。

在iOS中，回调通常表现为delegate的形式；而在Android中，回调通常以listener的形式存在。但不管表现形式如何，回调都是接口设计不可分割的一部分。

<!--more-->

那么在回调接口的设计和实现中，我们需要考虑哪些因素呢？下面就让我们从各个方面进行讨论。

#### 必须产生结果回调

当接口设计成异步的形式时，接口的最终执行结果就通过回调来返回给调用者。

但回调接口并不总是传递最终结果。实际上我们可以将回调分成两类：

* 中间回调
* 结果回调

而结果回调又包含成功结果回调和失败结果回调。

中间回调可能在异步任务开始执行时，执行进度有更新时，或者其它重要的中间事件发生时被调用；而结果回调要等异步任务执行到最后，有了一个明确的结果（成功了或失败了），才被调用。结果回调的发生意味着此次异步接口的执行结束。

“必须产生结果回调”，这条规则并不像想象的那样容易遵守。它要求在异步接口的实现中无论发生什么异常状况，都要在有限的时间内产生结果回调。比如，接收到非法的输入参数，程序的运行时异常，任务中途被取消，任务超时，以及种种意想不到的错误，这些都是发生异常状况的例子。

这里的难度就在于，接口的实现要慎重对待所有可能的错误情况，不管哪种情况出现，都必须产生结果回调。否则，可能会导致调用方整个执行流程的中断。


#### 重视失败回调 & 错误码应该尽量详细

先看一段代码例子：

{% highlight java linenos %}
public interface Downloader {
    /**
     * 设置监听器.
     * @param listener
     */
    void setListener(DownloadListener listener);
    /**
     * 启动资源的下载.
     * @param url 要下载的资源地址.
     * @param localPath 资源下载后要存储的本地位置.
     */
    void startDownload(String url, String localPath);
}

public interface DownloadListener {
    /**
     * 下载结束回调.
     * @param result 下载结果. true表示下载成功, false表示下载失败.
     * @param url 资源地址
     * @param localPath 下载后的资源存储位置. 只有result=true时才有效.
     */
    void downloadFinished(boolean result, String url, String localPath);

    /**
     * 下载进度回调.
     * @param url 资源地址
     * @param downloadedSize 已下载大小.
     * @param totalSize 资源总大小.
     */
    void downloadProgress(String url, long downloadedSize, long totalSize);
}
{% endhighlight %}

这段代码定义了一个下载器接口，用于从指定的URL下载资源。这是一个异步接口，调用者通过调用startDownload启动下载任务，然后等着回调。当downloadFinished回调发生时，表示下载任务结束了。如果返回result=true，则说明下载成功，否则说明下载失败。

这个接口定义基本上算是比较完备了，能够完成下载资源的基本流程：我们能通过这个接口启动一个下载任务，在下载过程中获得下载进度（中间回调），在下载成功时能够取得结果，在下载失败时也能得到通知（成功和失败都属于结果回调）。但是，如果在下载失败时我们想获知更详细的失败原因，那么现在这个接口就做不到了。

具体的失败原因，上层调用者可能需要处理，也可能不需要处理。在下载失败后，上层的展示层可能只是会为下载失败的资源做一个标记，而不区分是如何失败的。当然也有可能展示层会提示用户具体的失败原因，让用户接下来知道需要做哪些操作来恢复错误，比如，由于“网络不可用”而造成的下载失败，可以提示用户切换到更好的网络；而由于“存储空间不足”而造成的下载失败，则可以提示用户清理存储空间。总之，应该由上层调用者来决定是否显示具体错误原因，以及如何显示，而不是在定义底层回调接口时就决定。

因此，结果回调中的失败回调，应该返回尽可能详细的错误码，让调用者在发生错误时有更多的选择。这一规则，对于library的开发者来说，似乎毋庸置疑。但是，对于上层应用的开发者来说，往往得不到足够的重视。返回详尽的错误码，意味着在失败处理上花费更多的工夫。为了“节省时间”和“实用主义”，人们往往对于错误情况采取“简单处理”，但却给日后的扩展带来了隐患。

对于上面下载器接口的代码例子，为了能返回更详尽的错误码，其中DownloadListener的代码修改如下：

{% highlight java linenos %}
public interface DownloadListener {
    /**
     * 错误码定义
     */
    public static final int SUCCESS = 0;//成功
    public static final int INVALID_PARAMS = 1;//输入参数有误
    public static final int NETWORK_UNAVAILABLE = 2;//网络不可用
    public static final int UNKNOWN_HOST = 3;//域名解析失败
    public static final int CONNECT_TIMEOUT = 4;//连接超时
    public static final int HTTP_STATUS_NOT_OK = 5;//下载请求返回非200
    public static final int SDCARD_NOT_EXISTS = 6;//SD卡不存在(下载的资源没地方存)
    public static final int SD_CARD_NO_SPACE_LEFT = 7;//SD卡空间不足(下载的资源没地方存)
    public static final int READ_ONLY_FILE_SYSTEM = 8;//文件系统只读(下载的资源没地方存)
    public static final int LOCAL_IO_ERROR = 9;//本地SD存取有关的错误
    public static final int UNKNOWN_FAILED = 10;//其它未知错误

    /**
     * 下载成功回调.
     * @param url 资源地址
     * @param localPath 下载后的资源存储位置.
     */
    void downloadSuccess(String url, String localPath);
    /**
     * 下载失败回调.
     * @param url 资源地址
     * @param errorCode 错误码.
     * @param errorMessage 错误信息简短描述. 供调用者理解错误原因.
     */
    void downloadFailed(String url, int errorCode, String errorMessage);

    /**
     * 下载进度回调.
     * @param url 资源地址
     * @param downloadedSize 已下载大小.
     * @param totalSize 资源总大小.
     */
    void downloadProgress(String url, long downloadedSize, long totalSize);
}
{% endhighlight %}

在iOS中，Foundation Framework对于程序错误有一个系统的封装：NSError。它能以非常通用的方式来封装错误码，而且能将错误分成不同的domain。NSError就很适合用在这种失败回调接口的定义中。

#### 调用接口和回调接口应该有清晰的对应关系

我们通过一个真实的接口定义的例子来分析这个问题。

下面是来自国内某广告平台的视频广告积分墙的接口定义代码（为展示清楚，省略了一些无关的代码）。

{% highlight objc linenos %}
@class IndependentVideoManager;

@protocol IndependentVideoManagerDelegate <NSObject>
@optional
#pragma mark - independent video present callback 视频广告展现回调

...

#pragma mark - point manage callback 积分管理

...

#pragma mark - independent video status callback 积分墙状态
/**
 *  视频广告墙是否可用。
 *  Called after get independent video enable status.
 *
 *  @param IndependentVideoManager
 *  @param enable
 */
- (void)ivManager:(IndependentVideoManager *)manager
didCheckEnableStatus:(BOOL)enable;

/**
 *  是否有视频广告可以播放。
 *  Called after check independent video available.
 *
 *  @param IndependentVideoManager
 *  @param available
 */
- (void)ivManager:(IndependentVideoManager *)manager
isIndependentVideoAvailable:(BOOL)available;


@end

@interface IndependentVideoManager : NSObject {
    
}

@property(nonatomic,assign)id<IndependentVideoManagerDelegate>delegate;

...

#pragma mark - init 初始化相关方法

...

#pragma mark - independent video present 积分墙展现相关方法
/**
 *  使用App的rootViewController来弹出并显示列表积分墙。
 *  Present independent video in ModelView way with App's rootViewController.
 *
 *  @param type 积分墙类型
 */
- (void)presentIndependentVideo;

...

#pragma mark - independent video status 检查视频积分墙是否可用
/**
 *  是否有视频广告可以播放
 *  check independent video available.
 */
- (void)checkVideoAvailable;

#pragma mark - point manage 积分管理相关广告
/**
 *  检查已经得到的积分，成功或失败都会回调代理中的相应方法。
 *
 */
- (void)checkOwnedPoint;
/**
 *  消费指定的积分数目，成功或失败都会回调代理中的相应方法（请特别注意参数类型为unsigned int，需要消费的积分为非负值）。
 *
 *  @param point 要消费积分的数目
 */
- (void)consumeWithPointNumber:(NSUInteger)point;

@end
{% endhighlight %}

我们来分析一下在这段接口定义中调用接口和回调接口之间的对应关系。

使用IndependentVideoManager可以调用的接口，除了初始化的接口之外，主要有这几个：

* 弹出并显示视频 (presentIndependentVideo)
* 检查是否有视频广告可以播放 (checkVideoAvailable)
* 积分管理 (checkOwnedPoint和consumeWithPointNumber:)

而回调接口 (IndependentVideoManagerDelegate) 可以分为下面几类：

* 视频广告展现回调类
* 积分墙状态类 (ivManager:didCheckEnableStatus:和ivManager:isIndependentVideoAvailable:)
* 积分管理类

总体来说，这里的对应关系还是比较清楚的，这三类回调接口基本上与前面的三部分调用接口能够一一对应上。

不过，积分墙状态类的回调接口还是有一点让人迷惑的细节：看起来调用者在调用checkVideoAvailable后，会收到积分墙状态类的两个回调 (ivManager:didCheckEnableStatus:和ivManager:isIndependentVideoAvailable:)；但是，从接口名称所能表达的含义来看，调用checkVideoAvailable是为了检查是否有视频广告可以播放，那么单单是ivManager:isIndependentVideoAvailable:这一个回调接口就能返回所需要的结果了，似乎不太需要ivManager:didCheckEnableStatus:。而从ivManager:didCheckEnableStatus所表达的含义（视频广告墙是否可用）上来看，它似乎在任何调用接口被调用时都可能会执行，而不应该只对应checkVideoAvailable。这里的回调接口设计，在与调用接口的对应关系上，是令人困惑的。

#### 成功结果回调和失败结果回调应该彼此互斥

当一个异步任务结束时，它或者调用成功结果回调，或者调用失败结果回调。两者只能调用其一。这是显而易见的要求，但若在实现时不加注意，却也可能无法遵守这一要求。

假设我们前面提到的Downloader接口在最终产生结果回调的时候代码如下：

{% highlight java linenos %}
    int errorCode = parseDownloadResult(result);
    if (errorCode == SUCCESS) {
        listener.downloadSuccess(url, localPath)
    }
    else {
        listener.downloadFailed(url, errorCode, getErrorMessage(errorCode));
    }
{% endhighlight %}

进而我们发现，为了能够达到“必须产生结果回调”的目标，我们应该考虑parseDownloadResult这个方法抛异常的可能。于是，我们修改代码如下：

{% highlight java linenos %}
    try {
        int errorCode = parseDownloadResult(result);
        if (errorCode == SUCCESS) {
            listener.downloadSuccess(url, localPath)
        }
        else {
            listener.downloadFailed(url, errorCode, getErrorMessage(errorCode));
        }
    }
    catch (Exception e) {
        listener.downloadFailed(url, UNKNOWN_FAILED, getErrorMessage(UNKNOWN_FAILED));
    }
}
{% endhighlight %}

代码改成这样，已经能保证即使出现了意想不到的情况，也能对调用者产生一个失败回调。

但是，这也带来另一个问题：如果在调用listener.downloadSuccess或listener.downloadFailed的时候，回调接口的实现代码抛了异常呢？那会造成再多调用一次listener.downloadFailed。于是，成功结果回调和失败结果回调不再彼此互斥地被调用了：或者成功和失败回调都发生了，或者连续两次失败回调。

回调接口的实现是归调用者负责的部分，难道调用者犯的错误也需要我们来考虑？首先，这主要还是应该由上层调用者来负责处理，回调接口的实现者实在不应该在异常发生时再把异常抛回来。但是，底层接口的设计者也应当尽力而为。作为接口的设计者，通常不能
预期调用者会怎么表现，如果在异常发生时，我们能保证当前错误不至于让整个流程中断和卡死，岂不是更好呢？于是，我们可以尝试把代码改成如下这样：

{% highlight java linenos %}
    int errorCode;
    try {
        errorCode = parseDownloadResult(result);
    }
    catch (Exception e) {
        errorCode = UNKNOWN_FAILED;
    }
    if (errorCode == SUCCESS) {
        try {
            listener.downloadSuccess(url, localPath)
        }
        catch (Throwable e) {
            e.printStackTrace();
        }
    }
    else {
        try {
            listener.downloadFailed(url, errorCode, getErrorMessage(errorCode));
        }
        catch (Throwable e) {
            e.printStackTrace();
        }
    }
}
{% endhighlight %}

#### 回调的线程模型

异步接口能够得以实现的技术基础，主要有两个：

* 多线程（接口的实现代码在与调用线程不同的异步线程中执行）
* 异步IO（比如异步网络请求。在这种情况下，即使整个程序只有一个线程，也能实现出异步接口）

不管是哪种情况，我们都需要对回调发生的线程环境有清晰的定义。

通常来讲，定义结果回调的执行线程环境主要有三种模式：

1. 在哪个线程上调用接口，就在哪个线程上发生结果回调。
2. 不管在哪个线程上调用接口，都在主线程上发生结果回调（例如Android的AsyncTask）。
3. 调用者可以自定义回调接口在哪个线程上发生。（例如iOS的NSURLConnection，通过scheduleInRunLoop:forMode:来设置回调发生的Run Loop）

显然第3种模式最为灵活，因为它包含了前两种。

为了能把执行代码调度到其它线程，我们需要使用在上一篇[iOS和Android开发中的异步处理（一）——概述](/posts/blog-series-async-task-1.html)最后“Run Loop调度任务”那一小节提到的技术。我们有必要对线程调度的实质加以理解。

在客户端编程的大多数情况下，我们一般会希望结果回调发生在主线程上，因为我们一般会在这个时机更新UI。

----
看起来可能略显啰嗦，似乎用了大部分篇幅在说明一些显而易见的东西。工作多年的人也未必有清晰的套路。

