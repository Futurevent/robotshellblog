---
title: 简述Fuchsia内核Zircon二
tags: OS
id: zircon2
categories: OS
date: 2020-01-02 16:26:53
---

[上一篇](https://www.robotshell.com/2019/12/25/os/zircon/)对Fuchsia的最底下一层Zircon层进行了简单介绍，并介绍了几个相关的概念：SystemCall、Handle、Koid。本文继续简述Fuchsia的Zircon中涉及的几个概念。
<!-- more-->
# 运行中的代码：Job、Process、Thread
Thread线程为地址空间内的一个执行线程（CPU寄存器、栈、等），这一地址空间归该线程所在的进程所有。进程归作业所有，作业定义了对资源的使用限制。作业归父作业所有。所有的作业都由根作业创建，根作业是在kernel启动时创建的，其中的Userboot是kernel创建的第一个用户空间进程。如果没有作业的Handle，进程内的线程将无法创建另外一个进程或者作业。在Fuchsia系统中，程序的加载是kernel之上的用户空间提供的（Zircon是微内核）。
进程和线程相关的几个API：zx_process_create()、zx_process_start()、zx_thread_create()、zx_thread_start()。

# 消息传递：socket 和 channel
Socket 和 channel 都是双向双端的IPC通信对象，当创建一个socket或者channel对象时，会返回两个handle，分别用来引用通信的一端。
Socket的读写是面向流的，一次可以读取一个或多个字节。当socket buffer已满时，支持向socket流中写入部分数据，当socket buffer内容不够读取长度时，也支持读取小于请求长度的数据。
Channel的读写是面向数据报的，并且对消息的最大长度和连接到该channel的handle都有最大值限制。消息的最大长度由ZX_CHANNEL_MAX_MSG_BYTES指定，关联到一条消息的最大handle由常量ZX_CHANNEL_MAX_MSG_HANDLES指定。消息的读写只有可读写或者不可读写，不存在中间状态。当向channel中写入一个消息的handle时，该handle将从发送进程销毁；当从channel中读取一条消息时，消息的handle将会被添加到接收进程中。在写入和读出这两个事件之间，Handle将一直存在以保证所引用的对象是持续存在的。如果在这个过程中channel被关闭了，handle所对应的消息将被丢弃掉。
相关的一些API：zx_channel_create(), zx_channel_read(), zx_channel_write(), zx_channel_call(), zx_socket_create(), zx_socket_read(), zx_socket_write()。

# 对象信号
对象信号用来表示一个对象当前所处的状态，一个对象最多可以有32个信号，信号的类型为zx_signalst，定义为ZXSIGNAL。例如：channel和socket对象具有READABLE和WRITEABLE的状态，而thread则有可能处于TERMINATED。
可通过等待对象信号的方式来进行线程的调度。线程可以使用zx_object_wait_one（）在单个句柄上等待激活信号，或使用zx_object_wait_many（）在多个句柄上等待信号。这两个调用都允许超时，之后即使没有信号挂起，它们也会返回。当一个线程中有大量的handle需要等待信号，则可以使用Port对象，Port对象允许多个handle绑定到它上。然后使用Port对象来等待对象信号，当信号发生时，Port会收到包含该信号的消息。
相关的一些API：zx_port_create()、zx_port_queue()、zx_port_cancel()、zx_port_wait()

# 事件和事件对
Event是一个只有激活信号集的简单对象。事件对则是一对事件，他们互相通知激活对方。事件对的一个重要属性是，当其中一个事件销毁时，事件对里的另一个事件将接受到一个PEER_CLOSED事件，从而可以关闭剩下的这一事件对象。
相关的API有：例如zx_event_create() zx_eventpair_create()

# 共享内存：虚拟内存对象（VMOs)
虚拟内存对象用来标识一个物理内存页或者是即将被分配的内存页的集合。可以使用zx_vmar_map()将一个虚拟内存对象映射到进程的地址空间中，使用zx_vmar_unmap()可解除这种映射关系，虚拟对象可以使用zx_vmo_read() 和 zx_vmo_write()对映射的内存直接进行读写。虚拟内存可用来实现共享内存，在进程间传递数据。

# 地址空间管理
虚拟内存地址区域（vmar），是一个用来表示进程内地址空间的对象。当进程被创建时，一个指向该进程根地址空间的类型为vmar的handle将被传递给进程的构造者。使用这一handle，使用接口zx_vmar_allocate 和 zx_vmar_map 可以对进程的地址空间进行分割以创建子虚拟内存地址区域。
与虚拟地址空间管理相关的API：zx_vmar_map(), zx_vmar_allocate(), zx_vmar_protect(), zx_vmar_unmap(), zx_vmar_destroy()

以上，主要就是几个fuchsia zircon内核常见的几个概念。同时，也列举了一些与这些概念相关联的一些API，混个眼熟，方便以后深入阅读zircon的代码时不至于太生疏。
