---
layout: post
category: [ios,android]
title: "iOS和Android开发中的异步处理（三）——执行多个异步任务"
date: 2016-05-18 23:30:00 +0800
published: true
---

本文是笔者的系列文章《[iOS和Android开发中的异步处理](/posts/blog-series-async-task-1.html)》的第三篇。在本篇文章中，我们主要讨论在执行多个异步任务的时候可能碰到的相关问题。

通常我们都需要执行多个异步任务，使它们相互协作来完成需求。本文结合典型的应用场景，讲解异步任务的三种协作关系：

* 先后接续执行
* 并发执行，全部完成
* 并发执行，优先完成

<!--more-->

以上三种协作关系，本文分别以三种应用场景为例展开讨论。这三种应用场景分别是：

* 多级缓存
* 并发网络请求
* 页面缓存

最后，本文还会尝试给出一个使用RxJava这样的框架来实现“并发网络请求”的案例，并进行相关的探讨。

---

#### 多个异步任务先后接续执行

“先后接续执行”指的是一个异步任务先启动执行，待执行完成结果回调发生后，再启动下一个异步任务。这是多个异步任务最简单的一种协作方式。

一个典型的例子是静态资源的多级缓存，其中最为大家所喜闻乐见的例子就是静态图片的多级缓存。通常在客户端加载一个静态图片，都会至少有两级缓存：第一级Memory Cache和第二级Disk Cache。整个加载流程如下：

1. 先查找Memory Cache，如果命中，则直接返回；否则，执行下一步
2. 再查找Disk Cache，如果命中，则直接返回；否则，执行下一步
3. 发起网络请求，下载和解码图片文件。

通常，第1步查找Memory Cache是一个同步任务。而第2步和第3步都是异步任务，对于同一个图片加载任务来说，这两步之间便是“先后接续执行”的关系：“查找Disk Cache”的异步任务完成后（发生结果回调），根据缓存命中结果再决定要不要启动“发起网络请求”
的异步任务。

下面我们就用代码展示一下“查找Disk Cache”和“发起网络请求”这两个异步任务的启动和执行情况。

首先，我们需要先定义好“Disk Cache”和“网络请求”两个异步任务的接口。

{% highlight java linenos %}
public interface ImageDiskCache {
    /**
     * 异步获取缓存的Bitmap对象.
     * @param key
     * @param callback 用于返回缓存的Bitmap对象
     */
    void getImage(String key, AsyncCallback<Bitmap> callback);
    /**
     * 保存Bitmap对象到缓存中.
     * @param key
     * @param bitmap 要保存的Bitmap对象
     * @param callback 用于返回当前保存操作的结果是成功还是失败.
     */
    void putImage(String key, Bitmap bitmap, AsyncCallback<Boolean> callback);
}
{% endhighlight %}

ImageDiskCache用于存取图片的Disk Cache，其中参数中的AsyncCallback，是一个通用的异步回调接口的定义。其定义代码如下（本文后面还会用到）：

{% highlight java linenos %}
/**
 * 一个通用的回调接口定义. 用于返回一个参数.
 * @param <D> 异步接口返回的参数数据类型.
 */
public interface AsyncCallback <D> {
    void onResult(D data);
}
{% endhighlight %}

而发起网络请求下载图片文件，我们直接调用上一篇文章《[iOS和Android开发中的异步处理（二）——异步任务的回调](/posts/blog-series-async-task-2.html)》中介绍的Downloader接口（注：采用最后带有contextData参数的那一版本的Dowanloder接口）。

这样，查询“查找Disk Cache”和“发起网络下载请求”的代码示例如下：

{% highlight java linenos %}
    //检查二级缓存: disk cache
    imageDiskCache.getImage(url, new AsyncCallback<Bitmap>() {
        @Override
        public void onResult(Bitmap bitmap) {
            if (bitmap != null) {
                //disk cache命中, 加载任务提前结束.
                imageMemCache.putImage(url, bitmap);
                successCallback(url, bitmap, contextData);
            }
            else {
                //两级缓存都没有命中, 调用下载器去下载
                downloader.startDownload(url, getLocalPath(url), contextData);
            }
        }
    });
{% endhighlight %}

Downloader的成功结果回调的实现代码示例如下：

