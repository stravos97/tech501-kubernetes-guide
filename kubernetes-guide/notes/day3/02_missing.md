**Networking in Minikube:** By default, Minikube on Docker driver will not have a LoadBalancer capability (as there’s no cloud). NodePort services will be accessible on the VM’s IP. For example, if we expose NodePort 30002, to reach it from outside, we use `http://<VM public IP>:30002`. Ensure your cloud’s security group or firewall allows that port if you go that route.

However, often it’s easier to use **Ingress** or a reverse proxy on port 80. We will use an Nginx reverse proxy on the host to forward traffic to our NodePort services, so that end-users can just hit port 80. This avoids opening many ports and is a simpler URL.

**Storage in Minikube:** Minikube usually comes with a default **StorageClass** that provisions hostPath volumes on the VM. We already made a PV manually, but we could also let Minikube dynamic provision a hostPath PV by creating a PVC with no specific PV (Minikube’s default StorageClass is “standard” which uses hostPath provisioner). In our case, we’ll stick to our static PV approach for the Mongo DB, or we could convert to using a PVC with storageClass. Either works. Just note, the path on this Ubuntu VM for hostPath might be different. Our manifest uses `/data/mongo`. We should make sure that path exists and is writable by the container. Minikube’s kubelet likely runs as root, so it can create it.

**Deploying our applications on Minikube:** We will now deploy the same Sparta app (Node.js + MongoDB) on this Minikube, as well as potentially two other dummy applications to practice multiple app deployment.

Let’s say we have three applications:

- The Sparta Node.js app (with Mongo) – we already have manifests for those.
- An additional Nginx (for variety).
- Perhaps a simple hello-world app (like Kubernetes’ example or another small web app).

We can reuse our YAML from earlier, with slight modifications if needed for environment differences:

- The PV hostPath path might be different if we want; but we can reuse `/data/mongo`.
- NodePort numbers: We used 30001 and 30002 before. We can reuse or pick new. We know we want one NodePort to test directly, one to test via LoadBalancer, etc.

#### Deploy multiple apps:

**App1: Sparta Node.js + MongoDB** – We’ll treat this as one “application” (two deployments, one service, plus PVC etc.). Expose via NodePort 30002 (like before). **App2: Nginx** – Could be the same Nginx we did, or maybe an Apache HTTPD for variety. Let’s stick to Nginx. 3 replicas, NodePort 30001. **App3: Another app via LoadBalancer** – since Minikube can’t truly provision a cloud LB, we will simulate by using `minikube tunnel` which creates a local LoadBalancer IP on the host. Alternatively, we use NodePort but run `minikube service <name>` to access it. To meet the task, let’s do a LoadBalancer service for perhaps a simple app like a guestbook frontend? But that’s complex. Instead, we can convert our Nginx service to LoadBalancer (but we already have NodePort example). Actually, the task said one NodePort, one LoadBalancer, and then use Nginx reverse proxy to route external traffic. Possibly:

- Expose Node app via NodePort (30002).
- Expose Nginx directly via LoadBalancer (so it would get an external IP through minikube tunnel).
- Then Nginx reverse proxy on host to route maybe based on hostname or path to those services.

However, having Nginx itself be both an app and also reverse proxy might confuse. Maybe better:

- “Application 1” – Node/Mongo (NodePort).
- “Application 2” – say an Echo server or another service (we can use a publicly available simple API, or even reuse Nginx as an app).
- “Application 3” – something like Kubernetes Dashboard? But too heavy. Could deploy a dummy hello app (there’s a `k8s.gcr.io/echoserver` container which just echoes request data). Let’s use that for simplicity:
    - echoserver Deployment (1 replica, container `k8s.gcr.io/echoserver:1.4`, exposes port 8080).
    - Service type LoadBalancer for echoserver on port 8080.

