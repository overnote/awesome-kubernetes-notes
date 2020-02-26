
五 配置清单使用
===============

apiserver 仅接收 json 格式的资源定义，yaml
格式定义提供的配置清单，apiserver 可自动将其转换为 json
格式，而后再进行执行。

5.1 可配置的对象
----------------

-  可用资源清单配置的对象

.. code:: bash

   workload：Pod、ReplicaSet、Deployment、StatefulSet、DaemonSet、Job、CronJob
   服务发现及均衡：Service、Ingress
   配置与存储：Volume、CSI
       ConfigMap、Secret
       DownwardAPI
   集群级资源
       Namespace、None、Role、ClusterRole、RoleBinding、ClusterRoleBinding
   元数据类型资源
       HPA、PodTemplate、LimitRange

5.2 配置清单组成
----------------

-  配置清单组成部分，大部分资源使用配置清单方式来创建

.. code:: bash

   apiVersion
       # 以 "group/version" 形式指明，这个对象属于哪个 API 组（版本）
   kind:
       # 资源类别，标记创建什么类型的资源
   metadata:
       # 元数据内部是嵌套的字段
       # 定义了资源对象的名称、命名空间（k8s级别的不是系统的）等、标签、注解等
   spec:
       # 规范定义资源应该拥有什么样的特性，依靠控制器确保特性能够被满足
       # 它是用户定义的所期望了资源状态
   status:
       # 显示资源的当前状态，k8s 就是确保当前状态向目标状态无限靠近从而满足用户期望
       # 它是只读的，代表了资源当前状态

-  获取全部的 api 版本

.. code:: bash

   kubectl api-versions

-  获取全部的 api 资源对象

从内容可以看到一些缩写，方便我们日常命令后简写

.. code:: bash

   kubectl api-resources

   kubectl get po          # 查看pod
   kubectl get deploy      # 查看deployment
   kubectl get svc         # 查看service
   kubectl get cm          # 查看 configmap
   ...

5.3 获取清单帮助
----------------

-  查看 k8s 某个内置对象的配置清单格式，应该包含哪些字段，使用 .
   来显示字段的格式帮助信息

.. code:: bash

   kubectl explain pods
   kubectl explain pods.metadata

5.4 清单基本格式
----------------

-  定义一个资源清单

.. code:: bash

   apiVersion: v1
   kind: Pod
   metadata:
     name: pod-deme
     namespace: default
     labels:
       app: myapp
       tier: frontend
   spec:
     containers:
     - name: myapp
       image: ikubernetes/myapp:v1
     - name: busybox
       image: busybox:latest
       command:
       - "/bin/sh"
       - "-c"
       - "sleep 10"

5.5 快捷获取清单
----------------

-  使用 -o 参数来指定对象数据的输出格式，使用 –dry-run
   来测试性执行一个指令，它两个结合起来，就可以通过命令创建，且生成 yaml
   格式配置文件了 -o yaml –dry-run

.. code:: bash

   kubectl create secret docker-registry regsecret --docker-server=registry-vpc.cn-hangzhou.aliyuncs.com --docker-username=admin --docker-password=123456 --docker-email=420123641@qq.com -o yaml --dry-run

5.6 create 创建
---------------

-  创建资源清单中的资源，这样创建的为裸 POD
   ，没有控制器管理，所以删除后不会自动重建，成为自主式 POD

.. code:: bash

   kubectl create -f pod-demo.yaml

5.7 delete 删除
---------------

-  删除资源清单中定义的 POD

.. code:: bash

   kubectl delete -f pod-demo.yaml

5.8 apply 创建或更新
--------------------

apply 可以执行多次，如果发现文件不同，则更新

.. code:: bash

   kubectl apply -f pod-demo.yaml


## 5.9 pods.metadata POD元数据

### 5.9.1 labels 标签

-  labels 定义标签，键值对组成的标签

.. code:: bash

     labels:
       app: myapp
       tier: frontend

### 5.9.2 pods.spec 规范

#### 5.9.2.1 nodeName 运行节点

-  在使用资源清单定义 pod 时候，使用 nodeName 可以直接绑定资源对象在哪个
   POD 运行的节点

.. code:: yaml

   apiVersion: v1
   kind: Pod
   metadata:
     name: pod-deme
     namespace: default
     labels:
       app: myapp
       tier: frontend
   spec:
     nodeName: node2                           # 直接指定 POD 运行的节点
     containers:
     - name: myapp
       image: ikubernetes/myapp:v1
       imagePullPolicy: IfNotPresent

