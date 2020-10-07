---
layout: post
category: "client_dev"
title: "Android和iOS开发中的异步处理（二）——异步任务的回调"
date: 2016-05-11 12:00:00 +0800
published: true
---

本文是系列文章《[Android和iOS开发中的异步处理](/posts/blog-series-async-task-1.html)》的第二篇。在本篇文章中，我们主要讨论跟异步任务的回调有关的诸多问题。

在iOS中，回调通常表现为delegate的形式；而在Android中，回调通常以listener的形式存在。但不管表现形式如何，回调都是接口设计不可分割的一部分。回调接口设计的好坏，直接影响整个接口设计的成功与否。

<!--more-->

那么在回调接口的设计和实现中，我们需要考虑哪些方面呢？现在我们先把本文要讨论的子话题列出如下，然后再逐个讨论：

* 必须产生结果回调
* 重视失败回调 & 错误码应该尽量详细
* 调用接口和回调接口应该有清晰的对应关系
* 成功结果回调和失败结果回调应该彼此互斥
* 回调的线程模型
* 回调的context参数（透传参数）
* 回调顺序
* 闭包形式的回调和Callback Hell

注：本系列文章中出现的代码已经整理到GitHub上（持续更新），代码库地址为：

* <https://github.com/tielei/AsyncProgrammingDemos>{:target="_blank"}

其中，当前这篇文章中出现的Java代码，位于com.zhangtielei.demos.async.programming.callback这个package中。

---

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

```java
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
```

这段代码定义了一个下载器接口，用于从指定的URL下载资源。这是一个异步接口，调用者通过调用startDownload启动下载任务，然后等着回调。当downloadFinished回调发生时，表示下载任务结束了。如果返回result=true，则说明下载成功，否则说明下载失败。

这个接口定义基本上算是比较完备了，能够完成下载资源的基本流程：我们能通过这个接口启动一个下载任务，在下载过程中获得下载进度（中间回调），在下载成功时能够取得结果，在下载失败时也能得到通知（成功和失败都属于结果回调）。但是，如果在下载失败时我们想获知更详细的失败原因，那么现在这个接口就做不到了。

具体的失败原因，上层调用者可能需要处理，也可能不需要处理。在下载失败后，上层的展示层可能只是会为下载失败的资源做一个标记，而不区分是如何失败的。当然也有可能展示层会提示用户具体的失败原因，让用户接下来知道需要做哪些操作来恢复错误，比如，由于“网络不可用”而造成的下载失败，可以提示用户切换到更好的网络；而由于“存储空间不足”而造成的下载失败，则可以提示用户清理存储空间。总之，应该由上层调用者来决定是否显示具体错误原因，以及如何显示，而不是在定义底层回调接口时就决定。

因此，结果回调中的失败回调，应该返回尽可能详细的错误码，让调用者在发生错误时有更多的选择。这一规则，对于library的开发者来说，似乎毋庸置疑。但是，对于上层应用的开发者来说，往往得不到足够的重视。返回详尽的错误码，意味着在失败处理上花费更多的工夫。为了“节省时间”和“实用主义”，人们往往对于错误情况采取“简单处理”，但却给日后的扩展带来了隐患。

对于上面下载器接口的代码例子，为了能返回更详尽的错误码，其中DownloadListener的代码修改如下：

```java
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
```

在iOS中，Foundation Framework对于程序错误有一个系统的封装：NSError。它能以非常通用的方式来封装错误码，而且能将错误分成不同的domain。NSError就很适合用在这种失败回调接口的定义中。

#### 调用接口和回调接口应该有清晰的对应关系

我们通过一个真实的接口定义的例子来分析这个问题。

下面是来自国内某广告平台的视频广告积分墙的接口定义代码（为展示清楚，省略了一些无关的代码）。

```objc
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
```

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

此外，IndependentVideoManager的接口在上下文参数的设计上也有一些问题，本文后面会再次提到。

#### 成功结果回调和失败结果回调应该彼此互斥

当一个异步任务结束时，它或者调用成功结果回调，或者调用失败结果回调。两者只能调用其一。这是显而易见的要求，但若在实现时不加注意，却也可能无法遵守这一要求。

假设我们前面提到的Downloader接口在最终产生结果回调的时候代码如下：

```java
    int errorCode = parseDownloadResult(result);
    if (errorCode == SUCCESS) {
        listener.downloadSuccess(url, localPath)
    }
    else {
        listener.downloadFailed(url, errorCode, getErrorMessage(errorCode));
    }
```