{% highlight java linenos %}
    @Override
    public void downloadSuccess(final String url, final String localPath, final Object contextData) {
        //解码图片, 是个耗时操作, 异步来做
        imageDecodingExecutor.execute(new Runnable() {
            @Override
            public void run() {
                Bitmap bitmap = decodeBitmap(new File(localPath));
                if (bitmap != null) {
                    imageMemCache.putImage(url, bitmap);
                    imageDiskCache.putImage(url, bitmap, null);
                    successCallback(url, bitmap, contextData);
                }
                else {
                    //解码失败
                    failureCallback(url, ImageLoaderListener.BITMAP_DECODE_FAILED, contextData);
                }
            }
        });
    }
{% endhighlight %}

#### 多个异步任务并发执行，全部完成

“并发执行，全部完成”，指的是同时启动多个异步任务，它们同时并发地执行，等到它们全部执行完成的时候，再收集所有执行结果一起做后续处理。

一个典型的例子是，同时发起多个网络请求（即远程API接口），等获得所有请求的返回数据之后，再将数据一并处理，更新UI。这样的做法通过并发网络请求缩短了总的请求时间。

我们根据最简单的两个并发网络请求的情况来给出示例代码。

首先，还是要先定义好需要的异步接口，即远程API接口的定义。

{% highlight java linenos %}
/**
 * Http服务请求接口.
 */
public interface HttpService {
    /**
     * 发起HTTP请求.
     * @param apiUrl 请求URL
     * @param request 请求参数(用Java Bean表示)
     * @param listener 回调监听器
     * @param contextData 透传参数
     * @param <T> 请求Model类型
     * @param <R> 响应Model类型
     */
    <T, R> void doRequest(String apiUrl, T request, HttpListener<? super T, R> listener, Object contextData);
}

/**
 * 监听Http服务的监听器接口.
 *
 * @param <T> 请求Model类型
 * @param <R> 响应Model类型
 */
public interface HttpListener <T, R> {
    /**
     * 产生请求结果(成功或失败)时的回调接口.
     * @param apiUrl 请求URL
     * @param request 请求Model
     * @param result 请求结果(包括响应或者错误原因)
     * @param contextData 透传参数
     */
    void onResult(String apiUrl, T request, HttpResult<R> result, Object contextData);
}
{% endhighlight %}

需要注意的是： 在HttpService这个接口定义中，请求参数request使用Generic类型T来定义。如果这个接口有一个实现，那么在实现代码中应该会根据实际传入的request的类型（它可以是任意Java Bean），利用反射机制将其变换成Http请求参数。当然，我们在这里只讨论接口，具体实现不是这里要讨论的重点。

而返回结果参数result，是HttpResult类型，这是为了让它既能表达成功的响应结果，也能表达失败的响应结果。HttpResult的定义代码如下：

{% highlight java linenos %}
/**
 * HttpResult封装Http请求的结果.
 *
 * 当服务器成功响应的时候, errorCode = SUCCESS, 且服务器的响应转换成response;
 * 当服务器未能成功响应的时候, errorCode != SUCCESS, 且response的值无效.
 *
 * @param <R> 响应Model类型
 */
public class HttpResult <R> {
    /**
     * 错误码定义
     */
    public static final int SUCCESS = 0;//成功
    public static final int REQUEST_ENCODING_ERROR = 1;//对请求进行编码发生错误
    public static final int RESPONSE_DECODING_ERROR = 2;//对响应进行解码发生错误
    public static final int NETWORK_UNAVAILABLE = 3;//网络不可用
    public static final int UNKNOWN_HOST = 4;//域名解析失败
    public static final int CONNECT_TIMEOUT = 5;//连接超时
    public static final int HTTP_STATUS_NOT_OK = 6;//下载请求返回非200
    public static final int UNKNOWN_FAILED = 7;//其它未知错误

    private int errorCode;
    private String errorMessage;
    /**
     * response是服务器返回的响应.
     * 只有当errorCode = SUCCESS, response的值才有效.
     */
    private R response;

    public int getErrorCode() {
        return errorCode;
    }

    public void setErrorCode(int errorCode) {
        this.errorCode = errorCode;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    public R getResponse() {
        return response;
    }

    public void setResponse(R response) {
        this.response = response;
    }
}
{% endhighlight %}

HttpResult也包含一个Generic类型R，它就是请求成功时返回的响应参数类型。同样，在HttpService可能的实现中，应该会再次利用反射机制将请求返回的响应内容（可能是个Json串）变换成类型R（它可以是任意Java Bean）。

好了，现在有了HttpService接口，我们便能演示如何同时发送两个网络请求了。

{% highlight java linenos %}
public class MultiRequestsDemoActivity extends AppCompatActivity {
    private HttpService httpService = new MockHttpService();
    /**
     * 缓存各个请求结果的Map
     */
    private Map<String, Object> httpResults = new HashMap<String, Object>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_multi_requests_demo);

