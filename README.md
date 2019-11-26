# awesome-kubernetes-notes

---

[![Documentation Status](https://readthedocs.org/projects/awesome-kubernetes-notes/badge/?version=latest)](https://awesome-kubernetes-notes.readthedocs.io/en/latest/?badge=latest) 

# 目的
为方便更多k8s爱好者更系统性的学习文档，利用`sphinx`将笔记整理构建程在线文档，方便学习交流
本文 [awesome-kubernetes-notes](https://github.com/redhatxl/awesome-kubernetes-notes)

个人信息：
- [GitHub](https://github.com/redhatxl)
- [掘金](https://juejin.im/user/5c36033fe51d456e4138b473/posts)
- [慕课网](https://www.imooc.com/u/1260704)

> awesome-kubernetes-notes：[在线阅读](https://awesome-kubernetes-notes.readthedocs.io/en/latest/)

---

# 目录

* ## [一 Kubernetes概述](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#kubernetes)
    * ##### 1.1 容器编排工具
    * ##### 1.2 kubernetes
    * ##### 1.3 环境架构
    * ##### 1.4 架构和组件
* ## [二 核心组件/附件](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#id5)
    * ##### 2.1 Controller
    * ##### 2.2 Service
    * ##### 2.3 网络模型
    * ##### 2.4 kube-proxy
    * ##### 2.5 etcd
    * ##### 2.6 flanel
* ## [三 集群部署](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#id8)
    * ##### 3.1 部署前准备
    * ##### 3.2 部署 Master
    * ##### 3.3 部署 Node
* ## [四 入门命令](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#id15)
    * ##### 4.1 kubectl
    * ##### 4.2 run
    * ##### 4.3 expose
    * ##### 4.4 cp
    * ##### 4.5 port-forward
    * ##### 4.6 coredns
    * ##### 4.7模拟 POD 被删除
    * ##### 4.8 模拟 service 被删除
    * ##### 4.9 labels
    * ##### 4.10 动态扩容
    * ##### 4.11 滚动升级
    * ##### 4.12 集群外访问
    * ##### 4.13 排查日志
    * ##### 4.14 连入 POD 容器
* ## [五 配置清单使用](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#id22)
    * ##### 5.1 可配置的对象
    * ##### 5.2 配置清单组成
    * ##### 5.3 获取清单帮助
    * ##### 5.4 清单基本格式
    * ##### 5.5 快捷获取清单
    * ##### 5.6 create 创建
    * ##### 5.7 delete 删除
    * ##### 5.8 applay 创建或更新
* ## [六 POD 配置清单](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#id28)
    * ##### 6.1 pods.metadata POD元数据
    * ##### 6.2 pods.spec 规范
* ## [七 控制器配置清单](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#id31)
    * ##### 7.1 ReplicaSet 控制器
    * ##### 7.2 Deployment控制器
    * ##### 7.3 DaemonSet控制器
* ## [八 Service 配置清单](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#id44)
    * ##### 8.1 Service 工作模式
    * ##### 8.2 Service 类型
    * ##### 8.3 资源记录
    * ##### 8.4 Service 清单
    * ##### 8.5 service.spec 规范
    * ##### 8.6 ClusterIP 类型的 service
    * ##### 8.7 NodePort 类型的 service
    * ##### 8.8 loadBalancerIP 类型
    * ##### 8.9 无集群地址的 Service
    * ##### 8.10 externalName 类型
* ## [九 ingress 控制器](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#ingress)
    * ##### 9.1 ingress.spec 规范
    * ##### 9.2 ingress-nginx 代理
    * ##### 9.3 ingress-tomcat 代理
* ## [十 POD 存储卷](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#id50)
    * ##### 10.1 卷的类型
    * ##### 10.2 容器挂载选项
    * ##### 10.3 节点存储
    * ##### 10.4 网络存储
    * ##### 10.5 分布式存储
    * ##### 10.6 StorageClass Ceph RBD
* ## [十一 配置信息容器化](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#id57)
    * ##### 11.1 POD 获取环境变量
    * ##### 11.2 configMap
    * ##### 11.3 secret
* ## [十二 StatefulSet 控制器](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#statefulset)
    * ##### 12.1 清单格式
    * ##### 12.2 创建 NFS PV
    * ##### 12.3 创建 statefulSet
    * ##### 12.4 扩容和升级
* ## [十三 用户认证系统](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#id65)
    * ##### 13.1 用户的类型
    * ##### 13.2 POD如何连接集群
    * ##### 13.3 serviceaccount 对象
    * ##### 13.4 kubectl 配置文件
    * ##### 13.5 添加证书用户到 config
    * ##### 13.6 创建新 config 文件
    * ##### 13.7 基于 token 认证
* ## [十四 用户权限系统](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#id73)
    * ##### 14.1 权限列表
    * ##### 14.2 创建 Role
    * ##### 14.3 创建 rolebinding
    * ##### 14.4 创建 clusterrole
    * ##### 14.5 创建 clusterrolebinding
    * ##### 14.6 rolebinding 与 clusterrole
    * ##### 14.7 RBAC授权
* ## [十五 dashboard](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#dashboard)
    * ##### 15.1 部署流程
    * ##### 15.2 使用令牌登录
    * ##### 15.3 分级管理
    * ##### 15.4 配置文件认证
* ## [十六 网络通信](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#id79)
    * ##### 16.1 通信模型
    * ##### 16.2 通信模型底层
    * ##### 16.3 K8S 名称空间
    * ##### 16.4 K8S网络拓扑
    * ##### 16.5 flannel
    * ##### 16.6 Calico
* ## [十七 调度策略](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#id89)
    * ##### 17.1 POD创建流程
    * ##### 17.2 Service创建过程
    * ##### 17.3 资源限制维度
    * ##### 17.4 Scheduler 调度过程
    * ##### 17.4 预选因素
    * ##### 17.5 优选函数
    * ##### 17.6 选择函数
* ## [十八 高级调度设置](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#id96)
    * ##### 18.1 节点选择器
    * ##### 18.2 对节点的亲和性
    * ##### 18.3 对 POD 的亲和性
    * ##### 18.4 对 POD 的反亲和性
    * ##### 18.5 node 污点
    * ##### 18.6 POD 污点容忍
* ## [十九 容器资源限制](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#id103)
    * ##### 19.1 资源限制
    * ##### 19.2 qos 质量管理
* ## [二十 HeapSter监控（废弃中)](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#heapster)
    * ##### 20.1 安装 influx DB
    * ##### 20.2 安装 HeapSter
    * ##### 20.3 安装 Grafana
* ## [二十一 新一代监控架构](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#id106)
    * ##### 21.1 核心指标流水线
    * ##### 21.2监控流水线
    * ##### 21.3 安装 metrics-server
    * ##### 21.4 安装 prometheus
    * ##### 21.5 HPA命令行方式
    * ##### 21.6 HPA清单
* ## [二十二 K8S包管理器](https://kubernetes-note.readthedocs.io/en/latest/Kubernetes-note.html#id110)
    * ##### 22.1 基础概念
    * ##### 22.2 Helm 工作原理
    * ##### 22.3 部署 Helm
    * ##### 22.4 Chart文件组织
    * ##### 22.5 使用 Helm + Ceph 部署 EFK
    * ##### 22.6 Storage Class
    * ##### 22.7 Helm Elasticsearch
    * ##### 22.8 Helm fluentd-elasticsearch
    * ##### 22.9 Helm kibana
    
---
    
## 学习链接
#### 文档
* [Kubernetes官网教程](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
* [Kubernetes中文社区](https://www.kubernetes.org.cn/k8s)
* [从Kubernetes到Cloud Native](https://jimmysong.io/kubernetes-handbook/cloud-native/from-kubernetes-to-cloud-native.html)
* [Kubernetes Handbook](https://www.bookstack.cn/read/feiskyer-kubernetes-handbook/appendix-ecosystem.md)
* [Kubernetes从入门到实战](https://www.kancloud.cn/huyipow/kubernetes/722822)
* [Kubernetes指南](https://kubernetes.feisky.xyz/)
* [awesome-kubernetes](https://ramitsurana.github.io/awesome-kubernetes/)
* [从Docker到Kubernetes进阶](https://www.qikqiak.com/k8s-book/)
* [python微服务实战](https://www.qikqiak.com/tdd-book/)
* [云原生之路](https://jimmysong.io/kubernetes-handbook/cloud-native/from-kubernetes-to-cloud-native.html)
* [CNCF Cloud Native Interactive Landscape](https://landscape.cncf.io/)

#### 视频

* [马哥(docker容器技术+k8s集群技术)](https://www.bilibili.com/video/av35847195/?p=16&t=3931)
* [微服务容器化实战](https://www.acfun.cn/v/ac10232871)

---
如果此笔记对您有任何帮助，更多文章，欢迎关注博客一块学习交流🎉

扫一扫请我喝咖啡☕️

* 微信

![微信](https://raw.githubusercontent.com/redhatxl/awesome-kubernetes-notes/master/source/weixin.png)
* 支付宝

![支付宝](https://raw.githubusercontent.com/redhatxl/awesome-kubernetes-notes/master/source/zfb.png)