进而我们发现，为了能够达到“必须产生结果回调”的目标，我们应该考虑parseDownloadResult这个方法抛异常的可能。于是，我们修改代码如下：

```java
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
```

代码改成这样，已经能保证即使出现了意想不到的情况，也能对调用者产生一个失败回调。

但是，这也带来另一个问题：如果在调用listener.downloadSuccess或listener.downloadFailed的时候，回调接口的实现代码抛了异常呢？那会造成再多调用一次listener.downloadFailed。于是，成功结果回调和失败结果回调不再彼此互斥地被调用了：或者成功和失败回调都发生了，或者连续两次失败回调。

回调接口的实现是归调用者负责的部分，难道调用者犯的错误也需要我们来考虑？首先，这主要还是应该由上层调用者来负责处理，回调接口的实现方（调用者）实在不应该在异常发生时再把异常抛回来。但是，底层接口的设计者也应当尽力而为。作为接口的设计者，通常不能预期调用者会怎么表现，如果在异常发生时，我们能保证当前错误不至于让整个流程中断和卡死，岂不是更好呢？于是，我们可以尝试把代码改成如下这样：

```java
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
```

回调代码复杂了一些，但也更安全了。

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

为了能把执行代码调度到其它线程，我们需要使用在上一篇[Android和iOS开发中的异步处理（一）——概述](/posts/blog-series-async-task-1.html)最后提到的一些技术，比如iOS中的GCD、NSOperationQueue、performSelectorXXX方法，Android中的ExecutorService、AsyncTask、Handler，等等（注意：ExecutorService不能用于调度到主线程，只能用于调度到异步线程）。我们有必要对线程调度的实质加以理解：能把一段代码调度到某一个线程去执行，前提条件是那个线程有一个Event Loop。这个Loop顾名思义，就是一个循环，它不停地从消息队列里取出消息，然后处理。我们做线程调度的时候，相当于向这个队列里发送消息。这个队列本身在系统实现里已经保证是线程安全的（Thread Safe Queue），因此调用者就规避了线程安全问题。在客户端开发中，系统都会为主线程创建一个Loop，但非主线程则需要开发者自己来使用适当的技术进行创建。

在客户端编程的大多数情况下，我们一般会希望结果回调发生在主线程上，因为我们一般会在这个时机更新UI。而中间回调在哪个线程上执行，则取决于具体应用场景。在前面Downloader的例子中，中间回调downloadProgress是为了回传下载进度，下载进度一般也是为了在UI上展示，因此downloadProgress也是调度到主线程上执行更好一些。

#### 回调的context参数（透传参数）

在调用一个异步接口的时候，我们经常需要临时保存一份跟该次调用相关的上下文数据，等到异步任务执行完回调发生的时候，我们能重新拿到这份上下文数据。

我们还是以前面的下载器为例。为了能清晰地讨论各种情况，我们这里假设一个稍微复杂一点的例子。假设我们要下载若干个表情包，每个表情包包含多个表情图片文件，下载完全部表情图片之后，我们需要把表情包安装到本地（可能是修改本地数据库的操作），以便用户能够在输入面板中使用它们。

假设表情包的数据结构定义如下：

```java
public class EmojiPackage {
    /**
     * 表情包ID
     */
    public long emojiId;
    /**
     * 表情包图片列表
     */
    public List<String> emojiUrls;
}
```

在下载过程中，我们需要保存一个如下的上下文结构：

```java
public class EmojiDownloadContext {
    /**
     * 当前在下载的表情包
     */
    public EmojiPackage emojiPackage;
    /**
     * 已经下载完的表情图片计数
     */
    public int downloadedEmoji;
    /**
     * 下载到的表情包本地地址
     */
    public List<String> localPathList = new ArrayList<String>();
}
```

再假设我们要实现的表情包下载器遵守下面的接口定义：

```java
public interface EmojiDownloader {
    /**
     * 开始下载指定的表情包
     * @param emojiPackage
     */
    void startDownloadEmoji(EmojiPackage emojiPackage);

    /**
     * 这里定义回调相关的接口, 忽略. 不是我们要讨论的重点.
     */
    //TODO: 回调接口相关定义
}
```

如果利用前面已有的Downloader接口来完成表情包下载器的实现，那么根据传递上下文的方式不同，我们可能会产生三种不同的做法：

