resource "scaleway_ip" "k8s_master_ip" {
  count = 1
}

resource "scaleway_server" "k8s_master" {
  count          = 1
  name           = "${terraform.workspace}-master-${count.index + 1}"
  image          = "${data.scaleway_image.ubuntu.id}"
  type           = "${var.server_type}"
  public_ip      = "${element(scaleway_ip.k8s_master_ip.*.ip, count.index)}"
  security_group = "${scaleway_security_group.master_security_group.id}"
  boot_type      = "bootscript"
  bootscript     = "${data.scaleway_bootscript.architecture.id}"

  connection {
    type        = "ssh"
    user        = "root"
    private_key = "${file(var.private_key)}"
  }
  provisioner "file" {
    source      = "scripts/"
    destination = "/tmp"
  }
  provisioner "file" {
    source      = "addons/"
    destination = "/tmp"
  }
  provisioner "file" {
    source      = "kubeadm"
    destination = "/tmp/"
  }
  provisioner "remote-exec" {

    inline = [
      <<EOT
#!/bin/bash
set -e
chmod +x /tmp/docker-install.sh
chmod +x /tmp/kubeadm-install.sh
chmod g+w -R /tmp/kubeadm/

export ubuntu_version=$(echo -n ${var.ubuntu_version} | cut -d " " -f 2 | awk '{print tolower($0)}')

/tmp/docker-install.sh $${ubuntu_version} ${var.arch} ${var.docker_version} && \
/tmp/kubeadm-install.sh ${var.k8s_version} && \

export KUBEADM_VERSION=$(apt-cache madison kubeadm | grep $(echo ${var.k8s_version} | cut -c8-) | \
  head -1 | awk '{print $3}' | rev | cut -c4- | rev)
dpkg --compare-versions "$${KUBEADM_VERSION}" lt 1.13 && \
  export KUBEADM_CONFIG_FILE=/tmp/kubeadm/v1alpha3-config.yaml || \
  export KUBEADM_CONFIG_FILE=/tmp/kubeadm/v1beta1-config.yaml
dpkg --compare-versions "$${KUBEADM_VERSION}" lt 1.12 && \
  export KUBEADM_CONFIG_FILE=""
if [[ -z "$${KUBEADM_CONFIG_FILE}" ]]; then
  kubeadm init \
    --apiserver-advertise-address=${self.private_ip} \
    --apiserver-cert-extra-sans=${self.public_ip} \
    --kubernetes-version=${var.k8s_version} \
    --ignore-preflight-errors=KubeletVersion
else
  sed -i 's/CONFIG_CLUSTER_PUBLIC_IP/${self.public_ip}/g' $${KUBEADM_CONFIG_FILE} && \
  sed -i 's/CONFIG_CLUSTER_PRIVATE_IP/${self.private_ip}/g' $${KUBEADM_CONFIG_FILE} && \
  sed -i "s/CONFIG_KUBERNETES_VERSION/v$${KUBEADM_VERSION}/g" $${KUBEADM_CONFIG_FILE} && \
  sed -i "s/CONTAINER_LOG_MAX_SIZE/${var.container_log_max_size}/" $${KUBEADM_CONFIG_FILE}

  # ref https://github.com/kubernetes/kubeadm/issues/413
  # kube-apiserver.yaml initialDelaySeconds is too eager
  if [[ ${var.arch} == "arm" ]]; then
    kubeadm init phase control-plane apiserver --config=$${KUBEADM_CONFIG_FILE} --v 4
    sleep 2s && \
    cat /etc/kubernetes/manifests/kube-apiserver.yaml && \
    sed -i 's/failureThreshold: 8/failureThreshold: 15/g' /etc/kubernetes/manifests/kube-apiserver.yaml && \
    sed -i 's/initialDelaySeconds: [0-9][0-9]/initialDelaySeconds: 240/g' /etc/kubernetes/manifests/kube-apiserver.yaml && \
    cat /etc/kubernetes/manifests/kube-apiserver.yaml && \
    kubeadm init \
      --skip-phases=control-plane \
      --ignore-preflight-errors=all \
      --config=$${KUBEADM_CONFIG_FILE} \
      --v ${var.kubeadm_verbosity}
  else
    kubeadm init \
      --ignore-preflight-errors=KubeletVersion \
      --config=$${KUBEADM_CONFIG_FILE} \
      --v ${var.kubeadm_verbosity}
  fi
fi && \

mkdir -p $HOME/.kube && cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && \
kubectl create secret -n kube-system generic weave-passwd --from-literal=weave-passwd=${var.weave_passwd} && \
kubectl apply -f "https://cloud.weave.works/k8s/net?password-secret=weave-passwd&k8s-version=$(kubectl version | base64 | tr -d '\n')" && \
chmod +x /tmp/monitoring-install.sh && /tmp/monitoring-install.sh ${var.arch}
EOT
    ]
  }
  provisioner "local-exec" {
    command    = "./scripts/kubectl-conf.sh ${terraform.workspace} ${self.public_ip} ${self.private_ip} ${var.private_key}"
    on_failure = "continue"
  }
}

data "external" "kubeadm_join" {
  program = ["./scripts/kubeadm-token.sh"]

  query = {
    host = "${scaleway_ip.k8s_master_ip.0.ip}"
    key = "${var.private_key}"
  }

  depends_on = ["scaleway_server.k8s_master"]
}