#### 5.9.2.2 nodeSelector 节点选择

-  在使用资源清单定义 pod 时候，使用 nodeSelector
   （节点标签选择器）字段，来定义节点的倾向性

.. code:: yaml

   apiVersion: v1
   kind: Pod
   metadata:
     name: pod-deme
     namespace: default
     labels:
       app: myapp
       tier: frontend
   spec:
     nodeSelector:                            # 在 spec 中定义这个 POD 的节点倾向性
       disktype: ssd                         # 这个 POD 最终会运行在拥有 disktype 标签且值为 ssd 的 nodes 上
     containers:
     - name: myapp
       image: ikubernetes/myapp:v1
       imagePullPolicy: IfNotPresent
       ports:

-  从文件启动 pod，观察 pod 运行的节点，会发现已经运行在有标签的 node
   节点上了

.. code:: bash

   kubectl create -f pod-demo.yaml

::

   kubectl get pods -o wide

.. code:: bash

   NAME       READY   STATUS    RESTARTS   AGE   IP            NODE    NOMINATED NODE   READINESS GATES
   pod-demo   1/1     Running   0          21s   10.244.2.29   node3   <none>           <none>

#### 5.9.2.3 restartPolicy POD重启策略

Always：一旦容器挂了，那么总是重启它，k8s 每次重启策略为 30
秒的两倍，直到等待 300 秒重启。

OnFailure：只有其状态为错误的时候才去重启它

Never：从来不重启，挂了就挂了

.. code:: bash

   一旦某个 POD 被调度到某个节点上，只要这个节点在，那么它就不会被重新调度，只能被重启，除非 POD 被删除才会被重新调度，或者 node 挂了，才会被重新调度，否则只要 node 在，那么 POD 就不会被重新调度，如果 POD 启动失败，那么将不断的重启 POD。

.. code:: bash

   当需要终止 POD ，k8s 发送 kill -15 信号，让容器平滑的终止，等待 30 秒的宽限期，如果没有终止，那么则发送 kill 信号

#### 5.9.2.4 hostNetwork 主机网络空间

使用布尔值指定是否让 POD 使用主机的网络名称空间

#### 5.9.2.5 hostPID 主机PID空间

使用布尔值指定是否让 POD 使用主机的PID名称空间

#### 5.9.2.6 containers 配置

   kubectl explain pods.spec.containers

描述 POD 内所运行容器，语法：containers
<[]Object>，表示它的值为数组，数组内使用对象的方式来描述一个容器，对象可以有以下参数：

-  可用参数

======================== ==================
参数                     作用
======================== ==================
args                    
command                 
env                      向容器传递环境变量
envFrom                 
image                   
imagePullPolicy         
lifecycle               
livenessProbe           
name                    
ports                   
readinessProbe          
resources               
securityContext         
stdin                   
stdinOnce               
terminationMessagePath  
terminationMessagePolicy
tty                     
volumeDevices           
volumeMounts            
workingDir              
======================== ==================

-  示例型配置

.. code:: bash

   apiVersion: v1
   kind: Pod
   metadata:
     name: pod-deme                     # pod 的名称
     namespace: default
     labels:
       app: myapp
       tier: frontend
   spec:
     containers:
       - name: myapp                      # 运行的容器名称
         image: ikubernetes/myapp:v1      # 容器的镜像
         imagePullPolicy: IfNotPresent    # 从仓库获取镜像的策略
         ports:                           # 定义容器暴漏的端口
       - name: busybox
         image: busybox:latest
         command:
           - "/bin/sh"
           - "-c"
           - "sleep 10"

#### 5.9.2.7 imagePullPolicy下载策略

-  imagePullPolicy
   镜像获取的策略，详见：\ ``kubectl explain pods.spec.containers``

.. code:: bash

   Always            # 总是从仓库下载
   Never             # 从不下载，本地有就用，没有就失败
   IfNotPresent      # 如果本地存在就直接使用，如果不存在就下载

..

   如果标签是 latest 那么则始终从仓库下载

#### 5.9.2.8 ports 端口信息

-  ports
   定义容器保暴露的，详见：\ ``kubectl explain pods.spec.containers.ports``

在此处暴露的端口可为系统提供有关容器的网络连接的信息，但主要是信息性的，此处没有指定的端口也不会阻止容器暴露该端口，容器中任何侦听
0.0.0.0 地址的端口都可以从网络访问