（1）全局保存一份上下文。

注意：这里所说的“全局”，是针对一个表情包下载器内部而言的。代码如下：

```java
public class MyEmojiDownloader implements EmojiDownloader, DownloadListener {
    /**
     * 全局保存一份的表情包下载上下文.
     */
    private EmojiDownloadContext downloadContext;
    private Downloader downloader;

    public MyEmojiDownloader() {
        //实例化有一个下载器. MyDownloader是Downloader接口的一个实现。
        downloader = new MyDownloader();
        downloader.setListener(this);
    }

    @Override
    public void startDownloadEmoji(EmojiPackage emojiPackage) {
        if (downloadContext == null) {
            //创建下载上下文数据
            downloadContext = new EmojiDownloadContext();
            downloadContext.emojiPackage = emojiPackage;
            //启动第0个表情图片文件的下载
            downloader.startDownload(emojiPackage.emojiUrls.get(0),
                    getLocalPathForEmoji(emojiPackage, 0));
        }
    }

    @Override
    public void downloadSuccess(String url, String localPath) {
        downloadContext.localPathList.add(localPath);
        downloadContext.downloadedEmoji++;
        EmojiPackage emojiPackage = downloadContext.emojiPackage;
        if (downloadContext.downloadedEmoji < emojiPackage.emojiUrls.size()) {
            //还没下载完, 继续下载下一个表情图片
            String nextUrl = emojiPackage.emojiUrls.get(downloadContext.downloadedEmoji);
            downloader.startDownload(nextUrl,
                    getLocalPathForEmoji(emojiPackage, downloadContext.downloadedEmoji));
        }
        else {
            //已经下载完
            installEmojiPackageLocally(emojiPackage, downloadContext.localPathList);
            downloadContext = null;
        }
    }

    @Override
    public void downloadFailed(String url, int errorCode, String errorMessage) {
        ...
    }

    @Override
    public void downloadProgress(String url, long downloadedSize, long totalSize) {
        ...
    }

    /**
     * 计算表情包中第i个表情图片文件的下载地址.
     */
    private String getLocalPathForEmoji(EmojiPackage emojiPackage, int i) {
        ...
    }

    /**
     * 把表情包安装到本地
     */
    private void installEmojiPackageLocally(EmojiPackage emojiPackage, List<String> localPathList) {
        ...
    }
}
```

这种做法的缺点是：同时只能有一个表情包在下载。必须要等到前一个表情包下载完毕之后才能开始下载新的一个表情包。

虽然这种“全局保存一份上下文”的做法有这样明显的缺点，但是在某些情况下，我们却只能采取这种方式。这个后面会再提到。

（2）用映射关系来保存上下文。

在现有Downloader接口的定义下，我们只能用URL来作为这份映射关系的索引。由于一个表情包包含多个URL，因此我们必须为每一个URL都索引一份上下文。代码如下：

```java
public class MyEmojiDownloader implements EmojiDownloader, DownloadListener {
    /**
     * 保存上下文的映射关系.
     * URL -> EmojiDownloadContext
     */
    private Map<String, EmojiDownloadContext> downloadContextMap;
    private Downloader downloader;

    public MyEmojiDownloader() {
        downloadContextMap = new HashMap<String, EmojiDownloadContext>();
        //实例化有一个下载器. MyDownloader是Downloader接口的一个实现。
        downloader = new MyDownloader();
        downloader.setListener(this);
    }

    @Override
    public void startDownloadEmoji(EmojiPackage emojiPackage) {
        //创建下载上下文数据
        EmojiDownloadContext downloadContext = new EmojiDownloadContext();
        downloadContext.emojiPackage = emojiPackage;
        //为每一个URL创建映射关系
        for (String emojiUrl : emojiPackage.emojiUrls) {
            downloadContextMap.put(emojiUrl, downloadContext);
        }
        //启动第0个表情图片文件的下载
        downloader.startDownload(emojiPackage.emojiUrls.get(0),
                getLocalPathForEmoji(emojiPackage, 0));
    }

    @Override
    public void downloadSuccess(String url, String localPath) {
        EmojiDownloadContext downloadContext = downloadContextMap.get(url);
        downloadContext.localPathList.add(localPath);
        downloadContext.downloadedEmoji++;
        EmojiPackage emojiPackage = downloadContext.emojiPackage;
        if (downloadContext.downloadedEmoji < emojiPackage.emojiUrls.size()) {
            //还没下载完, 继续下载下一个表情图片
            String nextUrl = emojiPackage.emojiUrls.get(downloadContext.downloadedEmoji);
            downloader.startDownload(nextUrl,
                    getLocalPathForEmoji(emojiPackage, downloadContext.downloadedEmoji));
        }
        else {
            //已经下载完
            installEmojiPackageLocally(emojiPackage, downloadContext.localPathList);
            //为每一个URL删除映射关系
            for (String emojiUrl : emojiPackage.emojiUrls) {
                downloadContextMap.remove(emojiUrl);
            }
        }
    }

    @Override
    public void downloadFailed(String url, int errorCode, String errorMessage) {
        ...
    }

    @Override
    public void downloadProgress(String url, long downloadedSize, long totalSize) {
        ...
    }

    /**
     * 计算表情包中第i个表情图片文件的下载地址.
     */
    private String getLocalPathForEmoji(EmojiPackage emojiPackage, int i) {
        ...
    }

    /**
     * 把表情包安装到本地
     */
    private void installEmojiPackageLocally(EmojiPackage emojiPackage, List<String> localPathList) {
        ...
    }
}
```