Now we use **minikube tunnel**. Running `minikube tunnel` on the VM will require sudo (it creates network interfaces). It will output something like “Entering tunnel for LoadBalancer service...”. When we create a LoadBalancer service, Minikube will allocate an IP (usually from a local range, e.g., 10.96.x.x cluster IP range or sometimes it uses the cluster IP as external IP). The tunnel essentially listens on that IP and forwards to the service.

However, since we plan to set up an Nginx reverse proxy, we might not actually need to rely on the LB IP from outside. But we can test it.

Let’s do this step by step on the VM:

- Deploy Nginx (Deployment + NodePort Service 30001).
- Deploy echoserver (Deployment + LoadBalancer Service).
- Deploy Node/Mongo (Deployment + PVC/PV + Service NodePort 30002, etc.).

We must ensure ports 30001 and 30002 are open if we want to test NodePort directly. If we plan to only expose via Nginx on 80, we might not open them to public. But for completeness, maybe open them temporarily for testing.

**Applying YAMLs in Minikube:** Use `kubectl apply -f` for all manifests. They should all come up (check pods). For LoadBalancer service, do `minikube tunnel` in a separate SSH session (so it keeps running). When the echoserver service is created, `kubectl get svc echo-service` (for example) will initially show `<pending>` in EXTERNAL-IP column. After starting `minikube tunnel`, it should update to some IP (like 10.0.2.15 or something). That IP is actually on the VM itself. You can curl that IP:port from the VM to see if it responds.

Minikube tunnel also often requires root to bind to those IPs, so keep it running with sudo.

Now, **configure Nginx reverse proxy on the VM** to route external traffic: We have two apps to expose: for example,

- Node app on NodePort 30002
- Echo app on LoadBalancer IP (though we could also access it via NodePort if we gave it one, but we gave LB type).

We will configure Nginx (on the host VM, not the one in cluster) to listen on port 80 and proxy based on URL:

- `http://<VM IP>/node/*` -> forwards to `localhost:30002` (the NodePort of Node app).
- `http://<VM IP>/echo/*` -> forwards to the echo service.

However, the echo service is on a cluster IP or LB IP which might not be directly reachable externally unless we use the tunnel’s IP. Since we have NodePort to everything as an alternative, maybe simpler: For echo app, instead of LB, we could also create a NodePort to target it (just to use Nginx proxy easily). But since we set up LB to practice, we can still connect to it via tunnel IP from the host. Actually, after running minikube tunnel, the LB IP (let’s call it 10.96.0.200) is accessible on the host. So Nginx on host can proxy to 10.96.0.200:8080 (for echo service).

Alternatively, we could skip LB and just use NodePort for echo too, and demonstrate `minikube tunnel` separately as a concept. The task explicitly said one via LoadBalancer (with tunnel). So we did that for echo. We’ll still route via Nginx by pointing to that LB IP.

**Install Nginx on Ubuntu VM:**

```
sudo apt-get install -y nginx

```

Nginx will likely start automatically listening on port 80. We will customize its config. Edit `/etc/nginx/sites-available/default` (or create new site): For example:

```bash
server {
    listen 80;
    server_name _;

    location /node/ {
        proxy_pass http://127.0.0.1:30002/;
        # adjust if the Node app expects no /node prefix:
        rewrite ^/node/(.*)$ /$1 break;
    }

    location /echo/ {
        proxy_pass http://10.96.0.200:8080/;
        rewrite ^/echo/(.*)$ /$1 break;
    }
}

```

This assumes:

- Node app is fine with or without the `/node` prefix (we strip it when proxying).
- The echo server likely just returns what you send. It doesn’t care about path.

After editing, test Nginx config `sudo nginx -t`. Then `sudo systemctl restart nginx`.

Now, from your local machine, you can hit the cloud VM’s public IP:

- `http://<VM_PUBLIC_IP>/node/` -> should reach Node app. (If Node app has a web interface, you’ll see it; or maybe a JSON message).
- `http://<VM_PUBLIC_IP>/echo/` -> should hit the echo server and likely return some HTML with request details.