.. code:: yaml

       ports:                    # 定义两个端口对象一个 http 一个 https
       - name: http              # 定义这个端口的名称，方便别的对象取引用
         containerPort: 80       # 端口号
       - name: https             # 方便引用的名称
         containerPort: 443      # 这个端口号仅仅是起到信息的作用，方便查看和使用名称引用

#### 5.9.2.9 env 传递环境变量

.. code:: yaml

   在容器中获取 POD 的信息

   可以使用环境变量
   可以使用 downwardAPI
   https://kubernetes.io/zh/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/

#### 5.9.2.10 command ENTRYPOINT

-  command 定义容器运行的程序，详见：

一个 entrypoint array 而 command 启动的程序是不会运行在 Shell
中的，如果想要运行在 Shell
中需要自己填写，如果没有提供这个指令，那么将运行 docker 镜像中的
ENTRYPOINT。

#### 5.9.2.11 args CMD

-  args 向 command 传递参数的

如果你没有定义 args 而镜像中又存在 ENTRYPOINT 指令和 CMD
指令，那么镜像自己的 CMD 将作为参数传递给 ENTRYPOINT。如果手动指定了
args 那么镜像中的 CMD 字段不再作为参数进行传递。

如果在 args 中引用了变量，则需要使用 $(VAR_NAME)
来引用一个变量，如果不想在这里进行命令替换，那么可以
$$(VAR_NAME)，转义后在容器内使用。

### 5.9.3 annotations 注解信息

annotations 与 label
不同的地方在于，它不能用于挑选资源对象，仅为对象提供元数据，它的长度不受限制

.. code:: yaml

   apiVersion: v1
   kind: Pod
   metadata:
     name: pod-deme
     namespace: default
     labels:
       app: myapp
       tier: frontend
     annotations:                                      # 注解关键字
       kaliarch/created-by: "xuel"                     # 添加键值对的资源注解
   spec:
     containers:
     - name: myapp
       image: ikubernetes/myapp:v1
       imagePullPolicy: IfNotPresent

### 5.9.4 POD 生命周期

-  一般状态

.. code:: bash

   Pending：已经创建但是没有适合运行它的节点，已经调度，但是尚未完成
   Running：运行状态
   Failed： 启动失败
   Succeed：成功，这个状态很短
   Unkown： 未知的状态，如果 Apiserver 与 kubelet 通信失败则会处于这个状态

-  创建 POD 阶段

用户的创建请求提交给 apiserver ，而 apiserver 会将请求的目标状态保存在
etcd 中，而后 apiserver 会请求 schedule 进行调度，并且把调度的结果更新在
etcd 的 pod 状态中，随后一旦保存在 etcd 中，并完成 schedule
更新后目标节点的 kubelet 就会从 etcd
的状态变化得知有新任务给自己，所以此时会拿到用户所希望的资源清单目标状态，根据清单在当前节点运行这个
POD，如果创建成功或者失败，则将结果发回给 apiserver ，apiserver
再次保存在 etcd 中。

### 5.9.5 livenessProbe 存活性探测

   详细见：kubectl explain pods.spec.containers.livenessProbe

-  livenessProbe / readinessProbe 是 k8s
   两个生命周期，这两个生命周期都可以定义探针来探测容器状态做出不同反应

.. code:: bash

   livenessProbe     # 指示容器是否正在运行。如果存活探测失败，则依据 restartPolicy 策略来进行重启
   readinessProbe    # 指示容器是否准备好服务请求。如果就绪探测失败端点控制器将从与 Pod 匹配的所有 Service 的端点中删除该 Pod 的 IP 地址

-  livenessProbe / readinessProbe
   可用的探针和探针特性，探针只能定义一种类型，例如：HTTPGetAction

.. code:: bash

   exec          # 在容器内执行指定命令。如果命令退出时返回码为 0 则认为诊断成功。
   tcpSocket     # 对指定端口上的容器的 IP 地址进行 TCP 检查。如果端口打开，则诊断被认为是成功的。
   httpGet       # HTTP GET 请求指定端口和路径上的容器。如果响应码大于等于200 且小于 400，则诊断被认为是成功的。

.. code:: yaml

   failureThreshold    # 探测几次才判定为探测失败，默认为 3 次。
   periodSeconds       # 每次探测周期的间隔时长。
   timeoutSeconds      # 每次探测发出后等待结果的超时时间，默认为 1 秒。
   initalDelaySeconds  # 在容器启动后延迟多久去进行探测，默认为启动容器后立即探测。