这种做法也有它的缺点：并不能每次都能找到恰当的能唯一索引上下文数据的变量。在这个表情包下载器的例子中，能唯一标识下载的变量本来应该是emojiId，但在Downloader的回调接口中却无法取到这个值，因此只能改用每个URL都建立一份到上下文数据的索引。这样带来的结果就是：如果两个不同表情包包含了某个相同的URL，就可能出现冲突。另外，这种做法的实现比较复杂。


（3）为每一个异步任务创建一个接口实例。

通常来讲，按照我们的设计初衷，我们希望只实例化一个接口实例（即一个Downloader实例），然后用这一个实例来启动多个异步任务。但是，如果我们每次启动新的异步任务都是新创建一个接口实例，那么异步任务就和接口实例个数一一对应了，这样就能将异步任务的上下文数据存到这个接口实例中。代码如下：

```java
public class MyEmojiDownloader implements EmojiDownloader {
    @Override
    public void startDownloadEmoji(EmojiPackage emojiPackage) {
        //创建下载上下文数据
        EmojiDownloadContext downloadContext = new EmojiDownloadContext();
        downloadContext.emojiPackage = emojiPackage;
        //为每一次下载创建一个新的Downloader
        final EmojiUrlDownloader downloader = new EmojiUrlDownloader();
        //将上下文数据存到downloader实例中
        downloader.downloadContext = downloadContext;

        downloader.setListener(new DownloadListener() {
            @Override
            public void downloadSuccess(String url, String localPath) {
                EmojiDownloadContext downloadContext = downloader.downloadContext;
                downloadContext.localPathList.add(localPath);
                downloadContext.downloadedEmoji++;
                EmojiPackage emojiPackage = downloadContext.emojiPackage;
                if (downloadContext.downloadedEmoji < emojiPackage.emojiUrls.size()) {
                    //还没下载完, 继续下载下一个表情图片
                    String nextUrl = emojiPackage.emojiUrls.get(downloadContext.downloadedEmoji);
                    downloader.startDownload(nextUrl,
                            getLocalPathForEmoji(emojiPackage, downloadContext.downloadedEmoji));
                }
                else {
                    //已经下载完
                    installEmojiPackageLocally(emojiPackage, downloadContext.localPathList);
                }
            }

            @Override
            public void downloadFailed(String url, int errorCode, String errorMessage) {
                //TODO:
            }

            @Override
            public void downloadProgress(String url, long downloadedSize, long totalSize) {
                //TODO:
            }
        });

        //启动第0个表情图片文件的下载
        downloader.startDownload(emojiPackage.emojiUrls.get(0),
                getLocalPathForEmoji(emojiPackage, 0));
    }

    private static class EmojiUrlDownloader extends MyDownloader {
        public EmojiDownloadContext downloadContext;
    }

    /**
     * 计算表情包中第i个表情图片文件的下载地址.
     */
    private String getLocalPathForEmoji(EmojiPackage emojiPackage, int i) {
        ...
    }

    /**
     * 把表情包安装到本地
     */
    private void installEmojiPackageLocally(EmojiPackage emojiPackage, List<String> localPathList) {
        ...
    }
}
```

