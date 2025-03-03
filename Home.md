# Kubernetes Project: Comprehensive Step-by-Step Guide

# Table of Contents

## Day 1: Kubernetes Fundamentals and Basic Deployments
*   [1. Research Kubernetes](#1-research-kubernetes)
*   [2. Get Kubernetes running using Docker Desktop](#2-get-kubernetes-running-using-docker-desktop)
*   [3. Nginx Deployment with a NodePort Service](#3-nginx-deployment-with-a-nodeport-service)
*   [4. Observing Kubernetes Behaviors (Scaling and Self-Healing)](#4-observing-kubernetes-behaviors-scaling-and-self-healing)
*   [5. Deploying a Node.js “Sparta” Test App (with MongoDB)](#5-deploying-a-nodejs-sparta-test-app-with-mongodb)

## Day 2: Persistent Storage and Autoscaling
*   [1. Persistent storage for the database (MongoDB)](#1-persistent-storage-for-the-database-mongodb)
*   [2. Autoscaling: research and implementation](#2-autoscaling-research-and-implementation)

## Day 3: Deploying on a Cloud VM with Minikube and Advanced Networking
*   [1. Minikube setup on a cloud instance (Ubuntu 22.04 LTS)](#1-minikube-setup-on-a-cloud-instance-ubuntu-2204-lts)

---

This guide provides a structured **Day 1 – Day 3** walkthrough of setting up and experimenting with a Kubernetes cluster, deploying applications, and implementing advanced features like persistent storage and autoscaling. Each section expands on the tasks with detailed instructions, best practices, troubleshooting tips, YAML manifests, and illustrative diagrams.

## Day 1: Kubernetes Fundamentals and Basic Deployments

## 1. Research Kubernetes

### Why is Kubernetes needed?

Containers revolutionized software deployment by packaging applications with their dependencies, but running containers at scale introduced new challenges. As organizations began deploying hundreds or thousands of containers, they needed a system to automate scheduling, scaling, networking, and fault-tolerance. Simply using containers (e.g. with Docker alone) lacked **key capabilities** such as monitoring container health, re-scheduling failed containers, scaling out/in based on load, and service discovery​

[devtron.ai](https://devtron.ai/blog/why-use-kubernetes-for-container-orchestration/#:~:text=Managing%20containers%20for%20production%20is,capabilities%20were%20missing%2C%20such%20as)

​

[devtron.ai](https://devtron.ai/blog/why-use-kubernetes-for-container-orchestration/#:~:text=,variety%20of%20external%20data%20sources)

. Kubernetes was created to address these gaps. It is an open-source **container orchestration** platform that automates the management of containerized applications across clusters of machines. In essence, Kubernetes is needed to ensure that your application containers are **highly available, can scale on demand, and are resilient** to failures without manual intervention​

[devtron.ai](https://devtron.ai/blog/why-use-kubernetes-for-container-orchestration/#:~:text=Kubernetes%20not%20only%20addresses%20the,the%20platform%27s%20flexibility%20and%20utility)

​

[devtron.ai](https://devtron.ai/blog/why-use-kubernetes-for-container-orchestration/#:~:text=Kubernetes%20has%20become%20the%20de,and%20machines%20in%20a%20cluster)

.

### Benefits of Kubernetes

Kubernetes has become the de facto standard for container orchestration due to its numerous benefits. Key advantages include **automated scalability**, **self-healing**, and efficient resource utilization. Kubernetes can automatically **scale applications** up or down based on metrics like CPU/memory usage (Horizontal Pod Autoscaling), ensuring your app meets demand without over-provisioning​

[devtron.ai](https://devtron.ai/blog/why-use-kubernetes-for-container-orchestration/#:~:text=,packing%20containers%20efficiently%2C%20Kubernetes%20maximizes)

. It provides **high availability** by detecting failed containers/pods and rescheduling replacements automatically​

[devtron.ai](https://devtron.ai/blog/why-use-kubernetes-for-container-orchestration/#:~:text=,Amazon)

. Kubernetes is **cloud-agnostic and portable** – it runs on public clouds (AWS, Azure, GCP), on-premises, or hybrid environments, preventing lock-in and allowing consistent deployment across environments​

[devtron.ai](https://devtron.ai/blog/why-use-kubernetes-for-container-orchestration/#:~:text=,community%20support%2C%20enhancing%20its%20capabilities)

. It optimizes infrastructure costs through bin-packing, achieving high **resource efficiency** by tightly scheduling containers on nodes​

[devtron.ai](https://devtron.ai/blog/why-use-kubernetes-for-container-orchestration/#:~:text=AWS%2C%20Microsoft%20Azure%2C%20Google%20GCP,to%20cost%20savings%20on%20infrastructure)

. Moreover, Kubernetes boasts a huge **ecosystem and community support**, with many open-source tools and extensions (service meshes, operators, CI/CD integrations) available​

[devtron.ai](https://devtron.ai/blog/why-use-kubernetes-for-container-orchestration/#:~:text=,community%20support%2C%20enhancing%20its%20capabilities)

. All these benefits make it easier to deploy and manage complex, distributed applications in production.

### Success stories of Kubernetes adoption

Many organizations have successfully adopted Kubernetes to achieve faster development and deployment cycles. For example, **Spotify** migrated from their homegrown container platform to Kubernetes, and found that teams spent _less time on manual capacity provisioning and more time building features_. One of Spotify’s services handles ~10 million requests per second and benefits greatly from Kubernetes’ autoscaling​

[kubernetes.io](https://kubernetes.io/case-studies/spotify/#:~:text=percentage%20of%20our%20fleet%20has,tenancy%20capabilities%2C%20CPU%20utilization)

. They also reduced service deployment time from hours to seconds, and improved CPU utilization 2–3x through Kubernetes’ efficient scheduling​

[kubernetes.io](https://kubernetes.io/case-studies/spotify/#:~:text=features%20for%20Spotify%2C,tenancy%20capabilities%2C%20CPU%20utilization)

. Another success story is **Chick-fil-A** (a major restaurant chain) using Kubernetes at the edge in each restaurant – this enabled rapid iteration and reliable operations even outside traditional data centers​

[appvia.io](https://www.appvia.io/blog/chick-fil-a-kubernetes-success-story#:~:text=How%20Chick,food%20giant)

. The **Babylon Health** case study highlights Kubernetes as a great platform for machine learning workloads due to its built-in scheduling and scalability​

[kubernetes.io](https://kubernetes.io/case-studies/#:~:text=Image%3A%20Babylon)

. These real-world cases demonstrate how Kubernetes can increase developer velocity, reduce infrastructure costs, and handle massive scale. Companies often note that Kubernetes’ **strong open-source community and standard APIs** let them innovate faster and adopt best practices used industry-wide​

[kubernetes.io](https://kubernetes.io/case-studies/spotify/#:~:text=has%20improved%20on%20average%20two,to%20threefold)

​

[kubernetes.io](https://kubernetes.io/case-studies/spotify/#:~:text=But%20by%20late%202017%2C%20it,in%20the%20flourishing%20Kubernetes%20community)

.

### Kubernetes architecture: clusters, nodes, and components

![https://www.simform.com/blog/kubernetes-architecture/](blob:https://chatgpt.com/25e6cf8e-0f4a-4125-a7f5-7ab73c0b28a9)

 _Kubernetes architecture consists of a **control plane** (master node components) and **worker nodes** (where containers run). This diagram shows a high-level view: the control plane components (API server, scheduler, controller manager, etcd) manage the cluster, while each worker node runs a kubelet agent, kube-proxy, and container runtime to host Pods._

A **cluster** is the basic execution environment for Kubernetes – it’s a set of machines (virtual or physical) that work together to run your containerized applications. A cluster has two types of nodes:

- **Control Plane node(s)** (sometimes called master node(s)): These run the core Kubernetes control plane components that manage the overall cluster state and orchestrate the workload. Key components include:
    - **API Server** – the front-end that exposes the Kubernetes API (receives `kubectl` commands and cluster interactions).
    - **Controller Manager** – runs controllers that enforce the desired state (e.g. ensuring the correct number of pod replicas).
    - **Scheduler** – schedules pods to run on specific nodes based on resource availability and other constraints.
    - **etcd** – a distributed key-value store that holds the cluster state and configuration.
- **Worker Nodes**: These nodes actually run the application **Pods**. Each worker node has:
    - a **kubelet** – the node agent that communicates with the control plane and manages pods on that node.
    - a **container runtime** – such as Docker or containerd, to run the containers.
    - a **kube-proxy** – handles networking, routing traffic to the correct pod instances across the cluster.

Every cluster requires at least one worker node to run pods​

[kubernetes.io](https://kubernetes.io/docs/concepts/architecture/#:~:text=A%20Kubernetes%20cluster%20consists%20of,in%20order%20to%20run%20Pods)

. The control plane can be single or multiple nodes for redundancy; in production it is usually running on multiple nodes for high availability​

[kubernetes.io](https://kubernetes.io/docs/concepts/architecture/#:~:text=The%20worker%20node,tolerance%20and%20high%20availability)

. The control plane and worker nodes together form the full cluster. The control plane makes decisions about scheduling and scaling, while worker nodes execute the decisions (running or stopping containers). This separation is often referred to as the **control plane vs. data plane** distinction: the control plane (brain of the cluster) manages the data plane (the workhorses that run app data and workloads).

In a **managed Kubernetes service** (like GKE, EKS, AKS), the cloud provider runs the control plane components for you (abstracting away master node management), whereas in a **self-hosted cluster** (e.g., using kubeadm or kops on your own servers) you are responsible for setting up and maintaining both control plane and worker nodes. The architecture is conceptually the same, but **managed services** offload operational burden (upgrades, HA, backups of etcd) at the cost of some flexibility. **Self-hosting** gives full control and customization (you can access all components), but requires more expertise to manage and can be more error-prone if not maintained properly​

[gcore.com](https://gcore.com/blog/managed-vs-self-managed-k8s/#:~:text=Pros)

​

[gcore.com](https://gcore.com/blog/managed-vs-self-managed-k8s/#:~:text=,Potentially%20slow%20setup%20process)

. In summary, a managed Kubernetes cluster simplifies deployment and reduces ops overhead (the provider handles the masters and often provides SLA-backed uptime)​

[gcore.com](https://gcore.com/blog/managed-vs-self-managed-k8s/#:~:text=,grade%20clusters)

, whereas a self-managed cluster gives you freedom to tailor every component but incurs higher operational complexity​

[gcore.com](https://gcore.com/blog/managed-vs-self-managed-k8s/#:~:text=,customized%20as%20needed%2C%20offering%20flexibility)

​

[gcore.com](https://gcore.com/blog/managed-vs-self-managed-k8s/#:~:text=,Potentially%20slow%20setup%20process)

. Many teams choose managed services for production to leverage cloud provider reliability and focus on their apps, unless they have specific needs that require self-management.

#### Kubernetes objects: Pods, ReplicaSets, Deployments (and why Pods are ephemeral)

In Kubernetes, the fundamental unit of deployment is the **Pod**. A Pod represents one or more tightly-coupled containers (such as an app container and a sidecar) that share the same network IP and storage volumes. In practice, most Pods contain a single main container (e.g., your application container). **Pods are intended to be ephemeral** – they can be created and destroyed frequently by the system​

[kubernetes.io](https://kubernetes.io/docs/concepts/services-networking/service/#:~:text=If%20you%20use%20a%20Deployment,Pod%20is%20reliable%20and%20durable)

​

[kubernetes.io](https://kubernetes.io/docs/concepts/services-networking/service/#:~:text=of%20those%20Pods%20are%20working,Pod%20is%20reliable%20and%20durable)

. You should not treat any individual Pod as a long-lived, pet-like server. If a Pod dies (due to node failure or other issue), Kubernetes will create a new one to replace it if managed by a higher-level controller. This ephemeral nature is by design: it enables **self-healing and auto-scaling**. However, it also means that any data stored _inside_ a Pod’s container filesystem will be lost when the Pod is deleted or crashes. You mitigate this by using external storage (persistent volumes) and by using controllers to automatically recreate pods.

**ReplicaSet** and **Deployment** are Kubernetes objects that manage Pods and provide resilience:

- A **ReplicaSet** ensures a specified number of Pod replicas are running at any given time. If a Pod fails or is deleted, the ReplicaSet controller will launch a new Pod to meet the replica count. ReplicaSets monitor the cluster state and **replace pods that crash or are terminated**, which ensures high availability​
    
    [sematext.com](https://sematext.com/glossary/kubernetes-pod/#:~:text=For%20instance%2C%20when%20a%20pod,continuous%20running%20of%20the%20application)
    
    ​
    
    [sematext.com](https://sematext.com/glossary/kubernetes-pod/#:~:text=Kubernetes%20has%20in,These%20include)
    
    .
- A **Deployment** is an even higher-level object that manages ReplicaSets (and thus Pods). Deployments provide declarative updates to Pods and ReplicaSets – for example, you can update the Pod template (e.g., to a new container image version) and the Deployment will roll out the change gradually (rolling update) while maintaining the desired number of Pods. Deployments make it easier to perform versioned upgrades, rollbacks, and scaling. When you create a Deployment, it automatically creates a ReplicaSet which in turn creates the Pods. You almost always use Deployments (rather than directly managing ReplicaSets) for stateless applications.

**Why are Pods ephemeral?** Kubernetes is built with the paradigm that individual pods come and go, and the system (via controllers) will continuously drive toward the desired state. Pods are not durable because treating them as replaceable units enables powerful orchestration capabilities like rescheduling on different nodes, auto-recovery, and scaling. The trade-off is you should design your app to not rely on any given Pod’s local state. Instead, externalize state (e.g., databases or persistent volumes) and rely on stable network endpoints (Services) rather than Pod IPs. To handle pod ephemerality:

- Use a **Deployment** or other controller so that if a Pod dies, a new one is created automatically. For example, if you manually delete a Pod that was created by a Deployment, the Deployment’s ReplicaSet will notice the pod count dropped and will spawn a replacement within seconds.
- Use **PersistentVolumes (PV)** for data that needs to persist across Pod restarts (we’ll cover PV/PVC in Day 2). A Pod can be attached to a persistent volume, so even if the Pod is destroyed, the data remains and can be reattached to a new Pod.
- Use a **Service** to abstract Pod endpoints. Since pods get recreated (with new IPs), clients shouldn’t talk directly to a Pod’s IP. Instead, they talk to a Service (with a stable IP or DNS name), which routes to whatever Pods are currently backing that service.

In short, **pods are ephemeral** and not meant to be individually managed or relied upon for long durations​

[kubernetes.io](https://kubernetes.io/docs/concepts/services-networking/service/#:~:text=of%20those%20Pods%20are%20working,Pod%20is%20reliable%20and%20durable)

​

[kubernetes.io](https://kubernetes.io/docs/concepts/services-networking/service/#:~:text=the%20desired%20state%20of%20your,Pod%20is%20reliable%20and%20durable)

. Higher-level controllers (Deployments, StatefulSets, etc.) and Kubernetes mechanisms ensure that the _collective service_ provided by pods is persistent even if individual pod instances are not.

#### Security considerations for Kubernetes

Containerized applications bring security benefits (isolated environments, immutability) but also new challenges. When deploying on Kubernetes, you must consider security at multiple layers: the container image, the cluster configuration, network policies, and runtime. Here are some **container and Kubernetes security best practices**:

- **Use trusted, up-to-date images:** Ensure your container images are from a trusted source or registry, and are regularly updated to include the latest security patches. “Well-maintained images” (e.g., official images or those maintained by reputable vendors) are preferred because they are kept at consistent patch levels, reducing known vulnerabilities​
    
    [enterprisersproject.com](https://enterprisersproject.com/article/2018/2/container-security-fundamentals-5-things-know#:~:text=Since%20containers%20are%20deployed%20from,maintained%20images)
    
    . Avoid running images with known CVEs or pulling from unknown sources. Always scan images for vulnerabilities and rebuild them when base images have updates.
- **Least privilege:** Follow the principle of least privilege both for containers and for Kubernetes API access. For containers, this means avoid running as root user inside the container if not necessary, and restrict capabilities (using Pod Security Context and SecurityContext settings). For the cluster, use Kubernetes RBAC to grant minimal permissions to users, service accounts, and CI/CD systems. Define Roles and ClusterRoles with only the needed access and bind them appropriately​
    
    [accuknox.com](https://www.accuknox.com/blog/kubernetes-security-best-practices#:~:text=Source%3A%20Redhat%202022%20K8s%20Survey)
    
    . This prevents an exploit in one component from easily compromising the whole cluster.
- **Network policies:** Use Kubernetes NetworkPolicy to limit pod-to-pod communication where appropriate (for example, your frontend pods might only be allowed to talk to backend API pods and not to the database directly). This can contain the blast radius if one pod is compromised. By default, Kubernetes allows all cross-pod traffic; applying NetworkPolicies lets you whitelist expected traffic.
- **Protect the control plane:** If you manage your own Kubernetes masters, ensure the API server is secure (use authentication and authorization, enable audit logging, etc.). For any cluster, **secure etcd** (encrypt secrets at rest, restrict access) since etcd holds all cluster state (including Secrets).
- **Regular updates:** Keep your Kubernetes version and dependencies up to date. Kubernetes frequently releases patches for security issues. Similarly, keep the node OS and container runtime updated. Apply security fixes regularly to avoid known exploits.
- **Runtime security monitoring:** Employ tools that can monitor running containers for suspicious behavior (e.g., Falco or other intrusion detection). Enable audit logs in Kubernetes to track changes to resources​
    
    [accuknox.com](https://www.accuknox.com/blog/kubernetes-security-best-practices#:~:text=,or%20you%20can%20utilize%20open)
    
    .
- **Pod security context & policies:** Define pod security contexts to drop unneeded Linux capabilities, make file systems read-only where possible, and use seccomp/AppArmor profiles. Kubernetes is moving toward Pod Security Standards – you can enforce policies (baseline/restricted) to disallow privileged containers or dangerous host mounts cluster-wide.
- **Use Namespaces for multitenancy:** Namespaces provide a scope for names and can help separate teams or environments. They can also be coupled with RBAC to ensure one team’s application cannot access another’s resources​
    
    [accuknox.com](https://www.accuknox.com/blog/kubernetes-security-best-practices#:~:text=4,Use%20livenessProbe%20and%20readinessProbe)
    
    .
- **Enable logging and audit:** Ensure that you capture logs from your applications and cluster. Kubernetes doesn’t automatically centralize application logs, so use a logging agent (EFK stack or cloud log service). Also use `kubectl logs` and events to troubleshoot issues. Kubernetes audit logging, when enabled, can record every call made to the API – useful for security forensics.

A key thing to remember is that container security extends to the **supply chain** as well. It’s not only about the cluster – you should also secure your CI/CD pipeline (to prevent image tampering) and use tools to sign and verify images (so that only trusted images run). By incorporating security checks early (DevSecOps approach), you can catch misconfigurations or vulnerabilities before deployment.

#### Maintained images: what are they and their pros/cons?

“Maintained images” refer to container images that are regularly updated and curated, typically by a vendor, open-source community, or your internal team. Examples include official images on Docker Hub (like `nginx:latest` or `node:lts`) or images your organization builds with a formal patching process. Using maintained base images is a best practice for security and stability.

**Pros:** A well-maintained image is kept up-to-date with security patches and bug fixes. As one expert noted, _“The best images are well-maintained and fairly immutable… layers are kept at consistent patch levels to protect against known vulnerabilities”_​

[enterprisersproject.com](https://enterprisersproject.com/article/2018/2/container-security-fundamentals-5-things-know#:~:text=Since%20containers%20are%20deployed%20from,maintained%20images)

. This means if a critical CVE in a library is announced, the maintainers will release a new image version addressing it, and you can update your deployments. Maintained images also often have a smaller attack surface (unneeded packages removed) and are tested by a broader community. For example, using the official Node.js or Python images ensures you get the latest minor updates and a base that the community trusts and monitors.

**Cons:** On the flip side, relying on external maintained images means you need to track their updates and test your application with new versions. An update to a base image could potentially introduce changes that affect your app. There’s also a slight risk that an image could be deprecated or the maintainer could make breaking changes (for instance, switching the base OS from Debian to Alpine). Another con is that maintained images often prioritize stability, so they might not include the absolute latest version of a software if it’s experimental – which could be a limitation if you need a cutting-edge feature. Lastly, using a third-party maintained image requires trust in the maintainer; you should verify the source and integrity (many official images are signed or come from Docker Official Images or Verified Publishers, which mitigates this).

In summary, **the pros of maintained images far outweigh the cons for most cases**. They give you a secure starting point and reduce the maintenance burden on your team. The best practice is to start with a minimal, well-maintained base image and only add what your app needs​

[accuknox.com](https://www.accuknox.com/blog/kubernetes-security-best-practices#:~:text=Build%20Small%20Container%20Images)

(smaller images are not only more secure but also faster to pull and deploy). If you do customize an image, your team becomes the “maintainer” for that image – then you must regularly rebuild it with patches (which is essentially what a maintained image would do for you). Many organizations use renovate bots or CI pipelines to automatically rebuild images when base image updates are available, ensuring their derived images remain maintained.

## 2. Get Kubernetes running using Docker Desktop

One of the simplest ways to set up a local single-node Kubernetes cluster is by using Docker Desktop. Docker Desktop includes an option to enable a Kubernetes cluster integrated with your Docker runtime. This is great for development and testing purposes.

**Steps to enable Kubernetes in Docker Desktop:**

1. **Install Docker Desktop** (if not already installed) for your OS. Ensure it’s updated to a recent version. Docker Desktop comes with Kubernetes support on Windows and Mac (and on Windows it uses WSL2 backend).
2. **Enable Kubernetes:** Open Docker Desktop’s settings/preferences. Navigate to the “Kubernetes” section and check the option “Enable Kubernetes”. Docker will start installing and configuring a single-node Kubernetes cluster internally.
    - On enabling, Docker might prompt to reset the Kubernetes cluster if it was enabled before. Accept and wait a few minutes.
3. **Configure kubectl:** Docker Desktop installs the `kubectl` command-line tool (or you can install it separately) and merges the Kubernetes context automatically. Ensure your kubeconfig context is set to Docker Desktop’s cluster. You can check by running:
    
    shell
    
    Copy
    
    `kubectl config get-contexts kubectl config use-context docker-desktop`
    
    The context name `docker-desktop` is typically configured for you when enabling Kubernetes in Docker Desktop.
4. **Verify the cluster is running:** Run a simple command like:
    
    shell
    
    Copy
    
    `kubectl get nodes`
    
    You should see one node (often named `docker-desktop`) in the Ready state. Also try:
    
    shell
    
    Copy
    
    `kubectl get services`
    
    By default, you’ll see the `kubernetes` Service in the default namespace (an internal cluster IP for the API server).

If everything is correct, you now have a functioning Kubernetes cluster. Docker Desktop’s Kubernetes is a single-node cluster, meaning the control plane and worker roles are all on the one Docker VM.

**Troubleshooting Kubernetes startup in Docker Desktop:**

- If Kubernetes does not start (e.g., it’s stuck in “starting” state for a long time), try restarting Docker Desktop. Sometimes resetting the Kubernetes cluster (via the Docker Desktop GUI -> Kubernetes -> "Reset cluster") can resolve issues if the state is corrupted.
- Ensure your Docker resources (CPU/memory) are sufficient. Docker Desktop settings allow you to allocate resources. Kubernetes in Docker needs at least ~2 CPUs and 2GB RAM to function smoothly​
    
    [minikube.sigs.k8s.io](https://minikube.sigs.k8s.io/docs/start/#:~:text=What%20you%E2%80%99ll%20need)
    
    . If it’s been given too little memory, it might not schedule the internal pods.
- On Windows, if using WSL2, make sure the Kubernetes context is pointing to the Docker Desktop’s Kubernetes and not trying to use some other context. Also, check that WSL2 has the needed updates (Docker’s documentation lists some specific Windows version requirements).
- If `kubectl` commands hang or refuse to connect, check that Docker Desktop’s Kubernetes is showing as running. It may help to run `docker info` and see if Kubernetes is enabled.
- Sometimes you might encounter image pull issues (e.g., the internal “pause” image can’t be fetched due to network). Ensure that Docker can pull images from the internet. If you are behind a proxy, configure Docker’s proxy settings so Kubernetes can pull required images.
- Firewall: On Windows, the Kubernetes cluster network might be blocked by local firewall. Typically, Docker handles this, but if you have third-party firewall software, ensure the Docker VM’s network connections are allowed.

**Using kubectl with Docker Desktop:** The `kubectl` CLI gets configured automatically by Docker Desktop. If you have a separate kubectl installed, ensure it’s the same version range as the Kubernetes server (Docker Desktop often uses a specific Kubernetes version). You can always check versions with `kubectl version --short`. In general, minor version skew of +1/-1 is supported by kubectl.

Once you have `kubectl get nodes` showing the node, you are ready to deploy applications on this local cluster.

## 3. Nginx Deployment with a NodePort Service

Let’s deploy a simple Nginx web server in our cluster and expose it to our host machine using a NodePort service. A NodePort service opens a specific port on the node (in this case, our Docker Desktop VM) to allow external access to the service.

We’ll create two Kubernetes YAML manifest files: one for the Deployment and one for the Service (or combine them in one file separated by `---`). Below are the manifests.

**Deployment YAML (nginx-deployment.yaml):**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3  # run 3 Nginx pods for high availability
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: daraymonsta/nginx-257:dreamteam
        ports:
        - containerPort: 80
```

Let’s break down this deployment:

- We set `replicas: 3` to run three copies of the Nginx pod. This ensures if one pod goes down, we still have others serving, and it demonstrates load-balancing.
- The `selector` and `template.metadata.labels` ensure the Deployment manages pods labeled `app: nginx`.
- The container uses the image `daraymonsta/nginx-257:dreamteam` (as specified in the task). This is presumably a custom image (perhaps a modified Nginx with specific content or configuration). If that image is not accessible or you prefer, you could use a standard `nginx:latest` image – but we’ll follow the given one.
- We expose container port 80 (the Nginx default HTTP port). This is the port Nginx listens on _inside_ the container.

Apply this Deployment with: `kubectl apply -f nginx-deployment.yaml`. Kubernetes will pull the image and create 3 pods. You can check the pods status with:

```arduino
kubectl get pods -l app=nginx
```

This uses a label selector to list only pods with `app=nginx`. You should see 3 pods, and after pulling the image, their status should be **Running**. If a pod crashes or image pull fails, describe the pod (`kubectl describe pod <pod-name>`) to see events. A common issue is image pull error (e.g., if the image name is wrong or you need Docker Hub credentials). For this custom image, ensure it’s publicly accessible or you have logged in (you can use `kubectl create secret docker-registry` if it needed credentials).

Now, to expose these Nginx pods externally, create a NodePort Service.

**Service YAML (nginx-service.yaml):**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - port: 80        # Service port (cluster internal)
      targetPort: 80  # Container port to route to
      nodePort: 30001 # NodePort on the node VM
```

Here, we define a Service named “nginx-service”. Key points:

- `spec.type: NodePort` means this service will allocate a port on the node (in the 30000-32767 range). We explicitly choose `30001` for clarity (the task suggests exposing on 30001). If we left it blank, Kubernetes would auto-assign a random port in that range.
- The `selector` matches the pods with label `app: nginx` (so it will route traffic to the 3 Nginx pods we deployed).
- Under `ports`, `port: 80` is the service’s cluster-internal port, and `targetPort: 80` is where the service forwards traffic on the pods (the containerPort we exposed). Often the service `port` and container `targetPort` are the same for simplicity, as we do here (both 80).
- `nodePort: 30001` opens port 30001 on the Docker Desktop VM. This means any traffic hitting port 30001 on **your host (Docker VM)** will be forwarded to the service, which in turn balances it to the Nginx pods.

Apply the service: `kubectl apply -f nginx-service.yaml`. Now
