---
layout: post
category: [ios,android]
title: "用树型模型来管理App里的数字和红点显示"
date: 2016-06-30 23:50:00 +0800
published: true
---

我们平常接触到的大部分App，在收到新消息的时候一般都会以数字或红点的形式提示出来。比如在微信当中，当某位好友给我们发来新的聊天消息的时候，在相应的会话上就会有一个数字来表示未读消息的数目；再比如当微信朋友圈里有人发布新的内容时，朋友圈的入口就会出现一个红点，而当朋友圈里有人给我们点了赞，或者对我们发布的内容进行了评论的时候，朋友圈的入口就会显示一个数字。

但是，我们在试用一些新的App产品时，总会发现它们在数字和红点展示上存在各种各样的问题。比如，红点怎么点击也清除不掉；或者，发现有数字了，点进去却什么也没有；甚至是提示数字显示在错误的地方。

那这些问题到底是怎样产生的呢？

<!--more-->

我猜测，问题产生的根源是：没有对数字和红点的展示逻辑做一个统一的抽象和管理，以至于各种数字和红点之间的关系错综复杂，牵一发而动全身。这样，在App的维护过程中，稍微有一点改动（比如增加几个数字或红点类型），出现问题的概率就很高。

本文会提出一个树型结构模型，来对数字和红点的层次结构进行统一管理，并会在文章最后给出一个可以运行的Android版的Demo程序，以供参考。

如果您现在手头正好有一部Android手机，那么您可以先扫描下面的二维码（或点击二维码下面的下载链接）下载安装这个Demo，花几分钟看看它是否对您有用。

#### 朴素的数字红点管理方式

为了讨论方便，我们首先对一般情况下数字和红点展示的需求做一个简单的整理，然后看看根据这样的需求最直观的实现方式可能是怎样的。

* 有些新消息是重要的，需要展示成数字；有些新消息不那么重要，需要展示成红点。比如，我收到了新评论，或收到了新的点赞，以数字表示比较合理；而对于一些系统发给我的系统消息，我希望它不会太干扰到我的视线，这时以比较轻的红点形式展示比较合理。
* 数字和红点是需要分级展示的。当有新消息到来时，用户可以从App首页（即第一级页面）出发，根据数字和红点提示，逐级深入到更深的页面，最终到达展示新消息的终端页面。比如在下面的App截图中，当用户收到新评论的时候，首先会在第2个Tab（即“消息”那个Tab）上出现数字提示，引导用户进入第2个Tab页面，然后在页面中“收到的评论”旁边会继续显示数字提示，引导用户点击进入更深一级的评论页面。

[<img src="/assets/photos_badge_number_tree/badge_count_screenshot.png" style="width:250px" alt="Badge Count Demo" />](/assets/photos_badge_number_tree/badge_count_screenshot.png)

* 如果某一级的数字提示，在它更深一级的页面上包含多个数字提示，那么本级数字应该是更深一级页面的数字之和。比如上图中的消息数5=4+1。
* 如果某一级的数字（红点）提示，在它更深一级的页面上既有数字也有红点，那么本级优先按数字展示；如果更深一级的页面上数字都被清掉了，只有红点了，那么本级才按照红点展示。比如下面的App截图中，页面上只有系统消息了，而系统消息是展示红点，所以第2个Tab上也变成红点展示了。

[<img src="/assets/photos_badge_number_tree/badge_dot_screenshot.png" style="width:250px" alt="Badge Dot Demo" />](/assets/photos_badge_number_tree/badge_dot_screenshot.png)

相信以上总结的几点，跟大多数App的展示逻辑大体类似。即使有一些差别，应该也不妨碍我们接下来的讨论。

好，现在我们就以上面App截图中的具体情形来考虑一下实现。“消息”Tab包含“收到的评论”、“收到的赞”和“系统消息”，其中评论和赞是数字，系统消息是红点。

我们单独考虑“消息”这个Tab上的数字红点展示逻辑，不难写出类似如下的代码（伪码）：

{% highlight java linenos %}
int count = 评论数 + 赞数;
if (count > 0) {
	展示数字count
}
else if (有系统消息) {
	展示红点
}
else {
	隐藏数字和红点
}
{% endhighlight %}

这段代码当然能实现需求，但是缺点也是很明显的。其中最关键的是，它要求在“消息”这个Tab上的展示逻辑要列举下面包含的所有子消息类型（评论、赞、系统消息），并且知道每个类型是数字还是红点。上面只是给出了两级页面的情况，如果出现三级页面甚至更多级呢？那么这些信息就要在各级页面上重复一遍。

这会造成维护和修改变得复杂。想象一下，在“消息”下面又增加了一个新的消息类型，或者某个类型的消息从数字展示变成红点展示了，甚至是某个类型的消息，从一个页面栈移动到了另一个页面栈了。所有这些情况，都要求更高层级的所有页面都对应进行修改。当一个App的消息类型越来越多，达到几十个的时候，可以想象这种修改是很容易出错的。


