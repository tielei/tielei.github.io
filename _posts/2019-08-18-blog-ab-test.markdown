---
layout: post
category: "other"
title: "科学精神与A/B实验"
date: 2019-08-18 00:00:00 +0800
published: true
---

我们先讲两个历史上真实发生过的小故事。

第一个故事是关于黄热病。

黄热病是一种严重的传染病，曾在1793年袭击美国费城。当时，费城有一位著名的人物，他叫本杰明·拉什[1]。拉什曾经签署过《独立宣言》，是美国的开国元勋之一。同时，他还是著名的教育家和出色的外科医生。在费城的黄热病爆发的时候，他坚信放血疗法可以治疗这种疾病。于是，他用手术刀或水蛭吸血的办法给病人放血。当拉什自己染上这种疾病的时候，他也采用同样的方法给自己治疗。

<!--more-->

第二个故事是关于坏血病。

坏血病在历史上曾是严重威胁人类健康的一种疾病，尤其在远洋航行的水手中尤为严重。在18世纪，一位英国船长发现，在一些地中海国家的海军舰艇上服役的船员没有坏血病。他注意到，这些船员的食物配给中含有柑橘类(citrus)水果。于是，为了弄清真正的原因，这位船长将他的船员们分为两组：其中一组在日常饮食中加入酸橙(limes)，而另外一组维持原来的食谱不变。结果通过对比发现，定期食用酸橙的一组船员，真的防止了坏血病的发生。后来，定期食用柑橘类水果就变成了英国水手必须遵循的一种规定。这种做法越来越普遍，以至于在后来的美国英语中产生了一个新的词汇——limeys，用来代指任何一个英国人。这个词翻译成中文称为「英国佬」。

现在让我们来比较一下这两个故事有什么不同。

在第一个故事中，本杰明·拉什坚信他的放血疗法可以治疗黄热病。实际上，他确实「治」好了一些病人。当然，也有一些病人死掉了。事情的解释就演变成这样：如果病人情况好转，那么就被作为放血疗法有效的证据；反之，如果病人死掉了，拉什就解释说是病情太严重，已经无药可救了。后来，有评论家指出，他的疗法甚至比疾病本身更加危险。

而在第二个故事中，船长将船员分成了两组，进行了**对照实验** (controlled experiment)。现代医学已经证实，这位船长通过对照实验得到的结论确实是有效的。坏血病的致病原因是由于缺乏维生素C，而柑橘类水果中含有大量的维生素C。

在这两个故事中，当事人都试图在寻找事物之间的一种**因果关系**(causal relationship)。本杰明·拉什相信放血疗法和治愈黄热病之间存在因果关系；而第二个故事中的船长则发现了食用酸橙和防止坏血病之间的因果关系。那为什么拉什没有找到真正的因果关系，而那位英国船长找到了？关键就在于对照实验。

进一步追问，为什么使用对照实验就能得到真正的因果关系？这本质上是一个哲学问题，涉及到科学之所以成为科学的本质原因。但我们先不过早地进入哲学讨论的范畴，而是先采取务实的态度，跟大家讨论一下关于如何进行对照实验的各种技术。

在程序开发的领域，对照实验，也可以称为A/B实验。实际上，在不同的场合，它至少有半打以上不同的名字。下面的列表列出了这些名字：

* Controlled experiments (对照实验)
* Randomized experiments (随机实验)
* A/B tests (A/B测试，A/B实验)
* Split tests
* Control/Treatment tests
* MultiVariable Tests (MVT)
* Parallel flights

### 互联网业务开发中的A/B实验


一层中是否只有一个实验？















（正文完）

##### 参考文献：

* [1] <https://en.wikipedia.org/wiki/Benjamin_Rush>{:target="_blank"}
* [2] <https://en.wikipedia.org/wiki/Limey>{:target="_blank"}

**其它精选文章**：

* [万物有灵之精灵之恋](https://mp.weixin.qq.com/s/TqpkiSWHSmhY0RIG_sKCQA)
* [漫谈业务与平台](https://mp.weixin.qq.com/s/gPE2XTqTHaN8Bg7NnfOoBw)
* [漫谈分布式系统、拜占庭将军问题与区块链](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261626&idx=1&sn=6b32cc7a7a62bee303a8d1c4952d9031&chksm=844791e3b33018f595efabf6edbaa257dc6c5f7fe705e417b6fb7ac81cd94e48d384a694640f#rd)
* [光年之外的世界](https://mp.weixin.qq.com/s/zUgMSqI8QhhrQ_sy_zhzKg)
* [技术的正宗与野路子](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261357&idx=1&sn=ebb11a1623e00ca8e6ad55c9ad6b2547#rd)
* [三个字节的历险](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261541&idx=1&sn=2f1ea200389d82e7340a5b4103968d7f&chksm=84479e3cb330172a6b2285d4199822143ad05ef8e8c878b98d4ee4f857664c3d15f54e0aab50#rd)
* [做技术的五比一原则](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261555&idx=1&sn=3662a2635ecf6f67185abfd697b1057c&chksm=84479e2ab330173cebe16826942b034daec79ded13ee4c03003d7bef262d4969ef0ffb1a0cfb#rd)
* [知识的三个层次](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261491&idx=1&sn=cff9bcc4d4cc8c5e642309f7ac1dd5b3&chksm=84479e6ab330177c51bbf8178edc0a6f0a1d56bbeb997ab1cf07d5489336aa59748dea1b3bbc#rd)