---
layout: post
category: "android"
title: "OpenGL ES和坐标变换（二）"
date: 2017-09-18 00:00:01 +0800
published: true
---

本文是《[OpenGL ES和坐标变换](/posts/blog-opengl-transformations-1.html)》系列文章的第二篇。在本文中，我们将集中讨论以下内容：

1. 首先，以Demo程序中的代码为例，介绍model、view、projection三个变换在Android中如何用代码来表达。
2. 介绍相关理论，推导一下model变换中的缩放(scaling)和平移(translation)这两个变换的计算过程。由于旋转(rotation)这个话题比较复杂，我们留在下一篇再讨论。
3. 我们分析一下Android中的缩放(scaling)和平移(translation)变换的具体实现，将前面的理论推导同代码实现相互印证，以加深理解。

<!--more-->

### Demo程序简介

[上一篇](/posts/blog-opengl-transformations-1.html)已经给出了Demo程序的地址，为了明确，这里把地址再贴一遍。本文中出现的代码，都来自于下面这个文件：

* <https://github.com/tielei/OpenGLESTransformationsDemo/blob/master/app/src/main/java/com/zhangtielei/demos/opengles/transformations/MainActivity.java>{:target="_blank"}

首先，vertex shader中跟坐标变换有关的是下面这一行代码：

```java
	gl_Position = projection * view * model * vec4(position.xyz, 1);
```

它表示，对一个顶点坐标依次进行model、view、projection

















### 缩放和平移矩阵的推导

### Android中缩放和平移的实现



---

本文已经基本说明了这整个的分析思路，这个系列后面的文章仍然会遵循这一思路。等不及的读者已经可以按照类似的方法开始探索之旅了。



（完）


**其它精选文章**：

* [做技术的五比一原则](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&amp;mid=2657261555&amp;idx=1&amp;sn=3662a2635ecf6f67185abfd697b1057c&amp;chksm=84479e2ab330173cebe16826942b034daec79ded13ee4c03003d7bef262d4969ef0ffb1a0cfb#rd)
* [分层的概念——认知的基石](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261549&idx=1&sn=350d445acf339ce19e7aab1ff19d92d0&chksm=84479e34b3301722aea0aaaa6f74656dd3e9509d70bf5719fb3992d744312bdd1484fc0c1852#rd)
* [知识的三个层次](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261491&idx=1&sn=cff9bcc4d4cc8c5e642309f7ac1dd5b3&chksm=84479e6ab330177c51bbf8178edc0a6f0a1d56bbeb997ab1cf07d5489336aa59748dea1b3bbc#rd)
* [程序员的武林秘籍](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261552&idx=1&sn=dca554ca23c19394b1e0863bf08b5d49&chksm=84479e29b330173fc24e9c32e20ccd628ddfc6f9c71546dc31f4ebee49fca1c1bc4cc19d31c7#rd)
* [三个字节的历险](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261541&idx=1&sn=2f1ea200389d82e7340a5b4103968d7f&chksm=84479e3cb330172a6b2285d4199822143ad05ef8e8c878b98d4ee4f857664c3d15f54e0aab50#rd)
* [技术攻关：从零到精通](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261530&idx=1&sn=6e2e80a0895325861541c2b4266ae374&chksm=84479e03b3301715c53f0eebff06f6eca7d4a4089a635a2628e31480a5ca9e328403992f435b#rd)
* [那些让人睡不着觉的bug](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261538&idx=1&sn=0e4f6bec50f450528877cb7787fdc322&chksm=84479e3bb330172d988f3f3981c4af06d6898a236ebdb9aca35f3fe15c8b89f25b1981ca9c79#rd)
* [蓄力十年，做一个成就](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261524&idx=1&sn=f41934e050c964edd71371923c89e7cc&chksm=84479e0db330171b4211c0c31d11f94ed2508a68adc8760b173e448c26ab7b99964d5038c4dd#rd)

