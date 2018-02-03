---
title: Android O Vehicle之架构介绍
tags:
  - android
categories:
  - android
date: 2018-02-03 18:28:31
---

Android Automotive 是 Android Orea 中的一个特色功能，从AOSP的代码上看，android automotive 已经包含了从app层到framework层到hal层的各层级结构。本文简单介绍 Android Orea Vehicle 的架构形式
<!-- more -->
### 层次结构
Google [automotive](https://source.android.com/devices/automotive/?hl=zh-cn) 给出的架构如下图。
![Android_automotive_arch](http://ovfro7ddi.bkt.clouddn.com/vehicle_hal_arch.png)
从图中看，android vehicle 可划分为三层：
- Car API
Car API 中包含与Car 相关的各种 manager API，通过这些manager 对app提供 car service 所能提供的服务，主要实现在/packages/services/Car/car-lib/目录下
- Car Service
Car Service 是android vehicle 的主要实现，在这一层会处理部分车辆业务逻辑，并向下调用Vehicle Hal 暴露的接口。主要实现在/packages/services/Car/service/目录下
- Vehicle Hal
Vehicle Hal 主要用来定义车辆属性，并向上提供读写属性的接口，以及对属性变化注册监听的接口。厂家需实现各自自定义的Vehicle Hal.主要实现在/hardware/interfaces/automotive.

### 层次实现
Android O 对 Vehicle 的支持除HAL层，基本都在/packages/service/Car 目录下，android 的car 架构可以理解为在android framework之上，利用android framework的android api 实现的更高级的业务框架。
下面以Power managment 为例来说明这种层次结构的更详细的细节，以更好的理解Vehicle 业务框架。
android automotive power managment的类图如下：
![automotive_power_management_arch](http://ovfro7ddi.bkt.clouddn.com/android%20automotive%20powermanagement%20arch.png)

### CarAPI
Car类是Vehicle 的 API层的具体实现。Car 通过aidl最终与CarService进行进程间通信。
用户可使用如下代码使用Car的API:
```java
// 1.首先调用静态方法createCar创建Car对象
Car car = Car.createCar(getContext(), mConnectionListener);
// 2.连接Car service.
car.connect();
waitForConnection(DEFAULT_WAIT_TIMEOUT_MS);
// 3.通过名字获取对应的manager对象。
CarSensorManager carSensorManager =
(CarSensorManager) car.getCarManager(Car.SENSOR_SERVICE);
// 4.调用具体manager对象的方法
carSensorManager.isSensorSupported(CarSensorManager.SENSOR_TYPE_CAR_SPEED);
```
Car 类中有两个重要的成员变量
```java
private ICar mService;
private final HashMap<String, CarManagerBase> mServiceMap = new HashMap<>();
```
- mService 是CarService的客户端，ICar.aidl定义如下：
```java
interface ICar {
IBinder getCarService(in String serviceName) = 0;
int getCarConnectionType() = 1;
}
```
当调用getCarManager时会调用到mService的getCarService方法，再使用service name 与返回的对应Service的IBinder对象，一同创建出client端的manager对象。
- mServiceMap 用来保存getCarManager创建出的manager对象，当再次需要获取该manager时即从此map中返回。
接下来CarService [Android O Vehicle之Car Service]()
