---
title: android O 电源管理之从automotive谈起
id: power automotive
tags: android
categories: android
date: 2018-02-04 00:15:49
---

android o 在源码工程/package/service/目录下新增了一个目录Car, 做为android automotive的重要组成部分，这部分可理解为在android世界的基础上，调用android的api构造出的Vehicle框架，该框架将android这一系统获得从手机迁移到目前最大的智能设备————车上的能力。
从automotive 开始分析android O 的电源管理，一方面可以站在android api用户的角度，从调用逐层的深入下去直达kernel，另一方面也可以帮助理清android automotive的框架结构。对于android automotive的框架结构的更详细的介绍可以参考另外的说明，本文当然重点还是在于从头到位的串讲下android O的电源管理。
<!-- more -->
# android O automotive 框架层中的电源管理
## Car Power Management 框架
源码分析在关于[Android O Vehicle](http://www.robotshell.com/2018/02/03/Android-O-Vehicle%E4%B9%8BCar-Service/)的相关文章中有详细描述，此处不在赘述，上一张框架图如下：
{% asset_img AndroidAutomotivePowermanagementArch.png 安卓汽车电源管理架构图 %}
## androidO automotive 中定义的AP Power 状态
Android Vehicle 的电源管理概括起来两件事：同步android与车载MCU的电源状态和通过PowerManager的API控制android的电源状态。

AP 的官方文档解释：
Application Processor, aka SOC. The processor chip running Android. 可以简单理解为Android系统。

车上的MCU通过gpio或数据总线等方式与AP进行沟通并对AP的电源进行管理，通过get和set属性AP_POWER_STATE的值实现.
### AP_POWER_STATE get的值（VMCU --> AP）
android O 的automotive在VehicleProperty中定义了VehicleApPowerState，其中定义了五种状态, hal在监测到车身有如下五种状态间的变化时，向AP上报变化后的状态，如下：

| 状态             | 值 | 说明                           |
| - | - | - |
| OFF              | 0 | vehicle hal 不会向AP上报此状态 |
| DEEP_SLEEP       | 1 |vehicle hal 不会向AP上报此状态 |
| ON_DISP_OFF      | 2 |AP 运行但是灭屏                |
| ON_FULL          | 3 |AP 运行且亮屏，此时用户可交互  |
| SHUTDOWN_PREPARE | 4 |电源管理请求AP关机，AP视情况进入SLEEP状态或者关机，也可以通过发送SHUTDOWN_POSTPONE请求延时关机                               |

SHUTDOWN_PREPARE 状态携带参数 VehicleApPowerStateShutdownParam，该参数有三个取值如下：

| 参数                 | 值  | 说明                              |
| -------------------- | --- | --------------------------------- |
| SHUTDOWN_IMMEDIATELY | 1   | AP 必须立即关机，延迟关机不被允许  |
| CAN_SLEEP            | 2   | AP 可以使用深度睡眠来代替关机     |
| SHUTDOWN_ONLY        | 3   | 允许延迟关机                   |

这五种状态间的切换关系如下：
{% asset_img VehiclePowerApStateMachine.png 车辆电源状态机 %}
### AP_POWER_STATE set的值 (AP --> VMCU)
AP开机或其他业务需求触发或响应VMCU对AP的电源管理需求的过程中，需要向VMCU同步AP的电源变化，在VehiclePropertyType 中有如下定义:

| 状态              | 值  | 说明                                      |
| ----------------- | --- | ----------------------------------------- |
| BOOT_COMPLETE     | 0x1 | AP 已经完成启动                           |
| DEEP_SLEEP_ENTRY  | 0x2 | AP 正在进入deep sleep 状态                |
| DEEP_SLEEP_EXIT   | 0x3 | AP 正在退出deep sleep 状态                |
| SHUTDOWN_POSTPONE | 0x4 | AP 请求延时关机，单次最大支持5000ms       |
| SHUTDOWN_START    | 0x5 | AP 正在关机，可携带参数指定关机多久后开机 |
| DISPLAY_OFF       | 0x6 | 用户请求关闭显示                          |
| DISPLAY_ON        | 0x7 | 用户请求打开显示                          |

以上为automotive 部分的电源管理，automotive 部分说明了对android电源管理的请求从VMCU来或者从调用Car接口来。但是automotive 对电源管理请求最终的处理，还得到android系统中，再进一步到kernel中去。

---
## Android 电源管理
automotive 通过调用 PowerManager的API实现对Android的电源管理，android 系统的电源管理牵涉的模块非常的多，但是其主要框架是以PowerManagerService核心的，PowerManagerService 做为系统Service与其他系统Service 一起在SystemServer中被初始化。
### android 的电源管理整体框架
{% asset_img AndroidPowerArc.png 安卓电源框架 %}
由图可知，电源管理框架可分为如下基层：
- 应用层：例如Vehicle的电源管理、设置等其他应用等。
- Framework层：主要实现android电源管理的策略，负责调度和通知其他模块对电源管理做出响应。主要分为JavaFramework 和以com_android_server_power_PowerManagerService.cpp为核心的nativeFramework。
- HAL层：主要包含传统的hardware_legacy中的power.c和android O 新增的Vendor Interface 对应的Hardware/Interface/Power 中的power.hal 部分。
- Kernel层：主要包含linux的电源管理策略，以及对suspend lock的控制和reboot系统调用。
### PowerManagerService 的基本结构
{% asset_img PowerManagerServiceClass.png PowerManagerService关键类图 %}
### automotive 中调用到的PowerManager相关部分
主要在SystemInterfaceImpl中

| API               | 说明                                                                                         |
| ----------------- | -------------------------------------------------------------------------------------------- |
| shutdown          | Turn off the device                                                                          |
| goToSleep         | Forces the device to go to sleep                                                             |
| PARTIAL_WAKE_LOCK | Ensures that the CPU is running; the screen and keyboard backlight will be allowed to go off |
| FULL_WAKE_LOCK    | Ensures that the screen and keyboard backlight are on                                        |

- shutdown 会依次调用到
```flow
st=>start: Start
A=>operation: PowerManagerService.BinderService.shutdown
B=>operation: PowerManagerService.shutdownOrRebootInternal
C=>operation: ShutdownThread.shutdown
D=>operation: shutdownInner
E=>operation: beginShutdownSequence
F=>operation: 在ShutdownThread的run方法中 AMS PMS 等Service的shutdown方法做清理工作
G=>operation: PowerManagerService.lowLevelShutdown 修改属性sys.powerctl值为shutdown
H=>operation: property_service 监测到属性变化后最终调用到init.cpp中的property_changed]
I=>operation: 调用reboot.cpp的HandlePowerctlMessage->DoReboot中进行一些清理工作->RebotSystem 最终调用系统调用reboot
e=>end: End

st->A->B->C->D->E->F->G->H->I->e
```
- goToSleep
调用goToSleep的时候第三个参数为GO_TO_SLEEP_FLAG_NO_DOZE(Go to sleep flag: Skip dozing state and directly go to full sleep)
这里提到的Doze 模式,是android 6.0 后新增的特性
{% asset_img Doze.png Doze%}
如上图：Doze模式提供一个复发的maintenance window给app去使用网络和处理挂起的操作
Doze 模式下的限制:
  1. 网络访问功能被关闭
  2. 系统会忽略wake locks，即app无法持续占有电源
  3. 标准闹钟 AlarmManager（包括setExact()和setWindow()）都会被延时到下一个maintenance window才激活
    3.1. 如果app仍需要在Doze时使闹钟生效，可以使用setAndAllowWhileIdle()或setExactAndAllowWhileIdle()
    3.2. 使用函数setAlarmClock()设置的闹钟在Doze时仍会生效，系统会在闹钟生效前推出Doze。
  4. 系统不会进行Wi-Fi扫描
  5. 系统不允许异步Adapters运行
  6. 系统不允许JobScheduler运行

Doze 主要由DeviceIdleController实现，在DeviceIdleController中通过设备逐渐的满足条件，使得系统一步步的进入到doze状态下，流程如下图(android O貌似与此图有些微不同)：
{% asset_img DozeDeviceIdleControllerstate.png DozeState %}
分析源码可知，goToSleep 的实现最终也是依赖WakeLock锁来实现的，实现的流程先省略。且往下看。

### WakeLock
这里主要用到了两种锁如下

| 锁                             | cpu | display | keyboard | 电源键影响 |
| ------------------------------ | --- | ------- | -------- | ---------- |
| PARTIAL_WAKE_LOCK = 0x00000001 | On  | off     | off      | 不受       |
| FULL_WAKE_LOCK = 0x0000001a    | On  | Bright  | On       | 受         |

android 中其他锁的定义如下表：

| 锁类型                                      | cpu                                     | display                          | keyboard | 电源键影响 | 备注                                                      |
| ------------------------------------------- | --------------------------------------- | -------------------------------- | -------- | ---------- | --------------------------------------------------------- |
| PARTIAL_WAKE_LOCK = 0x00000001              | on                                      | off                              | off      | 不受       |                                                           |
| SCREEN_DIM_WAKE_LOCK = 0x00000006           | on                                      | dim                              | off      | 受         |                                                           |
| SCREEN_BRIGHT_WAKE_LOCK = 0x0000000a        | on                                      | bright                           | off      | 受         |                                                           |
| FULL_WAKE_LOCK = 0x0000001a                 | on                                      | bright                           | off      | 受         |                                                           |
| PROXIMITY_SCREEN_OFF_WAKE_LOCK = 0x00000020 | 距离传感器导致的灭屏后on，否则可正常off | 距离传感器检测到有物体off,否则on | off      | 受         | 需要设备支持距离传感器，不能和ACQUIRE_CAUSES_WAKEUP一起用 |
| DOZE_WAKE_LOCK = 0x00000040                 | off                                     | off                              | off      | 受         | 系统支持doze                                              |
| DRAW_WAKE_LOCK = 0x00000080                 | on                                      | off                              | off      | 不受       | windowManager允许应用在dozing状态绘制屏幕                 |

配合锁使用的两个flag

| flag                               | 说明                                                                                                     | 备注                           |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------- | ------------------------------ |
| ACQUIRE_CAUSES_WAKEUP = 0x10000000 | 正常情况下，获取wakelock是不会唤醒设备的，加上该标志之后，acquire wakelock也会唤醒设备                   | 不能和PARTIAL_WAKE_LOCK 一起用 |
| ON_AFTER_RELEASE = 0x20000000      | 和用户体验有关，当wakelock释放后如果没有该标志，屏幕会立即黑屏，如果有该标志，屏幕会亮一小会然后在黑屏。 |   不能和PARTIAL_WAKE_LOCK 一起用                             |

对于锁的使用无非就是两种操作，acquire和release。对于这两个过程，见如下流程图：
{% asset_img WakelockAcquireRelease.png WakeLock 申请与释放的流程图%}
### Wakefulness
PowerManagerService 中的 mWakefulness 用来指示当前设备所处的状态，它有四种取值

| Wakefulness          | 值  | 说明 |
| -------------------- | --- | --- |
| WAKEFULNESS_ASLEEP   | 0   | 表示系统当前处于休眠状态，只能通过调用wakeup()唤醒|
| WAKEFULNESS_AWAKE    | 1   | 表示系统当前处于正常运行状态                    |
| WAKEFULNESS_DREAMING | 2   | 表示系统当前处于屏保状态                       |
| WAKEFULNESS_DOZING |  3   | 表示系统当前处于“Doze”状态，在该状态只有低功耗的屏保可以运行，其他应用进程将被挂起|

在PowerManagerService 中无论是开关机，还是影响电源管理的用户行为（UserActivity）的管理，还是对wakelock锁的使用，（PowerManagerService中有两个很重要的底层SuspendBlockerLock:CPU锁————PowerManagerService.WakeLocks和Display锁————PowerManagerService.Display，系统通过向设备节点文件/sys/power/wake_lock 和 /sys/power/wake_unlock写入这两个锁的名字来控制cpu和display），最终都会调用到一个很重要的方法updatePowerStateLocked，该方法是整个PowerManagerService的核心。
其大体调用逻辑如下：
{% asset_img UpdatePowerStateLocked.png UpdatePowerStateLocked流程图 %}
---

## Android HAL 及更底层的电源管理
Android的电源管理提出wakelock的是一套全新的机制，借用C++里智能指针思想来设计电源的使用和分配。wake_lock保持使用计数，只不过这种“智能指针”的所使用的资源不再是内存，而是电量。应用程序会通过特定的WakeLock去访问硬件，然后硬件会根据引用计数是否为0来决定是不是需要关闭这一硬件的供电。 这种机制在SuspendBlockerImpl 中实现，通过对mReferenceCount的判断是否调用nativeAcquireSuspendBlocker和nativeReleaseSuspendBlocker, 底层调用通过向设备节点文件/sys/power/wake_lock 和 /sys/power/wake_unlock 里写入锁的名字实现对对应设备是否休眠的操作。

### PowerManagerService 对应的 hardware interface
位置： hardware/interface/power/1.0/ 其中IPower.hal 提供如下四个接口：
  - setInteractive(bool interactive)  设置系统是否交互状态，通常亮灭屏调用
  - powerhint(Powerhint hint, int32_t data) 调整cpu频率等参数时用来传递hint
  - setFeature(Feature feature, bool activate) 用来使能实际的feature
  - getPlatformLowPowerStats()generates(vec<PowerStatePlatformSleepState>), statuss retval);

---

## 参考资源
linux 电源管理相关blog: [电源管理子系统](http://www.wowotech.net/sort/pm_subsystem)
