---
title: 简述Fuchsia内核Zircon
tags: OS
id: zircon
categories: OS
---
Zircon是Fuchsia系统的内核。严格的讲，应该说Zircon是Fuchsia系统的核心，是Fuchsia系统的最底一层（回想下Fuchsia系统的四层蛋糕结构）。它由一个微内核（/zircon/kernel)和少量的用户空间代码组成。这部分用户空间代码是一些核心的服务、驱动和类库等（/zircon/system/necessary)，用于系统引导，与底层硬件交互、加载用户空间的进程等。Fuchsia将在Zircon之上构建出庞大的OS。
<!--more-->
Zircon对外提供系统调用，用来管理进程、线程、虚拟内存等，提供进程间通信的机制，监控内核中对象状态的改变，提供锁机制等。内核管理了大量的各种类型的对象，用户空间可以通过系统调用直接读取这些对象，这些东西通常是实现了分发接口的C++对象。这些C++类定义在kernel/object目录下，这些类大部分是一些自包含的C++类，一部分是底层LK（little kernel zircon内核的内核，一个嵌入式的内核）原语的包装类。下面是，当前代码中的这部分类的列表。
```
/zircon/kernel/object(218e80562e*) » ls
buffer_chain.cc                          fifo_dispatcher.cc                   job_policy_tests.cc                resource.cc
buffer_chain_tests.cc                    futex_context.cc                     log_dispatcher.cc                  resource_dispatcher.cc
BUILD.gn                                 glue.cc                              mbuf.cc                            socket_dispatcher.cc
bus_transaction_initiator_dispatcher.cc  guest_dispatcher.cc                  mbuf_tests.cc                      socket_dispatcher_tests.cc
channel_dispatcher.cc                    handle.cc                            message_packet.cc                  state_tracker_tests.cc
clock_dispatcher.cc                      handle_tests.cc                      message_packet_tests.cc            suspend_token_dispatcher.cc
diagnostics.cc                           include                              OWNERS                             thread_dispatcher.cc
dispatcher.cc                            interrupt_dispatcher.cc              pager_dispatcher.cc                timer_dispatcher.cc
event_dispatcher.cc                      interrupt_event_dispatcher.cc        pci_device_dispatcher.cc           user_handles.cc
event_pair_dispatcher.cc                 interrupt_event_dispatcher_tests.cc  pci_interrupt_dispatcher.cc        vcpu_dispatcher.cc
exceptionate.cc                          iommu_dispatcher.cc                  pinned_memory_token_dispatcher.cc  virtual_interrupt_dispatcher.cc
exceptionate_tests.cc                    job_dispatcher.cc                    port_dispatcher.cc                 vm_address_region_dispatcher.cc
exception.cc                             job_dispatcher_tests.cc              process_dispatcher.cc              vm_object_dispatcher.cc
exception_dispatcher.cc                  job_policy.cc                        profile_dispatcher.cc              wait_state_observer.cc
```
下面是对zircon中涉及到的一些概念的介绍。
# SystemCall
用户空间通过系统调用来使用内核提供的接口，而且这些系统调用都是基于Handle（句柄）的。在用户空间，Handle使用32位的整形标识，类型为zx_handle_t，实际上这个句柄是调用进程内句柄表的一个索引值。当发生系统调用时，内核会根据句柄值在调用空间内部的句柄表中保存的真实的句柄，并对其进行类型和权限的检查，例如向需要一个线程句柄的系统调用传入一个事件类型的句柄是会发生错误的。
从调用的角度划分，系统调用可分为三大类：

1. 没有调用限制的系统调用，这种类型的系统调用占极少数，例如：zx_clock_get() 和 zx_nanosleep() 这样的系统调用可以被任意线程调用。
2. 第一个参数为Handle，用来表示调用目标的系统调用，这部分占大多数，例如zx_channel_write() 和 zx_port_queue()等。
3. 创建新的对象，不包含handle的系统调用，例如zx_event_create()和zx_channel_create()等。

这些系统调用通过libzircon.so向外提供，libzircon.so 是一个虚拟共享库（virtural Dynamic Shared Object vDSO)，提供的接口基本都是zx_名词_动词()和zx_名词_动词_直接对象()这样子的命名格式。
这些系统调用是使用fidl格式定义，经过fidl编译为各种格式，方便各语言调用Zircon系统内核。
当前代码中的系统调用的定义的文件列表，位于/zircon/syscalls目录下
```bash
/zircon/syscalls(218e80562e*) » ls
alias_workarounds.fidl  cprng.fidl      exception.fidl    handle.fidl     ktrace.fidl  pager.fidl  process.fidl   socket.fidl   timer.fidl
bti.fidl                debug.fidl      fifo.fidl         interrupt.fidl  misc.fidl    pc.fidl     profile.fidl   syscall.fidl  vcpu.fidl
cache.fidl              debuglog.fidl   framebuffer.fidl  iommu.fidl      mtrace.fidl  pci.fidl    resource.fidl  system.fidl   vmar.fidl
channel.fidl            event.fidl      futex.fidl        ioports.fidl    object.fidl  pmt.fidl    rights.fidl    task.fidl     vmo.fidl
clock.fidl              eventpair.fidl  guest.fidl        job.fidl        OWNERS       port.fidl   smc.fidl       thread.fidl   zx.fidl
```

# Handle
一个内核中的对象可能存在多个句柄（在一个或多个进程中）。当应用一个对象的最后一个打开的句柄关闭后，该对象或者被释放，或者将处于一种无法被销毁的最终状态。
可以通过向channel写入一个句柄（例如zx_channel_write），将句柄从一个进程传递到另一个进程；或者在使用zx_process_start一个新进程时，将句柄作为参数传递给新进程的第一个线程。
可对一个句柄及该句柄所引用的对象进行何种操作，是由该句柄具有的权限所控制的。同意对象的不同句柄也可能具有不同类型的权限。
系统调用zx_handle_duplicate()和zx_handle_replace()可以产生传入的句柄所引用对象的新的句柄，这两个系统调用可以指定权限，使新产生的句柄比原句柄具有更少的权限。zx_handle_close()用来释放一个句柄，zx_handle_close_many()用来释放一个句柄数组，如果释放的句柄是被引用对象的最后一个句柄，将导致对象的释放。

# 内核对象ID
内核中的每一个对象都有一个内核对象ID(kernel object id, 缩写为koid)，用一个64位的无符号整型来标识。koid用来唯一标识一个内核对象，在系统的声明周期内koid是唯一的。
koid 有两种取值：
- ZX_KOID_INVALID

值为0，与null同意

- ZX_KOID_KERNEL

唯一的内核对象的ID值

kernel分配的koid只使用了64位中63为，预留1位，作为人工制定koid时使用。

本文简述了Zircon内核的基本概念，涉及到系统调用、句柄、KOID等几个名词。比较关键的概念还有作业、进程、线程、进程间通信、消息传递等，等后续了解后再进行简述。