        //同时发起两个异步请求
        httpService.doRequest("http://...", new HttpRequest1(),
                new HttpListener<HttpRequest1, HttpResponse1>() {
                    @Override
                    public void onResult(String apiUrl,
                                         HttpRequest1 request,
                                         HttpResult<HttpResponse1> result,
                                         Object contextData) {
                        //将请求结果缓存下来
                        httpResults.put("request-1", result);
                        if (checkAllHttpResultsReady()) {
                            //两个请求都已经结束
                            HttpResult<HttpResponse1> result1 = result;
                            HttpResult<HttpResponse2> result2 = (HttpResult<HttpResponse2>) httpResults.get("request-2");
                            if (checkAllHttpResultsSuccess()) {
                                //两个请求都成功了
                                processData(result1.getResponse(), result2.getResponse());
                            }
                            else {
                                //两个请求并未完全成功, 按失败处理
                                processError(result1.getErrorCode(), result2.getErrorCode());
                            }
                        }
                    }
                },
                null);
        httpService.doRequest("http://...", new HttpRequest2(),
                new HttpListener<HttpRequest2, HttpResponse2>() {
                    @Override
                    public void onResult(String apiUrl,
                                         HttpRequest2 request,
                                         HttpResult<HttpResponse2> result,
                                         Object contextData) {
                        //将请求结果缓存下来
                        httpResults.put("request-2", result);
                        if (checkAllHttpResultsReady()) {
                            //两个请求都已经结束
                            HttpResult<HttpResponse1> result1 = (HttpResult<HttpResponse1>) httpResults.get("request-1");
                            HttpResult<HttpResponse2> result2 = result;
                            if (checkAllHttpResultsSuccess()) {
                                //两个请求都成功了
                                processData(result1.getResponse(), result2.getResponse());
                            }
                            else {
                                //两个请求并未完全成功, 按失败处理
                                processError(result1.getErrorCode(), result2.getErrorCode());
                            }
                        }
                    }
                },
                null);
    }

    /**
     * 检查是否所有请求都有结果了
     * @return
     */
    private boolean checkAllHttpResultsReady() {
        int requestsCount = 2;
        for (int i = 1; i <= requestsCount; i++) {
            if (httpResults.get("request-" + i) == null) {
                return false;
            }
        }
        return true;
    }

    /**
     * 检查是否所有请求都成功了
     * @return
     */
    private boolean checkAllHttpResultsSuccess() {
        int requestsCount = 2;
        for (int i = 1; i <= requestsCount; i++) {
            HttpResult<?> result = (HttpResult<?>) httpResults.get("request-" + i);
            if (result == null || result.getErrorCode() != HttpResult.SUCCESS) {
                return false;
            }
        }
        return true;
    }

    private void processData(HttpResponse1 data1, HttpResponse2 data2) {
        //TODO: 更新UI, 展示请求结果. 省略此处代码
    }

    private void processError(int errorCode1, int errorCode2) {
        //TODO: 更新UI,展示错误. 省略此处代码
    }
}
{% endhighlight %}

为了判断两个异步请求是否“全部完成”，我们需要在任一个请求回调时都去判断所有请求是否已经返回。这里需要注意的是，之所以我们能采取这样的判断方法，有一个很重要的前提：HttpService的onResult已经调度到主线程执行。我们在上一篇文章《[iOS和Android开发中的异步处理（二）——异步任务的回调](/posts/blog-series-async-task-2.html)》中“回调的线程模型”一节，对回调发生的线程环境已经进行过讨论。在onResult已经调度到主线程执行的前提下，两个请求的onResult回调顺序只能有两种情况：先执行第一个请求的onResult再执行第二个请求的onResult；或者先执行第二个请求的onResult再执行第一个请求的onResult。不管是哪种顺序，上面代码中onResult内部的判断都是有效的。

然而，如果HttpService的onResult在不同的线程上执行，那么两个请求的onResult回调就可能交叉执行，那么里面的各种判断也会有同步问题。

相比前面讲过的“先后接续执行”，这里的并发执行显然带来了不小的复杂度。如果不是对并发带来的性能提升有特别强烈的需求，也许我们更愿意选择“先后接续执行”的协作关系，让代码逻辑保持简单易懂。

#### 多个异步任务并发执行，优先完成

