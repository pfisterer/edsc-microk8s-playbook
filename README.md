# Ansible Playbook (+ Terraform) to Create a VM in OpenStack with MicroK8S

Creates a virtual machine in OpenStack with [MicroK8S](https://microk8s.io/) pre-installed. It uses [MetalLB](https://metallb.universe.tf/) to provide load balancing.

However, as OpenStack only allows [a single floating IP to be assigned to an instance](https://ask.openstack.org/en/question/11901/how-to-configure-multiple-floating-ip-for-one-instance/), this project re-uses the hosts IP (which limits the ports available to Kubernetes).

A Docker image is available at <https://hub.docker.com/r/farberg/edsc-microk8s-playbook>. 

## Usage (local installation of Ansible)

1. Set the required environment variables (see table below) and run `ansible-playbook`
   - Set environent variables (e.g., using multiple `export NAME="VALUE"` statements on Linux)
1. Run `ansible-playbook deploy.yaml`
1. Open `generated-{{ name }}-server-list.txt` for the IP adresses of the created machines
1. Set `KUBECONFIG` to `$PWD/generated-kube.conf` and verify that `kubectl get nodes -o wide` works.

Example

```bash 
export OS_USERNAME="my-openstack-user-name"
export OS_PASSWORD="my-openstack-secret-pw"
export OS_DOMAIN_NAME="default"
export OS_AUTH_URL="http://openstack-controller-hostname:5000/v3"
export OS_PROJECT_NAME="my-project"

ansible-playbook deploy.yaml
```

## Usage (Docker, image [farberg/edsc-openstack-studentnodes](https://hub.docker.com/r/farberg/edsc-microk8s-playbook))

1. Directory where to store the file with IP adresses of the created machines
  - Create directory on your local machine
  - Mount this diretory using `-v /your/absolute/path/to/some/dir:/data`
1. Set the required environment variables (see table below)
   - Requires multiple `--env "NAME=VALUE"` parameters
   - Make sure to set `GENERATED_SERVER_LIST` to a file in `/data/` (e.g., `GENERATED_SERVER_LIST=/data/generated-server-list.txt`)
1. Make your ssh keys available
   - Requires mounting them as `/root/.ssh/` using `-v /your/absolute/path/to/.ssh/:/root/.ssh/:ro`
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

## Environment variables (only Openstack):

| Name            | Required | Description | Example                                        |
| --------------- | -------- | ----------- | ---------------------------------------------- |
| OS_AUTH_URL     | x        |             | `http://openstack-controller-hostname:5000/v3` |
| OS_USERNAME     | x        |             | `my-openstack-user-name`                       |
| OS_PASSWORD     | x        |             | `my-openstack-secret-pw`                       |
| OS_PROJECT_NAME | x        |             | `my-project`                                   |
| OS_DOMAIN_NAME  | x        |             | `default`                                      |


# Building the Docker Image

```bash
# Build the image
docker build -t farberg/edsc-microk8s-playbook .

# Push the image (maintainers only)
docker push farberg/edsc-microk8s-playbook

# Run a container
docker run --rm -ti farberg/edsc-microk8s-playbook
```

## Notes

Run microk8s installation on existing hosts:

```bash
ansible-playbook -i generated-server-list.txt --tags microk8s deploy.yaml
```