This setup is essentially acting like an **Ingress**: Nginx is forwarding to services. In production, you might actually run an Ingress Controller inside the cluster to do this, but here we manually did it on the host.

**Document Minikube networking:** Important points to note:

- With NodePort, the service is accessible via `NodeIP:NodePort`. Our VM had NodeIP = 192.168.49.2 (Minikube’s default VM IP) and we used localhost in Nginx because we’re on the same host. From outside, you either open the NodePort or use a proxy.
- With LoadBalancer service and `minikube tunnel`, Minikube allocated a pseudo external IP and routed traffic from host to service. This is a way to simulate cloud LoadBalancers. The tunnel has to run constantly for the IP to work.
- We chose to not directly expose these to the internet but instead funnel through Nginx on port 80, which is often open. This is a common pattern: you might have an Nginx or HAProxy as a gateway.
- Clean up: if you stop `minikube tunnel`, the LB IP stops working. If you shut down the VM or Minikube, all pods go down (unless you set minikube to start on boot, which we’ll address).

**Cleanup and management:** When done, you can stop the cluster with `minikube stop` (though we might want it to auto-start on boot). You might also want to configure Minikube to start on boot: One way is to create a systemd service that runs `minikube start` at boot as root. Alternatively, since it’s one node, maybe just restart manually via ssh if needed. But the task says "Ensuring `minikube start` happens automatically on instance restart".

To do this: Create a systemd unit file `/etc/systemd/system/minikube.service`:

```
[Unit]
Description=Minikube
After=docker.service
Requires=docker.service

[Service]
User=root
ExecStart=/usr/local/bin/minikube start --driver=docker
ExecStop=/usr/local/bin/minikube stop
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target

```

Then `sudo systemctl enable minikube.service`. This will try to start it on boot. Make sure Docker is up before it runs (we did After= and Requires= docker.service).

There’s a nuance: minikube start might hang if run at boot without a tty, etc. It’s not heavily tested for headless autostart. Another approach: use cron with @reboot to run `minikube start`. But systemd is cleaner if it works.

Be mindful that if minikube requires `sudo`, running as root in the service covers that.

Test by rebooting the VM and seeing if `kubectl get nodes` works after.

Now, with everything running, we do the **final deployment of the Sparta app in the cloud**:

- That essentially is what we did: Node.js + Mongo with PV (100MB as specified) and HPA, and exposure via Nginx on port 80.
- Verify that HPA on the cloud VM cluster works as well (you might need to enable metrics-server on minikube too: `minikube addons enable metrics-server`).
- The Nginx reverse proxy is exposing it on port 80 so users can access without specifying a port.

At this point, our GitHub repository should have all manifests in a structured way (maybe in directories for each day or by component). The README should detail each step, including any issues (for example, maybe mention that on Minikube, the custom image `daraymonsta/nginx-257:dreamteam` needed to be pulled via `docker pull` because it’s on Docker Hub, or we needed to use `minikube image load` if it was a local image).

We should also include **diagrams** illustrating:

- Kubernetes cluster architecture (we did for Day 1).
- PV/PVC architecture (Day 2).
- Day 3 networking: maybe a diagram showing how external request goes to Nginx (host) -> NodePort -> app pod, etc., to clarify the flow.

Finally, ensure all **logs and troubleshooting notes** are included, as well as links to relevant official docs: We have cited many official docs above (Kubernetes.io, etc.) to reinforce best practices and definitions. In a real README, one would hyperlink to those docs or include references as footnotes.

To conclude, check everything in the cloud environment:

- Access the Node app URL (via Nginx) – ensure it talks to the database (maybe add a new item via the app if it’s that kind of test, and see it persists).
- Possibly simulate a bit of load from an external source to watch HPA in effect on the VM (though limited resources might not scale much).
- Ensure if the VM reboots, `minikube start` works (maybe test once, or mention that it needs configuration if not fully tested).
- Provide instructions on how to shut down or clean up (like disabling minikube service, deleting resources if needed). 