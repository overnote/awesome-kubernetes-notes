三 集群部署
===========

为简单上手体验功能，可以先利用kubeadm安装测试，生产环境建议二进制或者一些成熟的集群高可用安装方式，Kubeadm
是 K8S 官方提供的快速部署工具，它提供了 kubeadm init 以及 kubeadm join
这两个命令作为快速创建 kubernetes 集群的最佳实践，本章节说明了使用
kubeadm 来部署 K8S 集群的过程。

-   集群组织结构

> 项目说明 -----------------------------------------------------
> 集群规模
> Master、node1、node2 系统 CentOS 7.3 网络规划
> POD：10.244.0.0/16、Service：10.96.0.0/12

3.1 部署前准备
--------------

> 本小节的所有的操作，在所有的节点上进行

### 3.1.1 关闭 firewalld 和 selinux

``` bash
setenforce 0
sed -i '/^SELINUX=/cSELINUX=disabled' /etc/selinux/config

systemctl stop firewalld
systemctl disable firewalld
```

### 3.1.2 加载 ipvs 内核模块

-   安装 IPVS 模块

``` bash
yum -y install ipvsadm ipset sysstat conntrack libseccomp
```

-   设置开机加载配置文件

``` bash
cat >>/etc/modules-load.d/ipvs.conf<<EOF
ip_vs_dh
ip_vs_ftp
ip_vs
ip_vs_lblc
ip_vs_lblcr
ip_vs_lc
ip_vs_nq
ip_vs_pe_sip
ip_vs_rr
ip_vs_sed
ip_vs_sh
ip_vs_wlc
ip_vs_wrr
nf_conntrack_ipv4
EOF
```

-   设置开机加载 IPVS 模块

``` bash
systemctl enable systemd-modules-load.service   # 设置开机加载内核模块
lsmod | grep -e ip_vs -e nf_conntrack_ipv4      # 重启后检查 ipvs 模块是否加载
```

-   如果集群已经部署在了 iptables 模式下，可以通过下面命令修改，修改
    mode 为 ipvs 重启集群即可。

``` bash
kubectl edit -n kube-system configmap kube-proxy
```

### 3.1.3 下载 Docker 和 K8S

-   设置 docker 源

``` bash
curl -o /etc/yum.repos.d/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

-   设置 k8s 源

``` bash
cat >>/etc/yum.repos.d/kuberetes.repo<<EOF
[kuberneres]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
enabled=1
EOF
```

-   安装 docker-ce 和 kubernetes

``` bash
yum install docker-ce kubelet kubectl kubeadm -y
```

``` bash
systemctl start docker
systemctl enable docker
systemctl enable kubelet
```

### 3.1.4 设置内核及 K8S 参数

-   设置内核参数

``` bash
cat >>/etc/sysctl.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
```

-   设置 kubelet 忽略 swap，使用 ipvs

``` bash
cat >/etc/sysconfig/kubelet<<EOF
KUBELET_EXTRA_ARGS="--fail-swap-on=false"
KUBE_PROXY_MODE=ipvs
EOF
```

3.2 部署 Master
---------------

> 本小节的所有的操作，只在 Master 节点上进行

### 3.2.1 提前拉取镜像

宿主机最好能访问国外资源，在kubeadm init 在初始化的时候会到谷歌的 docker
hub 拉取镜像，如果宿主机测试无法访问 k8s.gcr.io
可以在服务器所以我们要提前部署好代理软件，本例中监听个本机 9666
进行部署。

如果条件不允许可以参考:
<https://blog.csdn.net/jinguangliu/article/details/82792617>
来解决镜像问题。

-   配置 Docker 拉取镜像时候的代理地址，vim
    /usr/lib/systemd/system/docker.service。

``` bash
[Service]
Environment="HTTPS_PROXY=127.0.0.1:9666"
Environment="NO_PROXY=127.0.0.0/8,172.16.0.0/16"
```

-   提前拉取初始化需要的镜像

``` bash
kubeadm config images pull
```

-   使用其他源镜像

``` bash
docker pull mirrorgooglecontainers/kube-apiserver:v1.14.2
docker pull mirrorgooglecontainers/kube-controller-manager:v1.14.2
docker pull mirrorgooglecontainers/kube-scheduler:v1.14.2
docker pull mirrorgooglecontainers/kube-proxy:v1.14.2
docker pull mirrorgooglecontainers/pause:3.1
docker pull mirrorgooglecontainers/etcd:3.3.10
docker pull coredns/coredns:1.3.1


