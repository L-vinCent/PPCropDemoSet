---
title: ( 每日一篇 ) block 修饰符的原理
date: 2018-04-15
tags: [每日一篇]
categories: 每日一篇
---


----

## 开篇自测

在本文的开头，提出两个简单的问题，如果你不能从根本上弄懂这两个问题，那么希望你阅读完本文后能有所收获。

1.  为什么block中不能修改普通变量的值？
2.  __block的作用就是让变量的值在block中可以修改么？

<!-- more -->

## block是什么？

很多教程、资料上都称Block是“带有自动变量值的匿名函数”。这样的解释显然是正确的，但也是不利于初学者理解的。我们首先通过一个例子看一看block到底是什么？

```
typedef void (^Block)(void);

Block block;
{
    int val = 0;
    block = ^(){
        NSLog(@"val = %d",val);
    };
}
block();
```

抛开block略有怪异的语法不谈，其实对于一个block来说：

> 它更像是一个微型的程序。

为什么这么说呢，我们知道程序就是数据加上算法，显然，block有着自己的数据和算法。可以看到，在这个简单的例子中，block的数据就是int类型变量val，它的算法就是一个简单的NSLog方法。对于一般的block来说，它的数据就是传入的参数和在定义这个block时截获的变量。而它的算法，就是我们往里面写的那些方法、函数调用等。

我认为block像是一个微型程序的另一个主要原因是一个block对象可以由程序员选择在什么时候调用。比如，如果我喜欢，我可以设置一个定时器，在10s后执行这个block，或者在另一个类里执行这个block。

当然，我们还注意到在上面的demo中，通过typedef，block非常类似于一个OC的对象。限于篇幅和主题，这里不加证明的给出一个结论：Block其实就是一个Objective-C的对象。有兴趣的读者可以结合runtime中类和对象的定义进一步思考。

## block是怎么实现的？

刚刚我们已经意识到，block的定义和调用是分离的。通过clang编译器，可以看到block和其他Objective-C对象一样，都是被编译为C语言里的普通的struct结构体来实现的。我们来看一个最简单的block会被编译成什么样：

```
//这个是源代码
int main(){
    void (^blk)(void) = ^{printf("Block\n");};
    block();
    return 0;
}
```

编译后的代码如下：

```
struct __block_impl {
    void *isa;
    int Flags;
    int Reserved;
    void *FuncPtr;
};

struct __main_block_impl_0 {
    struct __block_impl impl;
    struct __main_block_desc_0 *Desc;

    __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc,int flags=0){
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
}
};

struct void __main_block_func_0(struct __main_block_impl_0 *__cself){
    printf("Block\n");
}

static struct __main_block_desc_0{
    unsigned long reserved;
    unsigned long Block_size;
} __main_block_desc_0_DATA = {
    0,
    sizeof(struct __main_block_impl_0)
};
```