这样做自然缺点也很明显：为每一个下载任务都创建一个下载器实例，这有违我们对于Downloader接口的设计初衷。这会创建大量多余的实例。特别是，当接口实例是个很重的大对象时，这样做会带来大量的开销。

上面三种做法，每一种都不是很理想。根源在于：底层的异步接口Downloader不能支持上下文（context）传递（注意，它跟Android系统中的Context没有什么关系）。这样的上下文参数不同的人有不同的叫法：

* context（上下文）
* 透传参数
* callbackData
* cookie
* userInfo

不管这个参数叫什么名字，它的作用都是一样的：在调用异步接口的时候传递进去，当回调接口发生时它还能传回来。这个上下文参数由上层调用者定义，底层接口的实现并不用理解它的含义，而只是负责透传。

支持了上下文参数的Downloader接口改动如下：

```java
public interface Downloader {
    /**
     * 设置回调监听器.
     * @param listener
     */
    void setListener(DownloadListener listener);
    /**
     * 启动资源的下载.
     * @param url 要下载的资源地址.
     * @param localPath 资源下载后要存储的本地位置.
     * @param contextData 上下文数据, 在回调接口中会透传回去.可以是任何类型.
     */
    void startDownload(String url, String localPath, Object contextData);
}
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
     * @param contextData 上下文数据.
     */
    void downloadSuccess(String url, String localPath, Object contextData);
    /**
     * 下载失败回调.
     * @param url 资源地址
     * @param errorCode 错误码.
     * @param errorMessage 错误信息简短描述. 供调用者理解错误原因.
     * @param contextData 上下文数据.
     */
    void downloadFailed(String url, int errorCode, String errorMessage, Object contextData);

    /**
     * 下载进度回调.
     * @param url 资源地址
     * @param downloadedSize 已下载大小.
     * @param totalSize 资源总大小.
     * @param contextData 上下文数据.
     */
    void downloadProgress(String url, long downloadedSize, long totalSize, Object contextData);
}
```

利用这个最新的Downloader接口，前面的表情包下载器就有了第4种实现方式。

（4）利用支持上下文传递的异步接口。

代码如下：

```java
public class MyEmojiDownloader implements EmojiDownloader, DownloadListener {
    private Downloader downloader;

    public MyEmojiDownloader() {
        //实例化有一个下载器. MyDownloader是Downloader接口的一个实现。
        downloader = new MyDownloader();
        downloader.setListener(this);
    }

    @Override
    public void startDownloadEmoji(EmojiPackage emojiPackage) {
        //创建下载上下文数据
        EmojiDownloadContext downloadContext = new EmojiDownloadContext();
        downloadContext.emojiPackage = emojiPackage;
        //启动第0个表情图片文件的下载, 上下文参数传递进去
        downloader.startDownload(emojiPackage.emojiUrls.get(0),
                getLocalPathForEmoji(emojiPackage, 0),
                downloadContext);

    }

    @Override
    public void downloadSuccess(String url, String localPath, Object contextData) {
        //通过回调接口的contextData参数做Down-casting获得上下文参数
        EmojiDownloadContext downloadContext = (EmojiDownloadContext) contextData;

        downloadContext.localPathList.add(localPath);
        downloadContext.downloadedEmoji++;
        EmojiPackage emojiPackage = downloadContext.emojiPackage;
        if (downloadContext.downloadedEmoji < emojiPackage.emojiUrls.size()) {
            //还没下载完, 继续下载下一个表情图片
            String nextUrl = emojiPackage.emojiUrls.get(downloadContext.downloadedEmoji);
            downloader.startDownload(nextUrl,
                    getLocalPathForEmoji(emojiPackage, downloadContext.downloadedEmoji),
                    downloadContext);
        }
        else {
            //已经下载完
            installEmojiPackageLocally(emojiPackage, downloadContext.localPathList);
        }
    }

    @Override
    public void downloadFailed(String url, int errorCode, String errorMessage, Object contextData) {
        ...
    }

    @Override
    public void downloadProgress(String url, long downloadedSize, long totalSize, Object contextData) {
        ...
    }

    /**
     * 计算表情包中第i个表情图片文件的下载地址.
     */
    private String getLocalPathForEmoji(EmojiPackage emojiPackage, int i) {
        ...
    }

    /**
     * 把表情包安装到本地
     */
    private void installEmojiPackageLocally(EmojiPackage emojiPackage, List<String> localPathList) {
        ...
    }
}
```