利用`kubeadm config images list` 查看需要的docker image name

k8s.gcr.io/kube-apiserver:v1.14.2
k8s.gcr.io/kube-controller-manager:v1.14.2
k8s.gcr.io/kube-scheduler:v1.14.2
k8s.gcr.io/kube-proxy:v1.14.2
k8s.gcr.io/pause:3.1
k8s.gcr.io/etcd:3.3.10
k8s.gcr.io/coredns:1.3.1

# 修改tag

docker tag docker.io/mirrorgooglecontainers/kube-apiserver:v1.14.2 k8s.gcr.io/kube-apiserver:v1.14.2
docker tag docker.io/mirrorgooglecontainers/kube-scheduler:v1.14.2 k8s.gcr.io/kube-scheduler:v1.14.2
docker tag docker.io/mirrorgooglecontainers/kube-proxy:v1.14.2 k8s.gcr.io/kube-proxy:v1.14.2
docker tag docker.io/mirrorgooglecontainers/kube-controller-manager:v1.14.2 k8s.gcr.io/kube-controller-manager:v1.14.2
docker tag docker.io/mirrorgooglecontainers/etcd:3.3.10  k8s.gcr.io/etcd:3.3.10
docker tag docker.io/mirrorgooglecontainers/pause:3.1  k8s.gcr.io/pause:3.1
docker tag docker.io/coredns/coredns:1.3.1  k8s.gcr.io/coredns:1.3.1

docker rmi `docker images |grep docker.io/ |awk '{print $1":"$2}'`
```

### 3.2.2 初始化Master

-   使用 kubeadm 初始化 k8s 集群

``` bash
kubeadm init --kubernetes-version=v1.14.0 --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12 --ignore-preflight-errors=Swap
```

-   如果有报错使用下面命令查看

``` bash
journalctl -xeu kubelet
```

-   如果初始化过程被中断可以使用下面命令来恢复

``` bash
kubeadm reset
```

-   下面是最后执行成功显示的结果，需要保存这个执行结果，以让 node
    节点加入集群

``` bash
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 172.16.100.9:6443 --token 2dyd69.hrfsjkkxs4stim7n \
    --discovery-token-ca-cert-hash sha256:4e30c1f41aefb177b708a404ccb7e818e31647c7dbdd2d42f6c5c9894b6f41e7
```

-   最好以普通用户的身份运行下面的命令

``` bash
# 在当前用户家目录下创建.kube目录并配置访问集群的config 文件
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

-   部署 flannel 网络插件

``` bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

-   查看 kube-system 命名空间中运行的 pods

``` bash
kubectl get pods -n kube-system
```

-   查看 k8s 集群组件的状态

``` bash
kubectl get ComponentStatus
```

-   配置命令补全

``` bash
yum install -y bash-completion
source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
```

3.3 部署 Node
-------------

> 本小节的所有的操作，只在 Node 节点上进行。

### 3.3.1 加入集群

-   加入集群，注意在命令尾部加上 --ignore-preflight-errors=Swap ，以忽略
    k8s 对主机 swap 的检查（k8s为了性能所以要求进制 swap ）

``` bash
kubeadm join 172.16.100.9:6443 --token 2dyd69.hrfsjkkxs4stim7n \
    --discovery-token-ca-cert-hash sha256:4e30c1f41aefb177b708a404ccb7e818e31647c7dbdd2d42f6c5c9894b6f41e7 --ignore-preflight-errors=Swap
