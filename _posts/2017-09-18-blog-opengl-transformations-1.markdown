---
layout: post
category: "android"
title: "OpenGL ES和坐标变换（一）"
date: 2017-09-18 00:00:01 +0800
published: true
---

相信做技术的同学，特别是做客户端开发的同学，都听说过OpenGL。要想对客户端的渲染机制有一个深入的了解，不对OpenGL了解一番恐怕是做不到的。而且，近年来客户端开发中对于图像和视频的处理的需求，成上升趋势，要想胜任这些稍具「专业性」的工作，对于OpenGL的学习也是必不可少的。然而，OpenGL的学习曲线相对来说比较陡峭，尤其是涉及到一些计算机图形学方面的专业知识，不免会让很多人望而生畏。

<!--more-->

要想熟练地掌握OpenGL，有两方面相关的知识是需要重点关注的。

* 一个是OpenGL的图形处理管线(graphics pipeline)，也就是图形渲染的整个过程包含哪些步骤，每个步骤的作用是什么，比如我们编写的vertex shader和fragment shader工作在哪些阶段，再比如depth testing (深度测试)、stencil testing (模板测试)，以及rasterization (光栅化)等等，分别起到什么作用；
* 另一个就是坐标变换，也就是vertex shader主要要完成的功能。如何将3D空间中的一个物体摆放到正确的位置，调整到正确的姿态，以及最终如何将3D坐标投射到2D的平面(一般来说是屏幕)上。

本文所要探讨的主题，将主要围绕上述第二个方面的知识，也就是坐标变换。这部分涉及到一点数学知识，显得更难理解一些，并且网上的资料也散落在各处，很少有系统而详尽的描述。严格来说，这部分理论知识并不完全属于OpenGL规范所规定的范围，但却与之有着非常密切的关系。接下来，就坐标变换这个主题，我会写一个小系列，由多篇技术文章组成，将坐标变换相关的资料整理在一起，希望能为学习OpenGL和图像处理的同学扫清理论上的障碍。

本着理论联系实际的原则，我们将结合Android系统上的API介绍相关的理论。之所以选择Android环境，是因为上手简单，大部分程序员都能很快地跑起一个Android程序，并且OpenGL相关的编程环境在Android是现成的，几乎不用太多的配置。在Android上，实际广泛使用的是OpenGL ES 2.0，它可以看成是OpenGL对应版本的一个子集。我们在接下来的讨论中，也以OpenGL ES 2.0为准。

另外，很多实际中的开发任务只涉及到2D图像的处理，而不会涉及3D的处理。使用OpenGL ES做2D的图像处理，确实处理流程会简化一些，然而，个人认为，搞清3D的渲染机制，对于理解整件事有至关重要的作用。理解了3D，便能理解2D，反之则不成立。而且，只有在3D的语境下，坐标变换的完整概念才能被理解。因此，我们一开始便从3D开始，等介绍完3D空间中的坐标变换之后，我们再回到2D的特殊情况加以讨论。

### 一个例子程序

很多OpenGL的入门文章，都以画一个三角形开始。但是，对于讨论坐标变换这件事来说，画一个三角形的例子并不太合适，因为三角形是一个平面图形，对它应用了完整的坐标变换之后，会得到看似很奇怪的结果，反而让初学者比较迷惑。所以，本篇给出的例子程序画的是立方体(cube)。程序下载地址：

* <https://github.com/tielei/OpenGLESTransformationsDemo>{:target="_blank"}

下面是程序输出截图：

[<img src="/assets/photos_opengl_trans/cube_drawing.png" style="width:300px" alt="例子程序输出截图" />](/assets/photos_opengl_trans/cube_drawing.png)

没错，程序画了三个立方体的木箱子，它们的位置、大小、角度各不相同。但实际上，上面的大木箱子和下面的小木箱子都是由中间的那个木箱子经过一定的坐标变换（伸缩、旋转、位移）之后得到的。而中间的木箱子所在的位置是原始的位置，即世界坐标的原点处（世界坐标的概念我们马上就会介绍）。

接下来，我们先不过早地深入到代码细节，而是先把坐标变换的整个过程做一个概览。

### model/view/projection变换

（完）







































**其它精选文章**：

* [分层的概念——认知的基石](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261549&idx=1&sn=350d445acf339ce19e7aab1ff19d92d0&chksm=84479e34b3301722aea0aaaa6f74656dd3e9509d70bf5719fb3992d744312bdd1484fc0c1852#rd)
* [知识的三个层次](/posts/blog-knowledge-hierarchy.html)
* [程序员的武林秘籍](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261552&idx=1&sn=dca554ca23c19394b1e0863bf08b5d49&chksm=84479e29b330173fc24e9c32e20ccd628ddfc6f9c71546dc31f4ebee49fca1c1bc4cc19d31c7#rd)
* [三个字节的历险](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261541&idx=1&sn=2f1ea200389d82e7340a5b4103968d7f&chksm=84479e3cb330172a6b2285d4199822143ad05ef8e8c878b98d4ee4f857664c3d15f54e0aab50#rd)
* [技术的正宗与野路子](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261357&idx=1&sn=ebb11a1623e00ca8e6ad55c9ad6b2547#rd)
* [技术攻关：从零到精通](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261530&idx=1&sn=6e2e80a0895325861541c2b4266ae374&chksm=84479e03b3301715c53f0eebff06f6eca7d4a4089a635a2628e31480a5ca9e328403992f435b#rd)
* [那些让人睡不着觉的bug](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261538&idx=1&sn=0e4f6bec50f450528877cb7787fdc322&chksm=84479e3bb330172d988f3f3981c4af06d6898a236ebdb9aca35f3fe15c8b89f25b1981ca9c79#rd)
* [蓄力十年，做一个成就](https://mp.weixin.qq.com/s?__biz=MzA4NTg1MjM0Mg==&mid=2657261524&idx=1&sn=f41934e050c964edd71371923c89e7cc&chksm=84479e0db330171b4211c0c31d11f94ed2508a68adc8760b173e448c26ab7b99964d5038c4dd#rd)

