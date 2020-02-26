六 集群故障管理
================

## 6.1 节点问题

### 6.1.1 删除节点的正确步骤

```bash
# SchedulingDisabled,确保新的容器不会调度到该节点
kubectl cordon $node
# 驱逐除了ds以外所有的pod
kubectl drain $node   --ignore-daemonsets
kubectl delete $node
```

### 6.1.2 维护节点的正确步骤

```bash
# SchedulingDisabled,确保新的容器不会调度到该节点
kubectl cordon $node
# 驱逐除了ds以外所有的pod
kubectl drain $node --ignore-daemonsets --delete-local-data
# 维护完成,恢复其正常状态
kubectl uncordon $node
```

--delete-local-data 是忽略 `emptyDir`这类的临时存储的意思

### 6.1.3  ImageGCFailed

> 
>   kubelet 可以清除未使用的容器和镜像。kubelet 在每分钟和每五分钟分别回收容器和镜像。
> 
>   [配置 kubelet 垃圾收集](https://k8smeetup.github.io/docs/concepts/cluster-administration/kubelet-garbage-collection/)

但是 kubelet 的垃圾回收有个问题,它只能回收那些未使用的镜像,有点像 `docker system prune`,然而观察发现,那些死掉的容器不是最大的问题,正在运行的容器才是更大的问题.如果ImageGCFailed一直发生,而容器使用的ephemeral-storage/hostpath(宿主目录)越发增多,最终将会导致更严重的DiskPressure问题,波及节点上所有容器.


建议:

1. 高配机器(4核32G以上)的docker目录配置100G SSD以上空间
1. 配置[ResourceQuota](https://kubernetes.io/docs/concepts/policy/resource-quotas/#storage-resource-quota)限制整体资源限额
1. 容器端禁用ephemeral-storage(本地文件写入),或者使用spec.containers[].resources.limits.ephemeral-storage限制,控制宿主目录写入

### 6.1.4 节点出现磁盘压力(DiskPressure)

```
--eviction-hard=imagefs.available<15%,memory.available<300Mi,nodefs.available<10%,nodefs.inodesFree<5%
```

kubelet在启动时指定了磁盘压力,以阿里云为例,`imagefs.available<15%`意思是说容器的读写层少于15%的时候,节点会被驱逐.节点被驱逐的后果就是产生DiskPressure这种状况,并且节点上再也不能运行任何镜像,直至磁盘问题得到解决.如果节点上容器使用了宿主目录,这个问题将会是致命的.因为你不能把目录删除掉,但是真是这些宿主机的目录堆积,导致了节点被驱逐.

所以,平时要养好良好习惯,容器里面别瞎写东西(容器里面写文件会占用ephemeral-storage,ephemeral-storage过多pod会被驱逐),多使用无状态型容器,谨慎选择存储方式,尽量别用hostpath这种存储

出现状况时,真的有种欲哭无泪的感觉.

```
Events:
  Type     Reason                 Age                   From                                            Message
  ----     ------                 ----                  ----                                            -------
  Warning  FreeDiskSpaceFailed    23m                   kubelet, node.xxxx1     failed to garbage collect required amount of images. Wanted to free 5182058496 bytes, but freed 0 bytes
  Warning  FreeDiskSpaceFailed    18m                   kubelet, node.xxxx1     failed to garbage collect required amount of images. Wanted to free 6089891840 bytes, but freed 0 bytes
  Warning  ImageGCFailed          18m                   kubelet, node.xxxx1     failed to garbage collect required amount of images. Wanted to free 6089891840 bytes, but freed 0 bytes
  Warning  FreeDiskSpaceFailed    13m                   kubelet, node.xxxx1     failed to garbage collect required amount of images. Wanted to free 4953321472 bytes, but freed 0 bytes
  Warning  ImageGCFailed          13m                   kubelet, node.xxxx1     failed to garbage collect required amount of images. Wanted to free 4953321472 bytes, but freed 0 bytes
  Normal   NodeHasNoDiskPressure  10m (x5 over 47d)     kubelet, node.xxxx1     Node node.xxxx1 status is now: NodeHasNoDiskPressure
  Normal   Starting               10m                   kube-proxy, node.xxxx1  Starting kube-proxy.
  Normal   NodeHasDiskPressure    10m (x4 over 42m)     kubelet, node.xxxx1     Node node.xxxx1 status is now: NodeHasDiskPressure
  Warning  EvictionThresholdMet   8m29s (x19 over 42m)  kubelet, node.xxxx1     Attempting to reclaim ephemeral-storage
  Warning  ImageGCFailed          3m4s                  kubelet, node.xxxx1     failed to garbage collect required amount of images. Wanted to free 4920913920 bytes, but freed 0 bytes
```

ImageGCFailed 是很坑爹的状态,出现这个状态时,表示 kubelet 尝试回收磁盘失败,这时得考虑是否要手动上机修复了.

建议:

1. 镜像数量在200以上时,采购100G SSD存镜像
1. 少用临时存储(empty-dir,hostpath之类的)

参考链接:

1. [Eviction Signals](https://kubernetes.io/docs/tasks/administer-cluster/out-of-resource/#eviction-signals)
1. [10张图带你深入理解Docker容器和镜像](http://dockone.io/article/783)


### 6.1.5 节点CPU彪高

有可能是节点在进行GC(container GC/image GC),用`describe node`查查.我有次遇到这种状况,最后节点上的容器少了很多,也是有点郁闷

```
Events:
  Type     Reason                 Age                 From                                         Message
  ----     ------                 ----                ----
  Warning  ImageGCFailed          45m                 kubelet, cn-shenzhen.xxxx  failed to get image stats: rpc error: code = DeadlineExceeded desc = context deadline exceeded
```

参考:

[kubelet 源码分析：Garbage Collect](https://cizixs.com/2017/06/09/kubelet-source-code-analysis-part-3/)

### 6.1.6 节点失联(unknown)

```
  Ready                False   Fri, 28 Jun 2019 10:19:21 +0800   Thu, 27 Jun 2019 07:07:38 +0800   KubeletNotReady              PLEG is not healthy: pleg was last seen active 27h14m51.413818128s ago; threshold is 3m0s

Events:
  Type     Reason             Age                 From                                         Message
  ----     ------             ----                ----                                         -------
  Warning  ContainerGCFailed  5s (x543 over 27h)  kubelet, cn-shenzhen.xxxx                    rpc error: code = DeadlineExceeded desc = context deadline exceeded
```
ssh登录主机后发现,docker服务虽然还在运行,但`docker ps`卡住了.于是我顺便升级了内核到5.1,然后重启.

后来发现是有个人上了一个问题镜像，无论在哪节点运行，都会把节点搞瘫，也是醉了。

unknown 是非常严重的问题,必须要予以重视.节点出现 unknown ,kubernetes master 自身不知道节点上面的容器是死是活,假如有一个非常重要的容器在 unknown 节点上面运行,而且他刚好又挂了,kubernetes是不会自动帮你另启一个容器的,这点要注意.

参考链接:

[Node flapping between Ready/NotReady with PLEG issues](https://github.com/kubernetes/kubernetes/issues/45419)
[深度解析Kubernetes Pod Disruption Budgets(PDB)](https://my.oschina.net/jxcdwangtao/blog/1594348)

### 6.1.7 SystemOOM

`SystemOOM` 并不一定是机器内存用完了.有一种情况是docker 在控制容器的内存导致的.

默认情况下Docker的存放位置为：/var/lib/docker/containers/$id

这个目录下面有个重要的文件: `hostconfig.json`,截取部分大概长这样:

```json
	"MemorySwappiness": -1,
	"OomKillDisable": false,
	"PidsLimit": 0,
	"Ulimits": null,
	"CpuCount": 0,
	"CpuPercent": 0,
	"IOMaximumIOps": 0,
	"IOMaximumBandwidth": 0
}
```

`"OomKillDisable": false,` 禁止了 docker 服务通过杀进程/重启的方式去和谐使用资源超限的容器,而是以其他的方式去制裁(具体的可以看[这里](https://docs.docker.com/config/containers/resource_constraints/))

### 6.1.8 docker daemon 卡住

这种状况我出现过一次,原因是某个容器有毛病,坑了整个节点.

出现这个问题要尽快解决,因为节点上面所有的 pod 都会变成 unknown .

```bash
systemctl daemon-reexec
systemctl restart docker(可选视情况定)
systemctl restart kubelet
```

严重时只能重启节点,停止涉事容器.

建议: `对于容器的liveness/readiness 使用tcp/httpget的方式，避免 高频率使用exec`

## 6.2 pod

### 6.2.1 pod频繁重启

原因有多种,不可一概而论

有一种情况是,deploy配置了健康检查,节点运行正常,但是因为节点负载过高导致了健康检查失败(load15长期大于2以上),频繁Backoff.我调高了不健康阈值之后,降低节点负载之后,问题解决

```yaml

          livenessProbe:
            # 不健康阈值
            failureThreshold: 3
            initialDelaySeconds: 5
            periodSeconds: 10
            successThreshold: 1
            tcpSocket:
              port: 8080
            timeoutSeconds: 1
```

### 6.2.2 资源达到limit设置值

调高limit或者检查应用

### 6.2.3 Readiness/Liveness connection refused

Readiness检查失败的也会重启,但是`Readiness`检查失败不一定是应用的问题,如果节点本身负载过重,也是会出现connection refused或者timeout

这个问题要上节点排查


### 6.2.4 pod被驱逐(Evicted)

1. 节点加了污点导致pod被驱逐
1. ephemeral-storage超过限制被驱逐
    1. EmptyDir 的使用量超过了他的 SizeLimit，那么这个 pod 将会被驱逐
    1. Container 的使用量（log，如果没有 overlay 分区，则包括 imagefs）超过了他的 limit，则这个 pod 会被驱逐
    1. Pod 对本地临时存储总的使用量（所有 emptydir 和 container）超过了 pod 中所有container 的 limit 之和，则 pod 被驱逐

ephemeral-storage是一个pod用的临时存储.
```
resources:
       requests: 
           ephemeral-storage: "2Gi"
       limits:
           ephemeral-storage: "3Gi"
```
节点被驱逐后通过get po还是能看到,用describe命令,可以看到被驱逐的历史原因

> Message:            The node was low on resource: ephemeral-storage. Container codis-proxy was using 10619440Ki, which exceeds its request of 0.


参考:
1. [Kubernetes pod ephemeral-storage配置](https://blog.csdn.net/hyneria_hope/article/details/79467922)
1. [Managing Compute Resources for Containers](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/)


### 6.2.5 kubectl exec 进入容器失败

这种问题我在搭建codis-server的时候遇到过,当时没有配置就绪以及健康检查.但获取pod描述的时候,显示running.其实这个时候容器以及不正常了.

```
~ kex codis-server-3 sh
rpc error: code = 2 desc = containerd: container not found
command terminated with exit code 126
```

解决办法:删了这个pod,配置`livenessProbe`


### 6.2.6 pod的virtual host name

`Deployment`衍生的pod,`virtual host name`就是`pod name`.

`StatefulSet`衍生的pod,`virtual host name`是`<pod name>.<svc name>.<namespace>.svc.cluster.local`.相比`Deployment`显得更有规律一些.而且支持其他pod访问


### 6.2.7 pod接连Crashbackoff

`Crashbackoff`有多种原因.

沙箱创建(FailedCreateSandBox)失败,多半是cni网络插件的问题

镜像拉取,有中国特色社会主义的问题,可能太大了,拉取较慢

也有一种可能是容器并发过高,流量雪崩导致.

比如,现在有3个容器abc,a突然遇到流量洪峰导致内部奔溃,继而`Crashbackoff`,那么a就会被`service`剔除出去,剩下的bc也承载不了那么多流量,接连崩溃,最终网站不可访问.这种情况,多见于高并发网站+低效率web容器.

在不改变代码的情况下,最优解是增加副本数,并且加上hpa,实现动态伸缩容.

### 6.2.8 DNS 效率低下

容器内打开nscd(域名缓存服务)，可大幅提升解析性能

严禁生产环境使用alpine作为基础镜像(会导致dns解析请求异常)

## 6.3 deploy

### 6.3.1 MinimumReplicationUnavailable

如果`deploy`配置了SecurityContext,但是api-server拒绝了,就会出现这个情况,在api-server的容器里面,去掉`SecurityContextDeny`这个启动参数.

具体见[Using Admission Controllers](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)

## 6.4 service

### 6.4.1 建了一个服务,但是没有对应的po,会出现什么情况?

请求时一直不会有响应,直到request timeout

参考

1. [Configure Out Of Resource Handling](https://kubernetes.io/docs/tasks/administer-cluster/out-of-resource/#node-conditions)


### 6.4.2 service connection refuse

原因可能有

1. pod没有设置readinessProbe,请求到未就绪的pod
1. kube-proxy宕机了(kube-proxy负责转发请求)
1. 网络过载


### 6.4.3 service没有负载均衡

检查一下是否用了`headless service`.`headless service`是不会自动负载均衡的...

```yaml
kind: Service
spec:
# clusterIP: None的即为`headless service`
  type: ClusterIP
  clusterIP: None
```

具体表现service没有自己的虚拟IP,nslookup会出现所有pod的ip.但是ping的时候只会出现第一个pod的ip

```bash
/ # nslookup consul
nslookup: can't resolve '(null)': Name does not resolve

Name:      consul
Address 1: 172.31.10.94 172-31-10-94.consul.default.svc.cluster.local
Address 2: 172.31.10.95 172-31-10-95.consul.default.svc.cluster.local
Address 3: 172.31.11.176 172-31-11-176.consul.default.svc.cluster.local

/ # ping consul
PING consul (172.31.10.94): 56 data bytes
64 bytes from 172.31.10.94: seq=0 ttl=62 time=0.973 ms
64 bytes from 172.31.10.94: seq=1 ttl=62 time=0.170 ms
^C
--- consul ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.170/0.571/0.973 ms

/ # ping consul
PING consul (172.31.10.94): 56 data bytes
64 bytes from 172.31.10.94: seq=0 ttl=62 time=0.206 ms
64 bytes from 172.31.10.94: seq=1 ttl=62 time=0.178 ms
^C
--- consul ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.178/0.192/0.206 ms
```


普通的type: ClusterIP service,nslookup会出现该服务自己的IP

```BASH
/ # nslookup consul
nslookup: can't resolve '(null)': Name does not resolve

Name:      consul
Address 1: 172.30.15.52 consul.default.svc.cluster.local
```


## 6.5 ReplicationController

### 6.5.1 不更新

ReplicationController不是用apply去更新的,而是`kubectl rolling-update`,但是这个指令也废除了,取而代之的是`kubectl rollout`.所以应该使用`kubectl rollout`作为更新手段,或者懒一点,apply file之后,delete po.

尽量使用deploy吧.

## 6.6 StatefulSet

### 6.6.1 pod 更新失败

StatefulSet是逐一更新的,观察一下是否有`Crashbackoff`的容器,有可能是这个容器导致更新卡住了,删掉即可.

### 6.6.2 unknown pod

如果 StatefulSet 绑定 pod 状态变成 unknown ,这个时候是非常坑爹的,StatefulSet不会帮你重建pod.

这时会导致外部请求一直失败.

综合建议,不用 `StatefulSet` ,改用 operator 模式替换它.

## 6.7 HPA

HPA Controller会通过调整副本数量使得CPU使用率尽量向期望值靠近，而且不是完全相等．另外，官方考虑到自动扩展的决策可能需要一段时间才会生效：例如当pod所需要的CPU负荷过大，从而在创建一个新pod的过程中，系统的CPU使用量可能会同样在有一个攀升的过程。所以，在每一次作出决策后的一段时间内，将不再进行扩展决策。对于扩容而言，这个时间段为3分钟，缩容为5分钟。

HPA Controller中有一个tolerance（容忍力）的概念，它允许一定范围内的使用量的不稳定，现在默认为0.1，这也是出于维护系统稳定性的考虑。例如，设定HPA调度策略为cpu使用率高于50%触发扩容，那么只有当使用率大于55%或者小于45%才会触发伸缩活动，HPA会尽力把Pod的使用率控制在这个范围之间。

具体的每次扩容或者缩容的多少Pod的算法为：

```
        Ceil(前采集到的使用率 / 用户自定义的使用率) * Pod数量)
```

每次最大扩容pod数量不会超过当前副本数量的2倍

参考链接：
[Kubernetes 中 Pod 弹性伸缩详解与使用](https://cloud.tencent.com/developer/article/1005406)

## 6.8 阿里云Kubernetes问题

### 6.8.1 修改默认ingress

新建一个指向ingress的负载均衡型svc,然后修改一下`kube-system`下`nginx-ingress-controller`启动参数.

```
        - args:
            - /nginx-ingress-controller
            - '--configmap=$(POD_NAMESPACE)/nginx-configuration'
            - '--tcp-services-configmap=$(POD_NAMESPACE)/tcp-services'
            - '--udp-services-configmap=$(POD_NAMESPACE)/udp-services'
            - '--annotations-prefix=nginx.ingress.kubernetes.io'
            - '--publish-service=$(POD_NAMESPACE)/<自定义svc>'
            - '--v=2'
```

### 6.8.2 LoadBalancer服务一直没有IP

具体表现是EXTERNAL-IP一直显示pending.

```bash
~ kg svc consul-web
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)         AGE
consul-web   LoadBalancer   172.30.13.122   <pending>     443:32082/TCP   5m  
```

这问题跟[Alibaba Cloud Provider](https://yq.aliyun.com/articles/626066)这个组件有关,`cloud-controller-manager`有3个组件,他们需要内部选主,可能哪里出错了,当时我把其中一个出问题的`pod`删了,就好了.

### 6.8.3 清理Statefulset动态PVC

目前阿里云`Statefulset`动态PVC用的是nas。

1. 对于这种存储，需要先把容器副本将为0，或者整个`Statefulset`删除。
1. 删除PVC
1. 把nas挂载到任意一台服务器上面，然后删除pvc对应nas的目录。

### 6.8.4 升级到v1.12.6-aliyun.1之后节点可分配内存变少

该版本每个节点保留了1Gi,相当于整个集群少了N GB(N为节点数)供Pod分配.

如果节点是4G的,Pod请求3G,极其容易被驱逐.

建议提高节点规格.

```
Server Version: version.Info{Major:"1", Minor:"12+", GitVersion:"v1.12.6-aliyun.1", GitCommit:"8cb561c", GitTreeState:"", BuildDate:"2019-04-22T11:34:20Z", GoVersion:"go1.10.8", Compiler:"gc", Platform:"linux/amd64"}
```

### 6.8.5 新加节点出现NetworkUnavailable

RouteController failed to create a route

看一下kubernetes events,是否出现了

```
timed out waiting for the condition -> WaitCreate: ceate route for table vtb-wz9cpnsbt11hlelpoq2zh error, Aliyun API Error: RequestId: 7006BF4E-000B-4E12-89F2-F0149D6688E4 Status Code: 400 Code: QuotaExceeded Message: Route entry quota exceeded in this route table  
```

出现这个问题是因为达到了[VPC的自定义路由条目限制](https://help.aliyun.com/document_detail/27750.html),默认是48,需要提高`vpc_quota_route_entrys_num`的配额

### 6.8.6 访问LoadBalancer svc随机出现流量转发异常

见
[[bug]阿里云kubernetes版不检查loadbalancer service port,导致流量被异常转发](https://github.com/kubernetes/cloud-provider-alibaba-cloud/issues/57)
简单的说，同SLB不能有相同的svc端口，不然会瞎转发。

官方说法：
> 复用同一个SLB的多个Service不能有相同的前端监听端口，否则会造成端口冲突。


### 6.8.7 控制台显示的节点内存使用率总是偏大

[Docker容器内存监控](https://xuxinkun.github.io/2016/05/16/memory-monitor-with-cgroup/)

原因在于他们控制台用的是usage_in_bytes(cache+buffer),所以会比云监控看到的数字大


### 6.8.8 Ingress Controller 玄学优化

修改 kube-system 下面名为 nginx-configuration 的configmap

```
proxy-connect-timeout: "75" 
proxy-read-timeout: "75" 
proxy-send-timeout: "75" 
upstream-keepalive-connections: "300" 
upstream-keepalive-timeout: "300" 
upstream-keepalive-requests: "1000" 
keep-alive-requests: "1000" 
keep-alive: "300"
disable-access-log: "true" 
client-header-timeout: "75" 
worker-processes: "16"
```

注意,是一个项对应一个配置,而不是一个文件. 格式大概这样

```
➜  ~ kg cm nginx-configuration -o yaml
apiVersion: v1
data:
  disable-access-log: "true"
  keep-alive: "300"
  keep-alive-requests: "1000"
  proxy-body-size: 20m
  worker-processes: "16"
  ......
```

### 6.8.9 pid 问题

```
Message: **Liveness probe failed: rpc error: code = 2 desc = oci runtime error: exec failed: container_linux.go:262: starting container process caused "process_linux.go:86: adding pid 30968 to cgroups caused \"failed to write 30968 to cgroup.procs: write /sys/fs/cgroup/cpu,cpuacct/kubepods.slice/kubepods-burstable.slice/kubepods-burstable-podfe4cc065_cc58_11e9_bf64_00163e08cd06.slice/docker-0447a362d2cf4719ae2a4f5ad0f96f702aacf8ee38d1c73b445ce41bdaa8d24a.scope/cgroup.procs: invalid argument\""
```

阿里云初始化节点用的 centos 版本老旧,内核是3.1, Centos7.4的内核3.10还没有支持cgroup对于pid/fd限制,所以会出现这类问题.

建议:

1. 手动维护节点,升级到5.x的内核(目前已有一些节点升级到5.x,但是docker版本还是 17.6.2 ,持续观察中~)
1. 安装 [NPD](https://github.com/AliyunContainerService/node-problem-detector) + [eventer](https://github.com/AliyunContainerService/kube-eventer) ,利用事件机制提醒管理员手动维护

### 6.8.10 OSS PVC FailedMount

可以通过PV制定access key,access secret +PVC的方式使用OSS.某天某个deploy遇到 FailedMount 的问题,联系到阿里云的开发工程师,说是 flexvolume 在初次运行的节点上面运行会有问题,要让他"重新注册"

影响到的版本: registry-vpc.cn-shenzhen.aliyuncs.com/acs/flexvolume:v1.12.6.16-1f4c6cb-aliyun

解决方案:

```bash
touch /usr/libexec/kubernetes/kubelet-plugins/volume/exec/alicloud~oss/debug
```

参考(应用调度相关):
1. [Kubernetes之健康检查与服务依赖处理](http://dockone.io/article/2587)
2. [kubernetes如何解决服务依赖呢？](https://ieevee.com/tech/2017/04/23/k8s-svc-dependency.html)
5. [Kubernetes之路 1 - Java应用资源限制的迷思](https://yq.aliyun.com/articles/562440?spm=a2c4e.11153959.0.0.5e0ed55aq1betz)
8. [Control CPU Management Policies on the Node](https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/#cpu-management-policies)
1. [Reserve Compute Resources for System Daemons](https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/)
1. [Configure Out Of Resource Handling](https://kubernetes.io/docs/tasks/administer-cluster/out-of-resource/)

**满意请打赏**

![微信支付宝合一](zeusro.jpg)