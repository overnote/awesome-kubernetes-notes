二 核心组件/附件
================

2.1 Controller
--------------

controller manager 是只运行在 master 节点上面的特殊容器

Examples of controllers that ship with Kubernetes today are the replication controller, endpoints controller, namespace controller, and serviceaccounts controller.

这些控制器分别用于确保不同类型的 POD 资源运行于符合用户所期望的状态。

-   RelicationController

控制同一类 POD 对象的副本数量，实现程序的滚动更新，或者回滚的操作。

在滚动更新时候，允许临时超出规定的副本数量，

- Node Controller

Responsible for noticing and responding when nodes go down

- Endpoints Controller

Populates the Endpoints object (that is, joins Services & Pods)

- Service Account & Token Controllers

Create default accounts and API access tokens for new namespaces

参考链接：
[Kubernetes组件](https://kubernetes.io/docs/concepts/overview/components/)

### 杀容器的过程

```go
// killContainer kills a container through the following steps:
// * Run the pre-stop lifecycle hooks (if applicable).
// * Stop the container.
func (m *kubeGenericRuntimeManager) killContainer(pod *v1.Pod, containerID kubecontainer.ContainerID, containerName string, message string, gracePeriodOverride *int64) error {
	var containerSpec *v1.Container
	if pod != nil {
		if containerSpec = kubecontainer.GetContainerSpec(pod, containerName); containerSpec == nil {
			return fmt.Errorf("failed to get containerSpec %q(id=%q) in pod %q when killing container for reason %q",
				containerName, containerID.String(), format.Pod(pod), message)
		}
	} else {
		// Restore necessary information if one of the specs is nil.
		restoredPod, restoredContainer, err := m.restoreSpecsFromContainerLabels(containerID)
		if err != nil {
			return err
		}
		pod, containerSpec = restoredPod, restoredContainer
	}

	// From this point, pod and container must be non-nil.
	gracePeriod := int64(minimumGracePeriodInSeconds)
	switch {
	case pod.DeletionGracePeriodSeconds != nil:
		gracePeriod = *pod.DeletionGracePeriodSeconds
	case pod.Spec.TerminationGracePeriodSeconds != nil:
		gracePeriod = *pod.Spec.TerminationGracePeriodSeconds
	}

	if len(message) == 0 {
		message = fmt.Sprintf("Stopping container %s", containerSpec.Name)
	}
	m.recordContainerEvent(pod, containerSpec, containerID.ID, v1.EventTypeNormal, events.KillingContainer, message)

	// Run internal pre-stop lifecycle hook
	if err := m.internalLifecycle.PreStopContainer(containerID.ID); err != nil {
		return err
	}

	// Run the pre-stop lifecycle hooks if applicable and if there is enough time to run it
	if containerSpec.Lifecycle != nil && containerSpec.Lifecycle.PreStop != nil && gracePeriod > 0 {
		gracePeriod = gracePeriod - m.executePreStopHook(pod, containerID, containerSpec, gracePeriod)
	}
	// always give containers a minimal shutdown window to avoid unnecessary SIGKILLs
	if gracePeriod < minimumGracePeriodInSeconds {
		gracePeriod = minimumGracePeriodInSeconds
	}
	if gracePeriodOverride != nil {
		gracePeriod = *gracePeriodOverride
		klog.V(3).Infof("Killing container %q, but using %d second grace period override", containerID, gracePeriod)
	}

	klog.V(2).Infof("Killing container %q with %d second grace period", containerID.String(), gracePeriod)

	err := m.runtimeService.StopContainer(containerID.ID, gracePeriod)
	if err != nil {
		klog.Errorf("Container %q termination failed with gracePeriod %d: %v", containerID.String(), gracePeriod, err)
	} else {
		klog.V(3).Infof("Container %q exited normally", containerID.String())
	}

	m.containerRefManager.ClearRef(containerID)

	return err
}
```

2.2 Service
-----------

为客户端提供一个稳定的访问入口，Service 靠标签选择器来关联 POD 的，只要
POD 上有相关的标签，那么就会被 Service 选中，作为 Service
的后端，Service 关联 POD 后会动态探测这个 POD 的 IP
地址和端口，并作为自己调度的后端。

总的来说客户端请求 Service 由 Service 代理至后端的
POD，所以客户端看到的始终是 Service 的地址。

K8S 上的 Service 不是一个应用程序，也不是一个组件，它是一个 iptables
dnat 规则，或者 ipvs 规则，Service 只是规则，所以是 ping
不通的，由于是dnat规则或是ipvs规则，可以使用利用端口进行测试

Service 作为 k8s 的对象来说，是有名称的，可以通过 Service 的名称解析为
Service 的 IP 地址

一般格式: `svcname.namespace.svc.cluster.local`, 如果在同一个 namespace
中可以直接使用 svcname , 如果不在同一个 namespace 中,
需要写完整的FQDN域名。

-   AddOns

解析域名是由 DNS 来解析的，为 k8s
中提供域名解析这种基础服务，称之为基础架构 POD 也称为 k8s
附件，所以域名解析的 POD 就是 k8s 中的一种 AddOns。

而 k8s 中的 dns 附件，是动态的，例如：service 名称发生更改，就会自动触发
dns 中的解析记录的改变，如果手动修改 service 的地址，也会自动触发 DNS
解析记录的改变，所以客户端访问服务时，可以直接访问服务的名称。

2.3 其他常用资源
-----------

-   RelicaSet

副本集控制器，它不直接使用，它有一个声明式中心控制器 Deployment

-   Deployment

它只能管理无状态的应用，这个控制器，支持二级控制器，例如：HPA（Horizontal
Pod Autoscaler，水平 POD
自动伸缩控制器），当负载高的时候，自动启动更多的 POD。

-   StatefulSet

管理有状态的应用

-   DaemonSet

如果需要在每一个 node 上运行一个副本，而不是随意运行

-   Job

运行一次性作业，时间不固定的操作，例如：备份、清理，临时启动一个 POD
来进行备份的任务，运行完成就结束了。

如果运行时候 JOB
挂了，那么需要重新启动起来，如果运行完成了则不需要再启动了。

-   Cronjob

运行周期性作业


2.4 网络模型
------------

k8s 有三种网络：POD网络、集群网络、节点网络

    POD网络：所有 POD 处于同一个网络中，叠加网络
    集群网络：Service 是一个另外一个网络
    节点网络：node 节点也是另外一个网络，宿主机的内网网络

所以，接入外部访问时候，请求首先到达 node 网络，然后 node 网络代理至
service 网络，service 根据 iptables/ipvs 规则来转发到 pod 网络中的 pod
上。 ~~~ NODE 网络 -> SVC 网络 -> POD 网络 ~~~

k8s 有三种通信：

-   同一个 POD 内的多个容器间的通信，可以通过 lo 通信直接通讯。
-   POD 与 POD 通信，如果使用 flannel 所有 POD 都处于一个网络，可以跨
    node 与另外的 POD 直接通信，因为使用了叠加网络。
-   POD 与 Service 通信。

2.5 kube-proxy
--------------

在 node 节点上运行的一个守护进程，它负责随时与 apiserver
进行通信，因为每个 pod 发生变化后需要保存在 apiserver 中，而 apiserver
发生改变后会生成一个通知事件，这个事件可以被任何关联的组件接收到，例如被
kube-proxy 一旦发现某个 service 后端的 pod 地址发生改变，那么就由
kube-proxy 负责在本地将地址写入 iptables 或者 ipvs 规则中。

所以 service 的管理是靠 kube-proxy 来实现的，当你创建一个 service
，那么就靠 kube-proxy 在每个节点上创建为 iptables 或者 ipvs 规则，每个
service 的变动也需要 kube-proxy 反应到规则上。

apiserver 需要保存各个 node 信息，它需要保存在 etcd 中。

2.6 etcd
--------

是一个键值存储的系统，与 redis 很像，但是 etcd 还有一些协调功能是 redis
所不具备的，它还有节点选举等功能，从这个角度来讲 etcd 更像 zookeeper。

由于整个集群的所有信息都保存在 etcd，所以 etcd
如果宕机，那么整个集群就挂了，因而 etcd 需要做高可用。

2.7 flanel
----------

托管为 k8s 的附件运行, 在 k8s 中有很多其他的开源网络插件，例如高性能的
calico 三层网络插件,性能很好，支持访问控制

node 网络：物理各节点之间进行通信

POD 网络：所有 node上的 POD 彼此之间通过叠加，或者直接路由方式通信

service 网络：由 kube-proxy 负责管控和生成

知识小结
--------

![](images/chapter_2/components-of-kubernetes.png)

-   Master

```{=html}
<!-- -->
```
    kube-scheduler             # 调度 pod
    kuber-controller-manager   # 管理 pod
    kube-apiserver             # 接收请求
    etcd                       # 集群状态存储，集群所有的组件的状态都保存在这里

-   node

```{=html}
<!-- -->
```
    kubelet                    # 节点/pod管理
    kube-proxy                 # watch apiserver管理service
    docker                     # 容器运行时