代码非常长，但是并不复杂，一共是四个结构体，显然一个block对象被编译为了一个__main_block_impl_0类型的结构体。这个结构体由两个成员结构体和一个构造函数组成。两个结构体分别是__block_impl和__main_block_desc_0类型的。其中__block_impl结构体中有一个函数指针，指针将指向__main_block_func_0类型的结构体。总结了一副关系图： 
![这里写图片描述](http://upload-images.jianshu.io/upload_images/904629-2b77206842c241d3?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

block在定义的时候：

```
//调用__main_block_impl_0结构体的构造函数
struct __main_block_impl_0 tmp = __main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA);
struct __main_block_impl_0 *blk = &tmp;
```

block在调用的时候：

```
（*blk->impl.FuncPtr)(blk);
```

之前我们说到，block有自己的数据和算法。显然算法（也就是代码）是放在__main_block_func_0结构体里的。那么数据在哪里呢，这个问题比较复杂，我们来看一看文章最初的demo会编译成什么样，为了简化代码，这里只贴出需要修改的部分。

```
struct __main_block_impl_0 {
    struct __block_impl impl;
    struct __main_block_desc_0 *Desc;
    int val;

    __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc,int _val, int flags=0) : val(_val){
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
}
};

struct void __main_block_func_0(struct __main_block_impl_0 *__cself){
    int val = __cself->val;
    printf("val = %d",val);
}
```

可以看到，当block需要截获自动变量的时候，首先会在__main_block_impl_0结构体中增加一个成员变量并且在结构体的构造函数中对变量赋值。以上这些对应着block对象的定义。

在block被执行的时候，把__main_block_impl_0结构体，也就是block对象作为参数传入__main_block_func_0结构体中，取出其中的val的值，进行接下来的操作。

## 为什么__block中不能修改变量值？

如果你耐心地看完了上面非常啰嗦繁琐的block介绍，那么你很快就明白为什么block中不能修改普通的变量的值了。

通过把block拆成这四个结构体，系统“完美”的实现了一个block，使得它可以截获自动变量，也可以像一个微型程序一样，在任意时刻都可以被调用。但是，block还存在这一个致命的不足：

注意到之前的__main_block_func_0结构体，里面有printf方法，用到了变量val，但是这个block，和最初block截获的block，除了数值一样，再也没有一样的地方了。参见这句代码：

```
int val = __cself->val;
```

当然这并没有什么影响，甚至还有好处，因为int val变量定义在栈上，在block调用时其实已经被销毁，但是我们还可以正常访问这个变量。但是试想一下，如果我希望在block中修改变量的值，那么受到影响的是int val而非__cself->val，事实上即使是__cself->val，也只是截获的自动变量的副本，要想修改在block定义之外的自动变量，是不可能的事情。这就是为什么我把demo略作修改，增加一行代码，但是输出结果依然是”val = 0”。

```
//修改后的demo
typedef void (^Block)(void);

Block block;
{
    int val = 0;
    block = ^(){
        NSLog(@"val = %d",val);
    };
    val = 1;
}
block();
```

既然无法实现修改截获的自动变量，那么编译器干脆就禁止程序员这么做了。

## __block修饰符是如何做到修改变量值的

如果把val变量加上__block修饰符，编译器会怎么做呢？

```
    //int val = 0; 原代码
    __block int val = 0;//修改后的代码
```

编译后的代码：

```
struct __Block_byref_val_0 {
    void *__isa;
    __Block_byref_val_0 *forwarding;
    int __flags;
    int __size;
    int val;
};

struct __main_block_impl_0 {
    struct __block_impl impl;
    struct __main_block_desc_0 *Desc;
    __Block_byref_val_0 *val;

    __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc,__Block_byref_val_0 *_val, int flags=0) : val(_val->__forwrding){
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
}
};

struct void __main_block_func_0(struct __main_block_impl_0 *__cself){
    __Block_byref_val_0 *val = __cself->val;
    printf("val = %d",val->__forwarding->val);
}
```

改动并不大，简单来说，只是把val封装在了一个结构体中而已。可以用下面这个图来表示五个结构体之间的关系。

![这里写图片描述](http://upload-images.jianshu.io/upload_images/904629-46a3e97ed0c3f529?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

但是关键在于__main_block_impl_0结构体中的这一行：

```
__Block_byref_val_0 *val;
```

由于__main_block_impl_0结构体中现在保存了一个指针变量，所以任何对这个指针的操作，是可以影响到原来的变量的。

进一步，我们考虑截获的自动变量是Objective-C的对象的情况。在开启ARC的情况下，将会强引用这个对象一次。这也保证了原对象不被销毁，但与此同时，也会导致循环引用问题。

需要注意的是，在未开启ARC的情况下，如果变量附有__block修饰符，将不会被retain，因此反而可以避免循环引用的问题。

来自[bestswifter](https://blog.csdn.net/abc649395594/article/details/47086751)

----


关键词: 匿名函数 , 截获自动变量 ， 循环引用


