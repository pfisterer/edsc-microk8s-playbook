# Ansible Playbook to Create VMs in OpenStack with MicroK8S

Creates a number of virtual machines in OpenStack with [MicroK8S](https://microk8s.io/) pre-installed.

The motivation for creating this project was that in some OpenStack installations, no recent version of LBaaS v2 is available. This limits the use of Kubernetes Services of type `LoadBalancer`. Hence, this project uses [MetalLB](https://metallb.universe.tf/) to realize load balancing.

However, as OpenStack only allows [a single floating IP to be assigned to an instance](https://ask.openstack.org/en/question/11901/how-to-configure-multiple-floating-ip-for-one-instance/), this project re-uses the hosts IP. 

## Usage (local installation of Ansible)

1. Set the required environment variables (see table below) and run `ansible-playbook`
   - Set environent variables (e.g., using multiple `export NAME="VALUE"` statements on Linux)
1. Run `ansible-playbook deploy.yaml`
1. Open `generated-server-list.txt` for the IP adresses of the created machines
1. Set `KUBECONFIG` to `$PWD/generated-kube.conf` and verify that `kubectl get nodes -o wide` works.

Example

```bash 
export OS_USERNAME="my-openstack-user-name"
export OS_PASSWORD="my-openstack-secret-pw"
export OS_DOMAIN_NAME="default"
export OS_AUTH_URL="http://openstack-controller-hostname:5000/v3"
export OS_PROJECT_NAME="my-project"

export ANSIBLE_HOST_KEY_CHECKING=False 

export NODE_COUNT=1
export NODE_PASSWORD="bla"
export IMAGE="Ubuntu Server 20.04 64bit"
export NODE_FLAVOR="m1.medium"
export NODE_SEC_GROUP="default"
export KEY="my-laptop-ssh-key"
export EXT_NET="ext-network"
export FLOATING_IP_POOL="ext-network"

ansible-playbook deploy.yaml
```

## Usage (Docker, image [farberg/edsc-openstack-studentnodes](https://hub.docker.com/repository/docker/farberg/edsc-microk8s-playbook))

1. Directory where to store the file with IP adresses of the created machines
  - Create directory on your local machine
  - Mount this diretory using `-v /your/absolute/path/to/some/dir:/data`
1. Set the required environment variables (see table below)
   - Requires multiple `--env "NAME=VALUE"` parameters
   - Make sure to set `GENERATED_SERVER_LIST` to a file in `/data/` (e.g., `GENERATED_SERVER_LIST=/data/generated-server-list.txt`)
1. Make your ssh keys available
   - Requires mounting them as `/root/.ssh/` using `-v /your/absolute/path/to/.ssh/:/root/.ssh/`
1. Create a single command from the values above
1. See `/your/absolute/path/to/some/dir/generated-server-list.txt` for the IP adresses of the created machines
2. Set `KUBECONFIG` to `$PWD/generated-kube.conf` and verify that `kubectl get nodes -o wide` works.

Example

```bash
docker run --rm -ti \
  -v "/your/absolute/path/to/some/dir:/data" \
  -v "/your/absolute/path/to/.ssh/:/root/.ssh/" \
  --env "NAME=VALUE" \
  --env "GENERATED_SERVER_LIST=/data/generated-server-list.txt" \
  farberg/edsc-microk8s-playbook
```

## Environment Variables

Specific to this project:

| Name                  | Required | Description                                       | Example                                    |
| --------------------- | -------- | ------------------------------------------------- | ------------------------------------------ |
| NODE_COUNT            |          | Number of nodes to creates                        | `1`                                        |
| NODE_PASSWORD         | x        | Password to set for user `ubuntu`                 | `blablubb`                                 |
| NODE_NAME             |          | Prefix for hostnames                              | `demo-lecture`                             |
| IMAGE                 | x        | Name of the OS image to use                       | `"Ubuntu Server 18.04 64bit (29.05.2018)"` |
| NODE_FLAVOR           | x        | Name of the machine flavor to use                 | `m1.medium`                                |
| NODE_SEC_GROUP        | x        | Security group to use                             | `default`                                  |
| KEY                   | x        | Name of the SSH key to use                        | `my-laptop-ssh-key`                        |
| EXT_NET               | x        | Name of the external network                      | `ext-network`                              |
| FLOATING_IP_POOL      | x        | Name of the floating IP pool                      | `ext-network`                              |
| DNS_SERVER_1          |          | DNS server #1 (defaults to 8.8.8.8)               | `8.8.8.8`                                  |
| DNS_SERVER_1          |          | DNS server #2 (defaults to 8.8.8.8)               | `8.8.8.8`                                  |
| GENERATED_SERVER_LIST |          | Path of the file to store the list of machine IPs | `/data/generated-server-list.txt`          |
| MICROK8S_VERSION      |          | Version of microk8s                               | `1.18/stable`                              |

For default values, see [group_vars/all.yaml](group_vars/all.yaml)

Required by Openstack:

| Name            | Required | Description | Example                                        |
| --------------- | -------- | ----------- | ---------------------------------------------- |
| OS_AUTH_URL     | x        |             | `http://openstack-controller-hostname:5000/v3` |
| OS_USERNAME     | x        |             | `my-openstack-user-name`                       |
| OS_PASSWORD     | x        |             | `my-openstack-secret-pw`                       |
| OS_PROJECT_NAME | x        |             | `my-project`                                   |
| OS_DOMAIN_NAME  | x        |             | `default`                                      |


# Build Docker image

Build the image
- `docker build -t farberg/edsc-microk8s-playbook .`

Run a container
- `docker run --rm -ti farberg/edsc-microk8s-playbook` 

## Notes

Run just microk8s installation on existing hosts:

```bash
ansible-playbook -i generated-server-list.txt --tags microk8s deploy.yaml
```

Add a UDP/TCP service using the NGINX ingress controller (cf. [Ingress nginx for TCP and UDP services](https://minikube.sigs.k8s.io/docs/tutorials/nginx_tcp_udp_ingress/))

```yaml
spec:
  template:
    spec:
      containers:
      - name: ingress-nginx-controller
        ports:
         - containerPort: 52
           hostPort: 52
```

Run 
```bash
kubectl patch configmap nginx-udp-configmap -n kube-system --patch '{"data":{"52":"default/my-service:52"}}'

kubectl patch deployment ingress-nginx-controller --patch "$(cat ingress-nginx-controller-patch.yaml)" -n kube-system
```