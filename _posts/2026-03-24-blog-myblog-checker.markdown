---
layout: post
category: "ml"
title: "使用OpenClaw如何降低token？分享一个浏览器自动化的skill"
date: 2026-03-24 00:00:00 +0800
published: true
---

最近做了大量的AI实验。今天我先分享其中的一个小例子，用来说明在使用OpenClaw这类agent的时候如何大幅地降低token。

<!--more-->

今天讨论的内容分两部分：
* 先介绍一个小例子：如何使用OpenClaw来爬取我的个人博客网站，检查最新的文章发布。
* 总结一下这个思路背后的思想：在构建和运行个人工作流的过程中，模型的自主性和场景要求的确定性这两个因素，如何在时间和空间上进行排布，以能够达到更高的稳定性和更低的token消耗量。

### 自动检查我的博客网站

我们从一个简单的任务开始。任务目标是：检查zhangtielei的博客网站最近更新了哪些文章，做个总结。

解题思路可能有两个。第一个是使用爬虫的思路，写代码模拟用户请求，抓取博客文章，过滤、总结。第二个思路是把这个任务看成一个工作流。第二个思路有更强的通用性，我们按照这个思路来实施。

这个工作流可以分成三步：
1. 访问 https://zhangtielei.com 。
2. 依次点击过去若干天内新发布的每一篇博客文章，查看全文内容。
注意：如果新发布的文章数过多，可能需要翻页。
3. 最后，输出一个简短的总结，告诉我这些新文章大概讲了什么重要内容。

好了，我们可以把这个任务直接丢给OpenClaw让它执行。但是，大家现在都知道OpenClaw是个token粉丝机，token消耗的背后都是真金白银。特别是等各大模型厂商的coding plan优惠活动过了之后，这个问题就会更加严重~~ 而且，如果你想定期重复执行这个任务，它每次执行的效果也不太稳定。

现在我们换另外一个思路：让OpenClaw把这个任务写成脚本来执行。换句话说，使用OpenClaw把这个工作流调教好，然后「固化」成一个程序。为了让脚本生成的过程更顺畅、更准确，我下面会提供一个skill。具体实施步骤如下：

先安装一个skill，用于指导脚本生成：

```shell
npx skills add bitsky-tech/bridgic-browser --skill bridgic-browser
```

然后在OpenClaw的工作区建立一个项目目录：

```shell
mdkir ~/.openclaw/workspace/new-blogs-checker
```

在新建的项目目录下面，创建一个`task.md`文件，把前面的任务描述放进去。`task.md`的内容如下：

```
# 把下面的任务写成Python代码

## 任务目标
检查zhangtielei的博客网站最近更新了哪些文章，做个总结。

## 具体执行步骤
1. 访问 https://zhangtielei.com 。
2. 依次点击过去若干天内新发布的每一篇博客文章，查看全文内容。
注意：如果新发布的文章数过多，可能需要翻页。
3. 最后，输出一个简短的总结，告诉我这些新文章大概讲了什么重要内容。

## 其他要求
 - 检查的时间段请作为生成的可运行程序的一个可选参数。
 - 最后对文章的总结，请使用智谱的最新模型。api key是这个： <your_api_key>
```

`task.md`的内容，基本上前面工作流描述原封不动地放进去，又加了点非功能性需求的描述。

现在让OpenClaw开始干活儿。




### 小结

是不是一个claw就够了呢，显然不是。

为啥coding不是cc啥的
环境 啊什么的，升级啦

特别是在coding plan的活动过了之后，哈哈

bridgic-browser正式沿着这个思路的一个实践。



（正文完）

**其它精选文章**：

* [AI智能体纪元或将从2026开始归零](https://mp.weixin.qq.com/s/h8kS6dpoX2YC771M0nGrAA)
* [基于动态拓扑的Agent编排，原理解析+源码下载](https://mp.weixin.qq.com/s/FNAS-xp1RYAQfZj2nXLSCg)
* [【开源】智能体编程语言ASL——重构智能体开发体验](https://mp.weixin.qq.com/s/D89UVC-0F0AGcjUbkdJjrw)
* [【开源】我亲手开发的一个AI框架，谈下背后的思考](https://mp.weixin.qq.com/s/d2lADFG5m8pZ31v8epUhHQ)
* [一文讲透AI Agent开发中的human-in-the-loop](https://mp.weixin.qq.com/s/fNN32CGANMeAr_wlvhxtWA)
* [AI Agent时代的软件开发范式](https://mp.weixin.qq.com/s/vejqEv5hACcbT15b4Xe5LQ)
* [AI Agent的概念、自主程度和抽象层次](https://mp.weixin.qq.com/s/dJAWleHyOWd8FPqH5ZqDWw)
* [科普一下：拆解LLM背后的概率学原理](https://mp.weixin.qq.com/s/gF-EAVn0sfaPgvHmRLW3Gw)
* [分布式领域最重要的一篇论文，到底讲了什么？](https://mp.weixin.qq.com/s/FZnJLPeTh-bV0amLO5CnoQ)