显然，最后第4种实现方法更合理一些，代码更紧凑，也没有前面3种的缺点。但是，它要求我们调用的底层异步接口对上下文传递有完善的支持。在实际情况中，我们需要调用的接口大都是既定的，无法修改的。如果我们碰到的接口对上下文参数传递支持得不好，我们就别无选择，只能采取前面3种做法中的一种。总之，我们在这里讨论前3种做法并非自寻烦恼，而是为了应对那些对回调上下文支持不够的接口，而这些接口的设计者通常是无意中给我们出了这样的难题。

一个典型的情况是：提供给我们的接口不支持自定义的上下文数据传递，而且我们也找不到恰当的能唯一索引上下文数据的变量，从而逼迫我们只能使用前面第1种“全局保存一份上下文”的做法。

现在，我们可以很容易得出结论：**一个好的回调接口定义，应该具有传递自定义上下文数据的能力**。

我们再从上下文传递能力的角度来重新审视一下一些系统的回调接口定义。比如说iOS中UIAlertViewDelegate的alertView:clickedButtonAtIndex:，或者UITableViewDataSource的tableView:cellForRowAtIndexPath:，这些回调接口的第一个参数都会回传那个UIView本身的实例（其实UIKit中大多数回调接口都以类似的方式定义）。这起到了一定的上下文传递的作用，它可以用来区分不同的UIView实例，但不能用来区分同一个UIView实例内的不同回调。如果同一个页面内需要先后多次弹出UIAlertView框，那么我们每次都需要新创建一个UIAlertView实例，然后在回调中就能根据传回的UIAlertView实例来区分是哪一次弹框。这类似于前面讨论过的第3种做法。UIView本身还预定义了一个用于传递整型上下文的tag参数，但如果我们想传递更多的其它类型的上下文，那么我们就只能像前述第3种做法一样，继承一个UIView的自己的子类出来，在里面放置上下文参数。

UIView每次新的展示都创建一个实例，这本身并不能被视为过多的开销。毕竟，UIView的典型用法就是为了一个个创建出来并添加到View层次中加以展示的。但是，我们在前面提到的IndependentVideoManager的例子就不同了。它的回调接口被设计成第一个参数回传IndependentVideoManager实例，比如ivManager:isIndependentVideoAvailable:，可以猜测这样的回调接口定义必定是参考了UIKit。但IndependentVideoManager的情况明显不同，它一般只需要创建一个实例，然后通过在同一个实例上多次调用接口来多次播放广告。这里更需要区分的是同一个实例上多次不同的回调，每次回调携带了哪些上下文参数。这里真正需要的上下文传递能力，跟我们上面讨论的第4种做法类似，而像UIKit那样的接口定义方式提供的上下文传递能力是不够的。

在回调接口的设计中，上下文传递能力，关键的一点在于：**它能否区分单一接口实例的多次回调**。

再来看一下Android上的例子。Android上的回调接口以listener的形式呈现，典型的代码如下：

```java
Button button = (Button) findViewById(...);
button.setOnClickListener(new View.OnClickListener() {
    @Override
    public void onClick(View v) {
        ...
    }
});
```

这段代码中一个Button实例，可以对应多次回调（多次点击事件），但我们不能通过这段代码在这些不同的回调之间进行区分处理。所幸的是，我们实际上也不需要。

通过以上讨论，我们发现，与View层面有关的偏“前端”的开发，通常不太需要区分单个接口实例的多次回调，因此不太需要复杂的上下文传递机制。而偏“后端”开发的异步任务，特别是生命周期长的异步任务，却需要更强大的上下文传递能力。所以，本系列文章的上一篇才会把“异步处理”问题列为与“后端”编程紧密相关的工作。

关于上下文参数的话题，还有一些小问题也值得注意：比如在iOS上，context参数在异步任务执行期间是保持strong还是weak的引用？如果是强引用，那么如果调用者传进来的context参数是View Controller这样的大对象，那么就会造成循环引用，有可能导致内存泄漏；而如果是弱引用，那么如果调用者传进来的context参数是临时创建的对象，那么就会造成临时对象刚创建就销毁，根本透传不过去。这本质上是引用计数的内存管理机制带来的两难问题。这就要看我们预期的是什么场景，我们这里讨论的context参数能够用于区分单个接口实例的多次回调，所以传进来的context参数不太可能是生命周期长的大对象，而应该是生命周期与一个异步任务基本相同的小对象，它在每次接口调用开始时创建，在单次异步任务结束（结果回调发生）的时候释放。因此，在这种预期的场景下，我们应该为context参数传进来的对象保持强引用。

