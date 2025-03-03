# Observing Kubernetes Behaviors

## Table of Contents
- [Observing Kubernetes Behaviors](#observing-kubernetes-behaviors)
  - [Table of Contents](#table-of-contents)
  - [Pod Self-Healing](#pod-self-healing)
  - [Scaling Replicas Dynamically (Zero Downtime)](#scaling-replicas-dynamically-zero-downtime)
    - [Method 1: kubectl scale Command](#method-1-kubectl-scale-command)
    - [Method 2: Editing the Deployment Imperatively](#method-2-editing-the-deployment-imperatively)
    - [Method 3: Applying a Modified YAML (Declarative)](#method-3-applying-a-modified-yaml-declarative)
  - [Zero Downtime Deployment Updates](#zero-downtime-deployment-updates)
  - [Cleaning Up Resources](#cleaning-up-resources)
  - [Troubleshooting Scaling](#troubleshooting-scaling)
  - [References](#references)

## Pod Self-Healing

Now that we have a running deployment, let's explore some dynamic behaviors of Kubernetes. One of the key features is pod self-healing: if a pod in a Deployment is deleted or crashes, Kubernetes will create a new one automatically.

You can observe this by listing pods and deleting one:

```bash
kubectl get pods -l app=nginx
kubectl delete pod <one_of_pod_names>
```

After deletion, run `kubectl get pods -l app=nginx` again. Initially, you'll see one less pod, but within seconds a new pod with a new name should appear, bringing the count back to 3. The ReplicaSet controller noticed the pod went away and launched a replacement [1].

This demonstrates Kubernetes' self-healing capability. In production, if a node went down or a pod process died, users would still hit the service and be routed to remaining pods, while Kubernetes works to recover the lost pods on a healthy node.

## Scaling Replicas Dynamically (Zero Downtime)

Suppose our Nginx deployment needs to handle more load. We can scale out the number of pod replicas on the fly. There are multiple ways to scale:

### Method 1: kubectl scale Command

This is a direct way to scale a deployment or replicaset:

```bash
kubectl scale deployment nginx-deployment --replicas=5
```

This tells Kubernetes to increase the nginx-deployment to 5 replicas. The Deployment controller will create 2 new pods (since we had 3, it adds up to 5). You can watch the pods being created with:

```bash
kubectl get pods -l app=nginx -w  # watch mode
```

The new pods will be added to the service endpoints automatically. If you refresh your browser or use a load-testing tool, you can see traffic being spread to more pods. This scaling does not cause downtime – existing pods continue serving while new ones come up.

Similarly, you could scale down with the same command (e.g., to 2 replicas); Kubernetes will terminate excess pods.

### Method 2: Editing the Deployment Imperatively

You can run:

```bash
kubectl edit deploy nginx-deployment
```

This opens the deployment YAML in your default editor. Changing the `replicas: 5` in the spec and saving will update the deployment. This is essentially doing the same as the scale command, but via editing the live object.

### Method 3: Applying a Modified YAML (Declarative)

You could also edit your nginx-deployment.yaml file to have `replicas: 5` and then run:

```bash
kubectl apply -f nginx-deployment.yaml
```

Kubernetes will see the deployment spec changed and perform a rolling update to match it. In the case of just replica count change, it's a quick scale operation.

All these methods achieve a graceful scaling. Kubernetes ensures that at any point, at most one pod might be terminating during a downscale (default maxUnavailable = 1 for Deployments), and new pods are ready before old pods are removed during upscale/downscale events to avoid dropping below the desired count. In our Nginx example, adding pods doesn't disrupt existing ones at all.

## Zero Downtime Deployment Updates

Although not explicitly in the tasks, it's worth noting that if you update the container image of a Deployment, Kubernetes will do a rolling upgrade: incrementally launch new pods with the new image and terminate old ones, ensuring some overlap to avoid downtime.

This can be configured (e.g., rolling update strategy). By default, it'll spawn one new pod, then kill one old pod, etc., as configured by `maxSurge` and `maxUnavailable`.

## Cleaning Up Resources

It's important to delete Kubernetes resources when they're no longer needed, especially in a dev environment, to avoid consuming cluster resources. To delete our Nginx setup, you can run:

```bash
kubectl delete -f nginx-deployment.yaml
kubectl delete -f nginx-service.yaml
```

This will remove the Deployment (and thus its ReplicaSet and pods) and the Service.

Alternatively, since we labeled everything with `app=nginx`, you could do:

```bash
kubectl delete deploy,svc -l app=nginx
```

This deletes all deployments and services with that label. Always ensure you specify the object kind (deployment, service, etc.) when deleting by label to avoid accidentally deleting other things that might share a label.

## Troubleshooting Scaling

Scaling is usually straightforward. If you encounter issues:

- If `kubectl scale` doesn't seem to do anything, check if the Deployment has any conditions preventing scaling (rare). Also ensure you are targeting the correct resource name/namespace.

- If new pods are created but stuck in Pending state, that could mean insufficient cluster resources (not an issue in Docker Desktop usually, but in small Minikube clusters it can be). If a pod is Pending, describe it to see if it's waiting for a volume or node port conflict or some other reason.

- In our case, node ports are specified; if you tried to scale another deployment with the same node port, it would conflict (Kubernetes would refuse to schedule the service). But scaling pods under one service doesn't create new node ports; they all share the same service node port.

After exploring, you can scale back to 3 or down to 0. In fact, scaling to 0 is a way to temporarily pause a deployment (zero replicas means no pods). The service will have no endpoints, so traffic to it will fail, but the Deployment object still exists and can be scaled up later. This is a quick way to stop an app without deleting the deployment definition.

## References

[1] Sematext.com. "Kubernetes ReplicaSet: A Practical Guide." [https://sematext.com/blog/kubernetes-replicaset/](https://sematext.com/blog/kubernetes-replicaset/)
