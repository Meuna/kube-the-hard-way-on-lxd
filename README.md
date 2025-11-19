# kube-the-hard-way-on-lxd

This repository is fully inspired from Kelsey Hightower's tutorial:
[kubernetes-the-hard-way](https://github.com/kelseyhightower/kubernetes-the-hard-way).

It provisions 4 VM on LXD using OpenTofu and deploys the following stack with Ansible:
 - a simple pki
 - a 3 node etcd cluster
 - a single node kube-apiserver
 - a 3 node kube manager plane (controller and scheduler)
 - 3 worker nodes

A jumphost VM host the PKI and is configured with kubectl and etcdctl, with
credentials for the root user.

The 3 other VM host everything, with the exception of the kube-apiserver, only
hosted on node-0.

## Deployment

Provision the LXD VM:

```console
$ cd tofu
$ tofu init
$ tofu apply
```

Resolve the `kthw.local` domain with the LXD DNS server

```console
$ cd ..
$ sudo ./dns.sh
```

Deploy the stack:


```console
$ cd ansible
$ ansible-playbook playbooks/all.yaml
```

## Smoke tests

Log in as root on the jump host (the root user has a readily configured kubeconfig)

```console
$ ssh ansible@jh.kthw.local
$ sudo -i
```

### Data Encryption

Create a generic secret:

```console
$ kubectl create secret generic kthw --from-literal="mykey=mydata"
```

Print a hexdump of the `kthw` secret stored in etcd:

```console
$ etcdctl-default get /registry/secrets/default/kthw | hexdump -C
```

### Deployments

Create a deployment for the [nginx](https://nginx.org/en/) web server:

```console
$ kubectl create deployment nginx --image=nginx:latest
```

List the pod created by the `nginx` deployment:

```console
$ kubectl get pods -l app=nginx
```

### Port Forwarding

Retrieve the full name of the `nginx` pod:

```console
$ POD_NAME=$(kubectl get pods -l app=nginx  -o jsonpath="{.items[0].metadata.name}")
```

Forward port `8080` on your local machine to port `80` of the `nginx` pod:

```console
$ kubectl port-forward $POD_NAME 8080:80
```

In a new terminal make an HTTP request using the forwarding address:

```console
$ curl --head http://127.0.0.1:8080
```

### Services

Expose the `nginx` deployment using a [NodePort](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport) service:

```console
$ kubectl expose deployment nginx --port 80 --type NodePort
```

Retrieve the node port assigned to the `nginx` service:

```console
$ NODE_PORT=$(kubectl get svc nginx --output=jsonpath='{range .spec.ports[0]}{.nodePort}')
```

Make an HTTP request using the IP address and the `nginx` node port:

```console
$ curl -I http://node-0:${NODE_PORT}
$ curl -I http://node-1:${NODE_PORT}
$ curl -I http://node-2:${NODE_PORT}
```