```

-   返回结果，表示加入集群成功

``` bash
This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```

### 3.3.2 查看进度

当 node 节点加入 K8S 集群中后，Master 会调度到 Node
节点上一些组件，用于处理集群事务，这些组件没有下载完成之前 Node
节点在集群中还是未就绪状态

-   在 node 执行下面命令，可以查看镜像的下载进度，下面是最终结果显示

``` bash
$ docker image ls
REPOSITORY               TAG                 IMAGE ID            CREATED             SIZE
k8s.gcr.io/kube-proxy    v1.14.0             5cd54e388aba        6 weeks ago         82.1MB
quay.io/coreos/flannel   v0.11.0-amd64       ff281650a721        3 months ago        52.6MB
k8s.gcr.io/pause         3.1                 da86e6ba6ca1        16 months ago       742kB
```

-   可以在 Master 上使用下面命令来查看新加入的节点状态

``` bash
$ kubectl get nodes
NAME     STATUS   ROLES    AGE     VERSION
master   Ready    master   3d21h   v1.14.1
node1    Ready    <none>   3d21h   v1.14.1
node2    Ready    <none>   3d21h   v1.14.1
```

-   查看集群状态

``` bash
[root@master ~]# kubectl cluster-info 
Kubernetes master is running at https://10.234.2.204:6443
KubeDNS is running at https://10.234.2.204:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://10.234.2.204:6443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
[root@master ~]# kubectl get componentstatuses
NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok                  
scheduler            Healthy   ok                  
etcd-0               Healthy   {"health":"true"}   
```

如果嫌网络pull镜像慢可以在一台上面将镜像打包发送至其他node节点

    拷贝到node节点
    for i in /tmp/*.tar; do scp -i $i root@172.16.0.15:/root/;done


    node节点还原
    for i in *.tar ;do docker load -i $i;done

-   查看 kube-system 这个 k8s
    命名空间中有哪些组件，分别运行在哪个节点，-o wide 是以详细方式显示。

```bash
$ kubectl get pods -n kube-system -o wide

NAME                                 READY   STATUS    RESTARTS   AGE     IP              NODE         NOMINATED NODE   READINESS GATES
coredns-fb8b8dccf-cp24r              1/1     Running   0          26m     10.244.0.2      i-xeahpl98   <none>           <none>
coredns-fb8b8dccf-ljswp              1/1     Running   0          26m     10.244.0.3      i-xeahpl98   <none>           <none>
etcd-i-xeahpl98                      1/1     Running   0          25m     172.16.100.9    i-xeahpl98   <none>           <none>
kube-apiserver-i-xeahpl98            1/1     Running   0          25m     172.16.100.9    i-xeahpl98   <none>           <none>
kube-controller-manager-i-xeahpl98   1/1     Running   0          25m     172.16.100.9    i-xeahpl98   <none>           <none>
kube-flannel-ds-amd64-crft8          1/1     Running   3          16m     172.16.100.6    i-me87b6gw   <none>           <none>
kube-flannel-ds-amd64-nckw4          1/1     Running   0          6m41s   172.16.100.10   i-qhcc2owe   <none>           <none>
kube-flannel-ds-amd64-zb7sg          1/1     Running   0          23m     172.16.100.9    i-xeahpl98   <none>           <none>
kube-proxy-7kjkf                     1/1     Running   0          6m41s   172.16.100.10   i-qhcc2owe   <none>           <none>
kube-proxy-c5xs2                     1/1     Running   2          16m     172.16.100.6    i-me87b6gw   <none>           <none>
kube-proxy-rdzq2                     1/1     Running   0          26m     172.16.100.9    i-xeahpl98   <none>           <none>
kube-scheduler-i-xeahpl98            1/1     Running   0          25m     172.16.100.9    i-xeahpl98   <none>           <none>
```

### 3.3.3 镜像下载太慢

node 节点需要翻墙下载镜像太慢，建议使用 docker 镜像的导入导出功能
先将master的三个镜像打包发送到node节点，load后再jion

-   导出

``` bash
docker image save -o /tmp/kube-proxy.tar k8s.gcr.io/kube-proxy
docker image save -o /tmp/flannel.tar quay.io/coreos/flannel
docker image save -o /tmp/pause.tar k8s.gcr.io/pause
```

-   导入

``` bash
docker image load -i /tmp/kube-proxy.tar
docker image load -i /tmp/pause.tar
docker image load -i /tmp/flannel.tar
```