#### 回调顺序

还是以前面的下载器接口为例，假如我们连续调用两次startDownload，启动了两个异步下载任务。那么，两个下载任务哪一个先执行完，是不太确定的。那就意味着可能先启动的下载任务，反而先执行了结果回调（downloadSuccess或downloadFailed）。这种回调顺序与初始接口调用顺序不一致的情况（可以称为回调乱序），是否会造成问题，取决于调用方的应用场景和具体实现逻辑。但是，从两个方面来考虑，我们必须注意到：

* 作为接口调用方，我们必须弄清楚我们正在使用的接口是否会发生“回调乱序”。如果会，那么我们在处理接口回调的时候就要时刻注意，保证它不会带来恶性后果。
* 作为接口实现方，我们在实现接口的时候就要明确是否为回调顺序提供强的保证：保证不会发生回调乱序。如果需要提供这种保证，那么就会增加接口实现的复杂度。

从异步接口的实现方来讲，引发回调乱序的因素可能有：

* 提前的失败结果回调。实际上，这种情况很容易发生，但却很难让人意识到这会导致回调乱序。一个典型的例子是，一个异步任务的实现通常要调度到另一个异步线程去执行，但在调度到异步线程之前，就检查到了某种严重的错误（比如传入参数无效导致的错误）从而结束了整个任务，并触发了失败结果回调。这样，后启动但提前失败的异步任务，可能会比先启动但正常运行的任务更早一步回调。
* 提前的成功结果回调。与“提前的失败结果回调”情况类似。一个典型的例子是多级缓存的提前命中。比如Memory缓存一般都是同步地去查，如果先查Memory缓存的时候命中了，这样就有可能在当前主线程直接发生成功结果回调了，而省去了调度到另一个异步线程再回调的步骤。
* 异步任务的并发执行。异步接口背后的实现可能对应一个并发的线程池，这样并发执行的各个异步任务的完成顺序就是随机的。
* 底层依赖的其它异步任务是回调乱序的。

不管回调乱序是以上那种情况，如果我们想要保证回调顺序与初始接口调用顺序保持一致，也还是有办法的。我们可以为此创建一个队列，当每次调用接口启动异步任务的时候，我们可以把调用参数和其它一些上下文参数进队列，而回调则保证按照出队列顺序进行。

也许在很多时候，接口调用方并没有那么苛刻，偶尔的回调乱序并不会带来灾难性的后果。当然前提是接口调用方对此有清醒的认识。这样我们在接口实现上保证回调不发生乱序的做法就没有那么大的必要了。当然，具体怎么选择，还是要看具体应用场景的要求和接口实现者的个人喜好。

#### 闭包形式的回调和Callback Hell

当异步接口的方法数量较少，且回调接口比较简单的时候（回调接口只有一个方法），有时候我们可以用闭包的形式来定义回调接口。在iOS上，可以利用block；在Android上，可以利用内部匿名类（对应Java 8以上的lambda表达式）。

假如之前的DownloadListener简化为只有一个回调方法，如下：

```java
public interface DownloadListener {
    /**
     * 错误码定义
     */
    public static final int SUCCESS = 0;//成功
    //... 其它错误码定义（忽略）

    /**
     * 下载结束回调.
     * @param errorCode 错误码. SUCCESS表示下载成功, 其它错误码表示下载失败.
     * @param url 资源地址.
     * @param localPath 下载后的资源存储位置.
     * @param contextData 上下文数据.
     */
    void downloadFinished(int errorCode, String url, String localPath, Object contextData);
}
```

那么，Downloader接口也能够简化，不再需要一个单独的setListener接口，而是直接在下载接口中接受回调接口。如下：

```java
public interface Downloader {
    /**
     * 启动资源的下载.
     * @param url 要下载的资源地址.
     * @param localPath 资源下载后要存储的本地位置.
     * @param contextData 上下文数据, 在回调接口中会透传回去.可以是任何类型.
     * @param listener 回调接口实例.
     */
    void startDownload(String url, String localPath, Object contextData, DownloadListener listener);
}
```