“并发执行，优先完成”，指的是同时启动多个异步任务，它们同时并发地执行，但不同的任务却有不同的优先级，任务执行结束时，优先采用优先级高的任务返回的结果。如果优先级高的任务先执行结束了，那么后执行完的低优先级任务就被忽略；如果优先级低的任务先执行结束了，那么后执行完的高优先级任务的返回结果就覆盖之前优先级低任务返回的结果。

一个典型的例子是页面缓存。比如，一个页面要显示一份动态的列表数据。如果每次页面打开时都从服务器取列表数据，那么碰到没有网络或者网络比较慢的情况，页面会长时间空白。这时通常显示一份旧的数据，比什么都不显示要好。因此，我们可能会考虑给这份列表数据增加一个本地持久化的缓存。

本地缓存也是一个异步任务，代码定义如下：

{% highlight java linenos %}
public interface LocalDataCache {
    /**
     * 异步获取本地缓存的HttpResponse对象.
     * @param key
     * @param callback 用于返回缓存对象
     */
    void getCachingData(String key, AsyncCallback<HttpResponse> callback);

    /**
     * 保存HttpResponse对象到缓存中.
     * @param key
     * @param data 要保存的HttpResponse对象
     * @param callback 用于返回当前保存操作的结果是成功还是失败.
     */
    void putCachingData(String key, HttpResponse data, AsyncCallback<Boolean> callback);
}
{% endhighlight %}

这个本地缓存所缓存的数据对象，就是之前从服务器取到的一个HttpResponse对象。异步回调接口AsyncCallback，我们在前面已经讲过。

这样，当页面打开时，我们可以同时启动本地缓存读取任务和远程API请求的任务。其中后者比前者的优先级高。

{% highlight java linenos %}
public class PageCachingDemoActivity extends AppCompatActivity {
    private HttpService httpService = new MockHttpService();
    private LocalDataCache localDataCache = new MockLocalDataCache();
    /**
     * 从Http请求到的数据是否已经返回
     */
    private boolean dataFromHttpReady;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_page_caching_demo);

        //同时发起本地数据请求和远程Http请求
        final String userId = "xxx";
        localDataCache.getCachingData(userId, new AsyncCallback<HttpResponse>() {
            @Override
            public void onResult(HttpResponse data) {
                if (data != null && !dataFromHttpReady) {
                    //缓存有旧数据 & 远程Http请求还没返回,先显示旧数据
                    processData(data);
                }
            }
        });
        httpService.doRequest("http://...", new HttpRequest(),
                new HttpListener<HttpRequest, HttpResponse>() {
                    @Override
                    public void onResult(String apiUrl,
                                         HttpRequest request,
                                         HttpResult<HttpResponse> result,
                                         Object contextData) {
                        if (result.getErrorCode() == HttpResult.SUCCESS) {
                            dataFromHttpReady = true;
                            processData(result.getResponse());
                            //从Http拉到最新数据, 更新本地缓存
                            localDataCache.putCachingData(userId, result.getResponse(), null);
                        }
                        else {
                            processError(result.getErrorCode());
                        }
                    }
                },
                null);
    }


    private void processData(HttpResponse data) {
        //TODO: 更新UI, 展示数据. 省略此处代码
    }

    private void processError(int errorCode) {
        //TODO: 更新UI,展示错误. 省略此处代码
    }
}
{% endhighlight %}

虽然读取本地缓存数据通常来说比从网络获取数据要快得多，但既然都是异步接口，就存在一种逻辑上的可能性：网络获取数据先于本地缓存数据发生回调。而且，我们在上一篇文章《[iOS和Android开发中的异步处理（二）——异步任务的回调](/posts/blog-series-async-task-2.html)》中“回调顺序”一节提到的“提前的失败结果回调”和“提前的成功结果回调”，为这种情况的发生提供了更为现实的依据。

在上面的代码中，如果网络获取数据先于本地缓存数据回调了，那么我们会记录一个标记dataFromHttpReady。等到获取本地缓存数据的任务完成时，我们判断这个标记，从而忽略缓存数据。

单独对于页面缓存这个例子，由于通常来说读取本地缓存数据和从网络获取数据所需要的执行时间相差悬殊，所以这里的“并发执行，优先完成”的做法对性能提升并不明显。这意味着，如果我们把页面缓存的这个例子改为“先后接续执行”的实现方式，可能会在没有损失太多性能的前提下，获得代码逻辑的简单易懂。

当然，如果你决意要采用本节的“并发执行，优先完成”的异步任务协作关系，那么一定要记得考虑到异步任务回调的所有可能的执行顺序。

#### 使用RxJava merge来实现并发网络请求

到目前为止，

