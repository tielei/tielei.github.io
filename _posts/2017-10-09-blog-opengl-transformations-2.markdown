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

著名数学家高斯曾经说过一句话：“当一幢建筑物完成时，应该把脚手架拆除干净。”他说这话的意思是，一个新的数学理论一旦推导完成，他就会把多余的东西（比如灵感来源、直观的想法、中间走过的弯路、多余的推导计算等等）统统删掉，只把最终得到的最简洁的定理和结论公布出来。高斯的理由是，「脚手架」会影响理论的美感。但是，没有这些所谓的「脚手架」，后人就很难理解他的理论。从学习的角度来说，这些「脚手架」却是大大的有用。试想，只是看到一座宏伟的大厦，你并不能学会如何去建造它。

本文为了让细节讨论更加清楚，当然不会按照高斯的这种风格。相反，在本文接下来的描述中，我们会尽量详尽地说明每一步推导过程，并尽可能把推导的思路说清楚。

### Demo程序简介

[上一篇](/posts/blog-opengl-transformations-1.html)已经给出了Demo程序的地址，为了明确，这里把地址再贴一遍。本文中出现的代码，都来自于下面这个文件：

* <https://github.com/tielei/OpenGLESTransformationsDemo/blob/master/app/src/main/java/com/zhangtielei/demos/opengles/transformations/MainActivity.java>{:target="_blank"}

首先，vertex shader中跟坐标变换有关的是下面这一行代码：

```java
	gl_Position = projection * view * model * vec4(position.xyz, 1);
```

它表示，对一个顶点坐标依次进行model、view、projection三种变换。这三种变换，分别是通过左乘一个矩阵来完成的。在上面这行代码中，看起来三个变换的顺序跟我们期望的相反了，但这正是矩阵左乘造成的结果。

代码中的`vec4(position.xyz, 1)`表示顶点在本地坐标系中的坐标（用一个四维的齐次坐标来表达，我们下面会详细介绍）。它左边乘上model矩阵，就得到了该顶点在世界坐标系中的坐标。[上一篇](/posts/blog-opengl-transformations-1.html)我们已经讲过，这个model变换可能包含了缩放(scaling)、旋转(rotation)、平移(translation)这三种变换。然后，世界坐标系中的坐标再左乘一个view矩阵，就变换到了相机坐标系。最后，再左乘projection矩阵，就完成了投影变换。

那么这行代码中的model、view、projection这三个矩阵，它们的值是什么呢？我们看一下在Demo程序中它们的值是怎样分别计算。以第2个立方体为例，计算model矩阵的代码如下：

```java
	Matrix.setIdentityM(modelMatrix2, 0);
	Matrix.translateM(modelMatrix2, 0, 0.5f, 1.0f, -1.5f);
	Matrix.rotateM(modelMatrix2, 0, angle, 0.0f, 1.0f, 0.0f);
	Matrix.scaleM(modelMatrix2, 0, 1.5f, 1.5f, 1.5f);
```

这段代码中的`modelMatrix2`就是要计算的model矩阵，它是一个4x4的矩阵，存储在一个长度为16的float数组里(`float[16]`)。为什么不是3x3的矩阵呢？这跟齐次坐标有关，我们后面再说，现在先不管它。我们调用了Android SDK中的`Matrix`工具类的方法对其进行了赋值。`setIdentityM`表示设置一个初始的单位矩阵，而`translateM`, `rotateM`和`scaleM`表示在这个初始的单位矩阵基础上依次对矩阵进行调整，分别执行平移、旋转、伸缩操作。需要注意的是，这里的代码调用顺序虽然是先平移，然后旋转，最后再进行伸缩，但这些操作的含义却需要反过来解释，也就是说先进行了一个伸缩操作，然后进行了旋转，最后才执行了平移操作。这其中的原因仍然与矩阵左乘的含义有关，相关细节我们会在本文最后一部分再详细解释。现在我们暂且记住这些操作的解释顺序，那么上面这段代码的精确含义就是：

1. **伸缩**：先在x, y, z三个坐标轴上都放大1.5倍；
2. **旋转**：再绕着向量[0.0, 1.0, 0.0]<sup>T</sup>(也就是y轴)旋转角度`angle`；
3. **平移**：沿x轴正向平移0.5个单位，沿y轴正向平移1.0个单位，沿z轴负向平移1.5个单位。

如果你已经运行了Demo程序，那么根据上面这段描述，你就会看到这个立方体正是屏幕最上面的那个最大的立方体。它沿着一个轴在不停地旋转。之所以会旋转，是因为上面第2步中旋转的角度`angle`是个动态的值，它的值每一帧都在变化，所以看起来在不停地旋转。

[<img src="/assets/photos_opengl_trans/cube_drawing.png" style="width:300px" alt="例子程序输出截图" />](/assets/photos_opengl_trans/cube_drawing.png)

看到这里，估计有些同学禁不住会想，在上面的描述中，y轴是不是就是指向屏幕的上方？z轴是不是就是垂直于屏幕？不是的。当我们提到坐标以及坐标轴的时候，我们首先必须搞清我们当前在谈论的到底是哪个坐标系。在整个计算过程中，我们经常会在不同的坐标系之间切换。根据[上一篇](/posts/blog-opengl-transformations-1.html)的介绍，我们当前正在谈论的model变换是从本地坐标系变换到世界坐标系，因此，这里的x, y, z三个坐标轴指的是世界坐标系。而世界坐标系与屏幕的角度和位置没有直接关系，这取决于后面的view变换（从哪个角度去观察）。

接下来，我们再看一下在Demo程序中view矩阵是怎样计算的。

```java
	 Matrix.setLookAtM(viewMatrix, 0, 3.0f, 3.0f, 10.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f);
```

这行代码中的`viewMatrix`就是要计算的view矩阵，它也是一个4x4的矩阵。我们仍然是调用了`Matrix`工具类的方法对其进行了赋值。它表达的意思是：我们把眼睛（或者说相机）放在世界坐标系的(3.0, 3.0, 10.0)这个点，然后观察的方向正对着点(0.0, 0.0, 0.0)，即世界坐标系的原点。同时我们还需要指定一个「头朝上」的方向，这在代码里设置的是向量(0.0, 1.0, 0.0)指向「上」的方向。

最后看一下projection矩阵的计算：

```java
 	Matrix.perspectiveM(projectionMatrix, 0, 45.0f, width / (float) height, 0.1f, 100.0f);
```

这行代码中的`projectionMatrix`就是要计算的projection矩阵，它同样也是一个4x4的矩阵。'Matrix.perspectiveM'对这个矩阵进行了赋值，这个调用需要的几个输入参数如下：

* 观察视角为45.0度。这个值通常被称为field of view，简称fov。它的含义已在下图中标出。

[<img src="/assets/photos_opengl_trans/clip_space_fov.png" style="width:500px" alt="投影变换fov展示图" />](/assets/photos_opengl_trans/clip_space_fov.png)

* 第二个参数为宽高比，指的是近平面(N)的宽高比。
* 第三和第四个参数分别表示近平面(N)和远平面(F)与相机位置的距离。

现在，与model、view、projection三个矩阵的计算有关的代码我们都看到了，已经粗略知道了整个计算的流程。下一节我们就定量地分析一下其中某些矩阵的计算过程。

### 缩放和平移矩阵的推导

#### 平移矩阵的推导过程

#### 缩放矩阵的推导过程

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