这样定义的异步接口，好处是调用起来代码比较简洁，回调接口参数(listener)可以传入闭包的形式。但如果嵌套层数过深的话，就会造成Callback Hell ( <http://callbackhell.com>{:target="_blank"} )。试想利用上述Downloader接口来连续下载三个文件，闭包会有三层嵌套，如下：

```java
    final Downloader downloader = new MyDownloader();
    downloader.startDownload(url1, localPathForUrl(url1), null, new DownloadListener() {
        @Override
        public void downloadFinished(int errorCode, String url, String localPath, Object contextData) {
            if (errorCode != DownloadListener.SUCCESS) {
                //...错误处理
            }
            else {
                //下载第二个URL
                downloader.startDownload(url2, localPathForUrl(url2), null, new DownloadListener() {
                    @Override
                    public void downloadFinished(int errorCode, String url, String localPath, Object contextData) {
                        if (errorCode != DownloadListener.SUCCESS) {
                            //...错误处理
                        }
                        else {
                            //下载第三个URL
                            downloader.startDownload(url3, localPathForUrl(url3), null, new DownloadListener(

                            ) {
                                @Override
                                public void downloadFinished(int errorCode, String url, String localPath, Object contextData) {
                                    //...最终结果处理
                                }
                            });
                        }
                    }
                });
            }
        }
    });
```


对于Callback Hell，这篇文章 <http://callbackhell.com>{:target="_blank"} 给出了一些实用的建议，比如，Keep your code shallow和Modularize。另外，有一些基于Reactive Programming的方案，比如ReactiveX（在Android上RxJava已经应用很广泛），经过适当的封装，对于解决Callback Hell有很好的效果。

然而，针对异步任务处理的整个异步编程的问题，ReactiveX之类的方案并不是适用于所有的情况。而且，在大多数情况下，不管是我们读到的别人的代码，还是我们自己产生的代码，面临的都是一些基本的异步编程的场景。需要我们仔细想清楚的主要是逻辑问题，而不是套用某个框架就自然能解决所有问题。

---

大家已经看到，本文用了大部分篇幅在说明一些看起来似乎显而易见的东西，可能略显啰嗦。但如果仔细审查，我们会发现，我们平常所接触到的很多异步接口，都不是我们最想要的理想的形式。我们需要清楚地认识到它们的不足，才能更好地利用它们。因此，我们值得花一些精力对各种情况进行总结和重新审视。

毕竟，定义好的接口需要深厚的功力，工作多年的人也鲜有人做到。而本文也并未教授具体怎样做才能定义出好的接口和回调接口。实际上，没有一种选择是完美无瑕的，我们需要的是取舍。

最后，我们可以试着总结一下评判接口好坏的标准（一个并不严格的标准），我想到了以下几条：

* 逻辑完备（各个接口逻辑不重叠且无遗漏）
* 能自圆其说
* 背后有一个符合常理的抽象模型
* 最重要的：让调用者舒适且能满足需求

（完）

**其它精选文章**：

* [Android和iOS开发中的异步处理（一）——开篇](/posts/blog-series-async-task-1.html)
* [技术的正宗与野路子](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261357&idx=1&sn=ebb11a1623e00ca8e6ad55c9ad6b2547#rd)
* [Android端外推送到底有多烦？](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261350&idx=1&sn=6cea730ef5a144ac243f07019fb43076#rd)
* [用树型模型管理App数字和红点提示](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261255&idx=1&sn=01ab92edada77803fc4ab7a575453d97&scene=19#wechat_redirect)
* [一张图读懂RxJava中的线程控制](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=509777575&idx=1&sn=9ace4885f32a1f274e4be8d839700486&scene=19#wechat_redirect)
* [宇宙尽头的描述符（下）](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261342&idx=1&sn=0adc539ce9b4632aac96a447b7431532#rd)
* [Redis内部数据结构详解(5)——quicklist](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261335&idx=1&sn=053d72a348be2e78040f3847f4092d92&scene=19#wechat_redirect)
* [Redis内部数据结构详解(4)——ziplist](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261265&idx=1&sn=e105c4b86a5640c5fc8212cd824f750b#rd)
* [程序员的宇宙时间线](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261318&idx=1&sn=f7588db0d44a1c1842674d6465ca709e&scene=19#wechat_redirect)
* [Redis内部数据结构详解(1)——dict](http://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261203&idx=1&sn=f7ff61ce42e29b874a8026683875bbb1&scene=19#wechat_redirect)
