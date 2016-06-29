---
layout: post
category: [ios,android]
title: "用树型结构模型来管理App里的数字和红点显示"
date: 2016-06-29 01:30:00 +0800
published: true
---

我们平常接触到的大部分App，在收到新消息的时候一般都会以数字或红点的形式显示出来。比如在微信当中，当某位好友给我们发来新的聊天消息的时候，在相应的会话上就会有一个数字来表示未读消息的数目；再比如当微信朋友圈里有人发布新的内容时，朋友圈的入口就会出现一个红点。

但是，我们在试用一些新的App产品时，总会发现它们在数字和红点展示上存在各种各样的问题。比如，红点怎么点击也清除不掉；或者，发现有数字了，点进去却什么也没有；甚至是提示数字显示在错误的地方。

那这些问题到底是怎样产生的呢？

<!--more-->

我猜测，问题产生的根源是：没有对数字和红点的展示逻辑做一个统一的抽象和管理，以至于各种数字和红点之间的关系错综复杂，牵一发而动全身。这样，在App的维护过程中，稍微有一点改动（比如增加几个数字或红点类型），就会出现问题。这些问题我们以前自然也遇到过。

本文会提出一个树型结构模型，来对数字和红点的层次结构进行统一管理，并会在文章最后给出一个可以运行的Android版的Demo程序，以供参考。

#### 朴素的数字红点管理方式

首先，我们对一般情况下数字和红点展示的需求做一个简单的整理，然后看看根据这样的需求最直观的实现方式可能是怎样的。

* 有些新消息是重要的，需要展示成数字；有些新消息不那么重要，需要展示成红点。比如，我收到了新评论，或收到了新的点赞，以数字表示比较合理；而对于一些系统发给我的系统消息，我希望它不会太干扰到我的视线，这时以比较轻的红点形式展示比较合理。

[<img src="/assets/photos_badge_number_tree/badge_count_screenshot.png" style="width:250px" alt="Badge Count Demo" />](/assets/photos_badge_number_tree/badge_count_screenshot.png)

[<img src="/assets/photos_badge_number_tree/badge_dot_screenshot.png" style="width:250px" alt="Badge Dot Demo" />](/assets/photos_badge_number_tree/badge_dot_screenshot.png)