-  使用 exec 探针，实验结果应该为 39 秒后 POD 显示 ERROR ，但不自动重启
   POD

.. code:: bash

   apiVersion: v1
   kind: Pod
   metadata:
     name: execlive
     namespace: default
     labels:
       app: myapp
       tier: frontend
   spec:
     containers:
       - name: busybox
         image: busybox
         command:
           - "/bin/sh"
           - "-c"
           - "touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 3600"    # 创建一个文件等待 30 秒，这个时间探针应该是成功的，30 秒后则失败
         livenessProbe:                                   # 容器的存活性检测，如果失败则按照 restartPolicy 策略来重启 POD
           exec:                                          # exec 类型探针，进入容器执行一条命令
             command: ["test", "-e" ,"/tmp/healthy"]      # 执行的命令为测试文件存在性
           initialDelaySeconds: 2                         # 容器启动后延迟多久进行探测
           periodSeconds: 3                               # 每次探测周期的间隔时长为 3 秒
           failureThreshold: 3                            # 3 次失败后则判定为容器探测存活性失败
     restartPolicy: Never                                 # 当探测到容器失败是否重启 POD

-  使用 httpGet 探针，实验结果应该大约 40 秒后探测存活性失败，自动重启
   POD，第一次重启会立即进行，随后是 30 秒的2倍直到 300 秒。

.. code:: yaml

   apiVersion: v1
   kind: Pod
   metadata:
     name: httpgetlive
     namespace: default
     labels:
       app: myapp
       tier: frontend
   spec:
     containers:
       - name: nginx
         image: ikubernetes/myapp:v1
         ports:
           - name: http
             containerPort: 80
           - name: https
             containerPort: 443
         livenessProbe:                   # 容器的存活性检测，如果失败则按照 restartPolicy 策略来重启 POD
           httpGet:                       # httpget 探针
             path: /error.html            # 探测的页面，为了效果这个页面不存在
             port: http                   # 探测的端口，使用名称引用容器的端口
             httpHeaders:                 # httpget 时候设置请求头
               - name: X-Custom-Header
                 value: Awesome
           initialDelaySeconds: 15        # 容器启动后延迟多久进行探测
           timeoutSeconds: 1              # 每次探测发出等待结果的时长
     restartPolicy: Always                # 当探测到容器失败是否重启 POD

### 5.9.6 readinessProbe 就绪性检测

例如有一个容器运行的是 tomcat ，而 tomcat 展开 war
包，部署完成的时间可能较长，而默认 k8s 会在容器启动就标记为 read
状态，接收 service 的调度请求，但是容器启动不代表 tomcat
已经成功运行，所以需要 readinessProbe 进行就绪性探测，来决定是否可以接入
service 上。

-  livenessProbe / readinessProbe
   可用的探针和探针特性基本一样，探针只能定义一种类型，例如：HTTPGetAction

.. code:: bash

   livenessProbe     # 指示容器是否正在运行。如果存活探测失败，则依据 restartPolicy 策略来进行重启
   readinessProbe    # 指示容器是否准备好服务请求。如果就绪探测失败端点控制器将从与 Pod 匹配的所有 Service 的端点中删除该 Pod 的 IP 地址

-  使用 httpGet 探针，实验结果应该大约 40 秒后探测存活性失败，自动重启
   POD，第一次重启会立即进行，随后是 30 秒的2倍直到 300 秒。

.. code:: yaml

   apiVersion: v1
   kind: Pod
   metadata:
     name: httpgetread
     namespace: default
     labels:
       app: myapp
       tier: frontend
   spec:
     containers:
       - name: nginx
         image: ikubernetes/myapp:v1
         ports:
           - name: http
             containerPort: 80
           - name: https
             containerPort: 443
         livenessProbe:                   # 容器的存活性检测，如果失败则按照 restartPolicy 策略来重启 POD
           httpGet:                       # httpget 探针
             path: /error.html            # 探测的页面，为了效果这个页面不存在
             port: http                   # 探测的端口，使用名称引用容器的端口
             httpHeaders:                 # httpget 时候设置请求头
               - name: X-Custom-Header
                 value: Awesome
           initialDelaySeconds: 15        # 容器启动后延迟多久进行探测
           timeoutSeconds: 1              # 每次探测发出等待结果的时长
     restartPolicy: Always                # 当探测到容器失败是否重启 POD