#### 基于树型模型的数字红点管理方式

上面说的问题，我们在[微爱](http://welove520.com){:target="_blank"}App开发的初期也遇到过。后来，我们重新审视了App中红点和数字展示的结构，使用树型结构来看待它，让维护工作变得简单。

一个App的页面本身就是分级的，对于页面的访问路径本质上就是个树型结构。

[<img src="/assets/photos_badge_number_tree/badge_number_tree.png" style="width:400px" alt="Badge Number Tree结构图" />](/assets/photos_badge_number_tree/badge_number_tree.png)

如上图所示，节点1代表第1级页面，这个页面下面包含三个更深一级（第2级）的页面入口，分别对应节点2，3，4。再深一级就到了终端页面，以绿色的方形节点表示。

这个树型的模型可以如下表述：

* 叶子节点（绿色方形的节点）表示最终要展示消息的终端页面。消息在叶子节点上如何展示，是产品设计的时候就定好的。比如，它可以直接把消息展示出来，或者先展示一个数字，点进去再展示消息内容（就像前面App截图中的评论数提示），也或者可以弹框来提示。总之，它的展示样式是固化在产品业务的代码中的。
* 中间节点（圆形的橙色节点）表示从第1级页面到达消息终端页面访问路径上的页面。中间节点上的展示一般就是数字或红点。
* 每一个消息类型，我们称为一个Badge Number。它具有三个属性：
  * type: Badge Number类型。
  * count: 计数，对于每个Badge Number，每个用户一个计数。
  * displayMode: 当前badge number在父节点上的显示方式。0表示红点，1表示数字。
* Badge Number根据所属业务类型的不同，分属不同的大类（Category）。每个大类内的Badge Number类型type分配在同一个类型区间内。比如上面树型结构图中2，3，4节点就分别对应三个业务类型，也就是三个大类，它们对应的类型区间分别为[A, C], [X, Y], [R, T]。再举一个实际的例子，比如微信朋友圈是一个业务大类，里面的Badge Number类型包括：有人评论我（数字），有人给我点赞（数字），好友有新消息发布（红点），等。

为了使得一个大类内的Badge Number能用一个类型区间来表达，我们在为类型分配值的时候，可以采取类似这样的方式：用一个int来表示Badge Number类型，而它的高16位用来表示大类。比如“消息”大类高16位是0x2的话，那么它包含的三种Badge Number类型（type）就可以这样分配：

* 收到的评论：(0x2 << 16) + 0x1
* 收到的赞：(0x2 << 16) + 0x2
* 系统消息：(0x2 << 16) + 0x3

这样，“消息”这一大类就可以用一个类型区间[(0x2 << 16) + 0x1, (0x2 << 16) + 0x3]来表达。

有了类型区间之后，我们重新看一下树型模型里面的中间节点。它们都可以用一个或多个类型区间来表示。它们的展示逻辑（是展示成数字，还是红点，还是隐藏），需要对所有子树的类型区间求和。具体求和过程是：

* 先对所有类型区间里的数字类型进行求和，如果大于0，则展示数字；否则，
* 对所有类型区间里的红点类型进行求和，如果大于0，则展示红点；否则，
* 隐藏数字和红点。

#### 树型模型的代码实现

树型模型的实现，我们称为Badge Number Tree，本文提供了一个Android版的Demo实现，源码可以从GitHub下载：<https://github.com/tielei/BadgeNumberTree>{:target="_blank"} 。

下面我们把关键部分分析一下。

Android版本的主要实现类为BadgeNumberTreeManager，它的关键代码如下（为了不影响我们理解主要逻辑，非关键代码在下面忽略了，没有贴出。如需查看请到GitHub下载源代码）：

{% highlight java linenos %}
/**
 * 用于异步返回结果的接口.
 */
public interface AsyncResult<ResultType> {
    void returnResult(ResultType result);
}

/**
 * 树型结构的badge number管理器.
 */
public class BadgeNumberTreeManager {
    /**
     * 设置badge number
     * @param badgeNumber
     * @param asyncResult 异步返回结果, 会返回一个Boolean参数, 表示是否设置成功了.
     */
    public void setBadgeNumber(final BadgeNumber badgeNumber, final AsyncResult<Boolean> asyncResult) {
        ...
    }

    /**
     * 累加badge number
     * @param badgeNumber
     * @param asyncResult 异步返回结果, 会返回一个Boolean参数, 表示是否累加操作成功了.
     */
    public void addBadgeNumber(final BadgeNumber badgeNumber, final AsyncResult<Boolean> asyncResult) {
        ...
    }

    /**
     * 删除指定类型的badge number
     * @param type 指定的badge number类型.
     * @param asyncResult 异步返回结果, 会返回一个Boolean参数, 表示是否删除成功了.
     */
    public void clearBadgeNumber(final int type, final AsyncResult<Boolean> asyncResult) {
        ...
    }

    /**
     * 获取指定类型的badge number
     * @param type 类型。取聊天的badge number时，传0即可。
     * @param asyncResult 异步返回结果, 会返回指定类型的badge number的count数.
     */
    public void getBadgeNumber(final int type, final AsyncResult<Integer> asyncResult) {
        ...
    }

    /**
     * 根据一个类型区间列表计算一个树型父节点总的badge number。
     * 优先计算数字，其次计算红点。
     *
     * 一个类型区间列表在实际中对应一个树型父节点。
     *
     * @param typeIntervalList 指定的badge number类型区间列表, 至少有1一个区间
     * @param asyncResult 异步返回结果, 会返回指定类型的badge number的情况(包括显示方式和总数).
     */
    public void getTotalBadgeNumberOnParent(final List<BadgeNumberTypeInterval> typeIntervalList, final AsyncResult<BadgeNumberCountResult> asyncResult) {
        //先计算显示数字的badge number类型
        getTotalBadgeNumberOnParent(typeIntervalList, BadgeNumber.DISPLAY_MODE_ON_PARENT_NUMBER, new AsyncResult<BadgeNumberCountResult>() {
            @Override
            public void returnResult(BadgeNumberCountResult result) {
                if (result.getTotalCount() > 0) {
                    //数字类型总数大于0，可以返回了。
                    if (asyncResult != null) {
                        asyncResult.returnResult(result);
                    }
                }
                else {
                    //数字类型总数不大于0，继续计算红点类型
                    getTotalBadgeNumberOnParent(typeIntervalList, BadgeNumber.DISPLAY_MODE_ON_PARENT_DOT, new AsyncResult<BadgeNumberCountResult>() {
                        @Override
                        public void returnResult(BadgeNumberCountResult result) {
                            if (asyncResult != null) {
                                asyncResult.returnResult(result);
                            }
                        }
                    });
                }
            }
        });
    }


    private void getTotalBadgeNumberOnParent(final List<BadgeNumberTypeInterval> typeIntervalList, final int displayMode, final AsyncResult<BadgeNumberCountResult> asyncResult) {
        final List<Integer> countsList = new ArrayList<Integer>(typeIntervalList.size());
        for (BadgeNumberTypeInterval typeInterval : typeIntervalList) {
            getBadgeNumber(typeInterval.getTypeMin(), typeInterval.getTypeMax(), displayMode, new AsyncResult<Integer>() {
                @Override
                public void returnResult(Integer result) {
                    countsList.add(result);
                    if (countsList.size() == typeIntervalList.size()) {
                        //类型区间的count都有了
                        int totalCount = 0;
                        for (Integer count : countsList) {
                            if (count != null) {
                                totalCount += count;
                            }
                        }

                        //返回总数
                        if (asyncResult != null) {
                            BadgeNumberCountResult badgeNumberCountResult = new BadgeNumberCountResult();
                            badgeNumberCountResult.setDisplayMode(displayMode);
                            badgeNumberCountResult.setTotalCount(totalCount);
                            asyncResult.returnResult(badgeNumberCountResult);
                        }
                    }
                }
            });
        }
    }

    private void getBadgeNumber(final int typeMin, final int typeMax, final int displayMode, final AsyncResult<Integer> asyncResult) {
         ...
   }


    /**
     * badge number类型区间。
     */
    public static class BadgeNumberTypeInterval {
        private int typeMin;
        private int typeMax;

        public int getTypeMin() {
            return typeMin;
        }

        public void setTypeMin(int typeMin) {
            this.typeMin = typeMin;
        }

        public int getTypeMax() {
            return typeMax;
        }

        public void setTypeMax(int typeMax) {
            this.typeMax = typeMax;
        }
    }

    /**
     * badge number按照一个类型区间计数后的结果。
     */
    public static class BadgeNumberCountResult {
        private int displayMode;
        private int totalCount;

        public int getDisplayMode() {
            return displayMode;
        }

        public void setDisplayMode(int displayMode) {
            this.displayMode = displayMode;
        }

        public int getTotalCount() {
            return totalCount;
        }

        public void setTotalCount(int totalCount) {
            this.totalCount = totalCount;
        }
    }
    
}
{% endhighlight %}

在这段代码中我们需要注意的点包括：

* 前面对于Badge Number的增删改查4个操作——setBadgeNumber、addBadgeNumber、clearBadgeNumber、getBadgeNumber，它们都比较简单，实现代码这里没有贴出来。实际上在Demo中，是基于SQLite本地存储来实现的。我们需要注意的是各个操作的应用场景：
  * setBadgeNumber用于一般的新消息提醒，在新消息提醒产生时被调用，将Badge Number存入本地。这些Badge Number中的count值由服务器来维护，所以以服务器为准，每次从服务器获取到之后，就调动setBadgeNumber覆盖本地的值。
  * addBadgeNumber用于本地累加计数的消息提醒，比如聊天消息。一个用户接收的新聊天消息是依靠本地计数的，因此使用addBadgeNumber累加计数。
  * clearBadgeNumber用于清除指定类型的Badge Number。通常来说，当用户在消息终端页面（树型的叶子节点）上阅读完新消息后，需要清除Badge Number。
  * getBadgeNumber，根据指定类型获取Badge Number的值，用于在消息终端页面（树型的叶子节点）上展示消息的时候调用。
* 最后有一个private的getBadgeNumber方法，它和前面public的重载方法不同，它不是取指定的某一个类型的Badge Number，而是取一个类型区间[typeMin, typeMax]里的指定显示方式（displayMode）的Badge Number总数。这个方法是实现中间节点上Badge Number展示逻辑的基础。这里的实现代码也没有贴出来，它的实现其实也比较简单，在Demo中是基于SQLite做的一个求和（sum）操作来实现的。
* public的getTotalBadgeNumberOnParent是一个关键的方法，它用于实现中间节点上Badge Number展示逻辑。输入的typeIntervalList参数是一个类型区间的列表，对应一个中间节点。它的异步输出参数是一个BadgeNumberCountResult对象，可以表达三种展示结果：数字、红点、隐藏（无显示）。这个方法的实现是调用了它的另一个私有重载方法，先后对类型区间列表上的数字类型和红点类型分别进行求和（这就是前面讲的对中间节点所有子树类型区间求和的实现）。

调用getTotalBadgeNumberOnParent的代码例子如下：

{% highlight java linenos %}
    BadgeNumberTypeInterval typeInterval = new BadgeNumberTypeInterval();
    typeInterval.setTypeMin(BadgeNumber.CATEGORY_NEWS_MIN);
    typeInterval.setTypeMax(BadgeNumber.CATEGORY_NEWS_MAX);

    List<BadgeNumberTypeInterval> typeIntervalList = new ArrayList<BadgeNumberTypeInterval>(1);
    typeIntervalList.add(typeInterval);

    BadgeNumberTreeManager.getInstance().getTotalBadgeNumberOnParent(typeIntervalList, new AsyncResult<BadgeNumberCountResult>() {
        @Override
        public void returnResult(BadgeNumberCountResult result) {
            if (result.getDisplayMode() == BadgeNumber.DISPLAY_MODE_ON_PARENT_NUMBER && result.getTotalCount() > 0) {
                //展示数字
                showTabBadgeCount(tabIndex, result.getTotalCount());
            } else if (result.getDisplayMode() == BadgeNumber.DISPLAY_MODE_ON_PARENT_DOT && result.getTotalCount() > 0) {
                //展示红点
                showTabBadgeDot(tabIndex);
            } else {
                //隐藏数字和红点
                hideTabBadgeNumber(tabIndex);
            }
        }
    });
{% endhighlight %}

#### 关于实现上的一些补充说明

* 在Demo程序中，BadgeNumberTreeManager的底层存储使用的是SQLite。但是，由于BadgeNumberTreeManager的接口调用很频繁，因此在实现中还加入了中间一级内存缓存（详见GitHub代码）。
* 客户端通过某种方式获取到新的Badge Number后，将它存入本地（通过BadgeNumberTreeManager的setBadgeNumber和addBadgeNumber接口）。而客户端获取Badge Number的方式可能有多种，比如通过长连接推送到客户端（App自己实现的长连接，或者第三方平台的长连接），或者通过HTTP服务拉取得到（这种方式适用于实时性不强的新提示）。
* 中间节点Badge Number的展示刷新逻辑（即调用BadgeNumberTreeManager的getTotalBadgeNumberOnParent接口），需要在必需的所有时机执行。以本文给出的Android版Demo为例，这些时机包括：页面onResume的时候，子Tab切换的时候，获取到新的Badge Number的时候。展示刷新逻辑执行的时机不精确，或者有遗漏，也是App数字红点展示出现问题的一个常见原因。
* 中间节点Badge Number的清除，常见的有两种情况：（1）所有子节点都清除了它才清除；（2）只要点击了就清除，而不管子节点是否都清除了。本文给出的Demo是按前一种情况实现的。如果想实现后一种情况，需要为每个中间节点再单独记录一个标记，但这个改动并不大。
* 虽然本文给出的代码示例是基于Android Java的，但本文给出的树型模型，也可以用于非Android Java版本的App实现。
