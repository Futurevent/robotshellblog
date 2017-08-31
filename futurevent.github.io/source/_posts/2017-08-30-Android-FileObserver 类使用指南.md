---
title: Android FileObserver 类使用指南
tags:
    - android
categories:
    - android
---
有一种知识就是知道与不知道的区别，我们遇到的很多困难都是这种类型，不知道死活都想不到，知道了也就不过如此
最近我们的开发框架在做插件化的功能，用来已插件的形式加载场景和功能（这俩都是开发框架的概念），插件已一个独立apk的形式存在，放在固定的目录下不需要安装，框架启动时就会去加载apk中包裹的插件。有这么个需求，就是该目录下的这些个apk发生变动时 __新增__ , __删除__ , __更新__ 时，能够load或unload或reload 其中对应的插件，说白了就是监控这个目录的变化。
<!--more-->
进入正文

### inotify
本文要讲的是android 的 FileObserver类，而inotify则是该类功能实现所依赖的基础。
>Inotify 是一个 Linux 内核特性，它监控文件系统，并且及时向专门的应用程序发出相关的事件警告，比如删除、读、写和卸载操作等。您还可以跟踪活动的源头和目标等细节。
使用 inotify 很简单：创建一个文件描述符，附加一个或多个监视器（一个监视器 是一个路径和一组事件），然后使用 read 方法从描述符获取事件。read 并不会用光整个周期，它在事件发生之前是被阻塞的。

以上是百度百科对inotify的描述，FileObserver的原理大致就是如此，关于 inotify 了解到此即可。
### FileObserver
下面引用android源码中的注释，对于学习而言android的源码及源码的注释简直就是个巨大的宝藏
```java
/**
 * Monitors files (using <a href="http://en.wikipedia.org/wiki/Inotify">inotify</a>)
 * to fire an event after files are accessed or changed by by any process on
 * the device (including this one).  FileObserver is an abstract class;
 * subclasses must implement the event handler {@link #onEvent(int, String)}.
 *
 * <p>Each FileObserver instance monitors a single file or directory.
 * If a directory is monitored, events will be triggered for all files and
 * subdirectories inside the monitored directory.</p>
 *
 * <p>An event mask is used to specify which changes or actions to report.
 * Event type constants are used to describe the possible changes in the
 * event mask as well as what actually happened in event callbacks.</p>
 *
 * <p class="caution"><b>Warning</b>: If a FileObserver is garbage collected, it
 * will stop sending events.  To ensure you keep receiving events, you must
 * keep a reference to the FileObserver instance from some other live object.</p>
 */
 ```
FileObserver 可以监听的事件类型如下：

| 事件 | 说明 |
| :----- | :----- |
| ACCESS | 即文件被访问 |
| MODIFY | 文件被修改 |
| ATTRIB | 文件属性被修改，如 chmod、chown、touch 等 |
| CLOSE_WRITE | 可写文件被 close |
| CLOSE_NOWRITE | 不可写文件被 close |
| OPEN |文件被 open |
| MOVED_FROM | 文件被移走，如 mv |
| MOVED_TO | 文件被移来，如 mv、cp |
| CREATE | 创建新文件 |
| DELETE | 文件被删除，如 rm |
| DELETE_SELF | 自删除，即一个可执行文件在执行时删除自己 |
| MOVE_SELF | 自移动，即一个可执行文件在执行时移动自己 |
| CLOSE| 文件被关闭，等同于(IN_CLOSE_WRITE  IN_CLOSE_NOWRITE) |
| ALL_EVENTS | 包括上面的所有事件 |

 FileObserver的实现也很简单，创建自己的obsever类继承自FileObserver即可，只需重写唯一的一个abstract方法 onEvent 。示例如下：

 ```java
 class PluginFileObserver extends FileObserver {
    private static final String TAG = "PluginFileObserver";

    public static int PLUGIN_FILE_CHANGED = CREATE | DELETE | MODIFY | MOVED_FROM | MOVED_TO;

    private static ArrayList<PluginFileObserver> stubs = new ArrayList<>();

    private Context mContext;
    private String mPath;
    private int mMask;

    public PluginFileObserver(Context context, String path) {
        this(context, path, ALL_EVENTS);
    }

    public PluginFileObserver(Context context, String path, int mask) {
        super(path, mask);
        mContext = context;
        mPath = path;
        mMask = mask;
        stubs.add(this);
    }

    @Override
    public void onEvent(int event, String path) {
        Logger.i(TAG, "[PLUGIN] PluginFileObserver onEvent with event:" + event + " path:" + path);
        switch (event) {
            case FileObserver.CREATE:
            case FileObserver.MOVED_TO:
                Logger.i(TAG, "[PLUGIN] PluginFileObserver will add plugin: " + path);
                break;
            case FileObserver.DELETE:
            case FileObserver.MOVED_FROM:
                Logger.i(TAG, "[PLUGIN] PluginFileObserver will remove plugin: " + path);
                break;
            case FileObserver.MODIFY:
                Logger.i(TAG, "[PLUGIN] PluginFileObserver will update plugin: " + path);
                break;
            default:
                Logger.i(TAG, "[PLUGIN] PluginFileObserver don't care this event");
                break;
        }
    }
}
```

 使用也很简单，创建FileObserver对象，指定要监控的路径，指定监控的事件 ，调用startWatching()启动监控，使用完毕调用stopWatching()停止监控。

 ```java
 PluginFileObserver observer = new PluginFileObserver(mContext, pluginPath, PluginFileObserver.PLUGIN_FILE_CHANGED);
 //开始监控
observer.startWatching();
//停止监控
observer.stopWatching();
 ```

 ### 遇到一坑
 - 必须调用startWatching()方法，否则接收不到事件
 - 必须保证FileObserver对象不被GC回收，否则回收后接收不到事件
 - 指定路径如果是个目录，对目录下的子目录内内容变动，接收不到事件，不过可以递归创建子目录的FileObserver。
 - 有时候处理不当，会造成事件循环产生，先入死循环。
 - __最坑__ 当你把代码写好了，要进行测试了，连接上adb shell 后，修改下目录下的文件已用来测试，结果收不到事件。对的，在adb shell 下操作对应的文件，收不到事件，若要测试，最好直接操作设备的文件管理器或者写代码创建删除文件测试。