-  手动进入容器，删除 index.html 以触发就绪性探针的检测

.. code:: bash

   kubectl exec -it httpgetread -- /bin/sh
   $ rm -f /usr/share/nginx/html/index.html

-  结果这个 POD 的 READY 状态已经变成非就绪了，此时 service
   不会再调度到这个节点了

.. code:: bash

   [root@node1 ~]# kubectl get pods -w
   NAME                            READY   STATUS    RESTARTS   AGE
   httpgetread                     0/1     Running   0          2m50s

-  在容器内再创建一个文件，以触发就绪性探针的检测

.. code:: bash

   kubectl exec -it httpgetread -- /bin/sh
   $ echo "hello worlld" >>/usr/share/nginx/html/index.html

-  结果这个 POD 的的 READY 状态已经编程就绪了，此时 service
   会调度到这个节点了

.. code:: bash

   [root@node1 ~]# kubectl get pods -w
   NAME                            READY   STATUS    RESTARTS   AGE
   httpgetread                     1/1     Running   0          8m15s

### 5.9.7 lifecycle 生命周期钩子

   详见：kubectl explain pods.spec.containers.lifecycle

.. code:: bash

   postStart           # 在容器启动后立即执行的命令，如果这个操作失败了，那么容器会终止，且根据 restartPolicy 来决定是否重启
   preStop             # 在容器终止前立即执行的命令

-  postStart / preStop 的基本使用

.. code:: bash

   apiVersion: v1
   kind: Pod
   metadata:
     name: lifecycle-demo
   spec:
     containers:
     - name: lifecycle-demo-container
       image: nginx

       lifecycle:
         postStart:
           exec:
             command: ["/bin/sh", "-c", "echo Hello from the postStart handler > /usr/share/message"]
         preStop:
           exec:
             command: ["/usr/sbin/nginx","-s","quit"]

POD控制器

控制器管理的 POD 可以实现，自动维护 POD 副本数量，它能实现 POD
的扩容和缩容，但是不能实现滚的那个更新等高级功能。

+-----------------+----------------------------------------------------+
| 名称            | 作用                                               |
+=================+====================================================+
| ReplicationCont | 原来 k8s 只有这一种控制器，目前已经接近废弃        |
| roller          |                                                    |
+-----------------+----------------------------------------------------+
| ReplicaSet      | 代用户创建指定数量的 POD                           |
|                 | 副本，还支持扩缩容，被称为新一代的                 |
|                 | ReplicationController。主要由 3 个指标，1.         |
|                 | 用户希望的 POD 副本，2. 标签选择器，判定 POD       |
|                 | 是否归自己管理，3. 如果 POD 副本不够，按照哪个 POD |
|                 | template 创建 POD，但一般我们不直接使用            |
|                 | ReplicaSet。                                       |
+-----------------+----------------------------------------------------+
| Deployment      | Deployment 通过控制 ReplicaSet                     |
|                 | 来实现功能，除了支持 ReplicaSet                    |
|                 | 的扩缩容意外，还支持滚动更新和回滚等，还提供了声明式的配置，这个是我们日常使用最多的控制器。它是用来 |
|                 | 管理无状态的应用。                                 |
+-----------------+----------------------------------------------------+
| DaemonSet       | 用于确保集群内的每个 node 上只运行一个指定的       |
|                 | POD，如果有新增的节点也都会自动运行这个            |
|                 | POD，所以这个控制器无需定义 POD                    |
|                 | 运行的数量，只需要定义标签选择器和 POD             |
|                 | template。所以可以跟根据标签选择器选中的 node      |
|                 | 上只运行一个 POD 副本。                            |
+-----------------+----------------------------------------------------+
| Job             | 执行一个一次性任务，例如数据库备份，任务完成后正常退出，则 |
|                 |                                                    |
|                 | POD 不会再被启动了，除非任务异常终止。             |
+-----------------+----------------------------------------------------+
| CronJob         | 执行一些周期性任务                                 |
+-----------------+----------------------------------------------------+
| StatefulSet     | 管理有状态的 POD                                   |
|                 | ，但是对每个不同的有状态应用需要自行编写脚本，完成对有状态服务的管理，为了解决 |
|                 |                                                    |
|                 | StatefulSet 不方便编写有状态应用管理的问题。k8s    |
|                 | 还提供了 helm 这样类似于 yum 的方式，方便用户从    |
|                 | helm 市场来安装一个有状态的应用。                  |
+-----------------+----------------------------------------------------+
