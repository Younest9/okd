# OKD
## Overview 

- OKD is a distribution of Kubernetes optimized for continuous application development and multi-tenant deployment

- OKD embeds Kubernetes and extends it with security and other integrated concepts

- OKD adds developer and operations-centric tools on top of Kubernetes to enable rapid application development, easy deployment and scaling, and long-term lifecycle maintenance for small and large teams

- OKD is also referred to as Origin in GitHub and in the documentation

- OKD is a sibling Kubernetes distribution to Red Hat OpenShift

## Difference between OKD and OCP (Openshift Container Platform)
 The difference between OKD et OCP (Openshift Container Platform) is that OKD is a community supported and totally free to use and modify version of Kubernetes (somewhat similar to Fedora compared to RHEL in terms of being upstream of the commercial product) and it uses Fedora CoreOS as the base OS for the cluster, on the other hand, OCP (Openshift Container Platform) is a subscription-based hybrid cloud enterprise Kubernetes platform that is supported by Red Hat, and it uses Redhat CoreOS.

## OKD Bare Metal Install - User Provisioned Infrastructure (UPI)

- [OKD Bare Metal Install - User Provisioned Infrastructure (UPI)](#OKD-4-bare-metal-install---user-provisioned-infrastructure-upi)
  - [Architecture Diagram](#architecture-diagram)
  - [Download Software](#download-software)
  - [Prepare the 'Bare Metal' environment](#prepare-the-bare-metal-environment)
  - [Configure Environmental Services](#configure-environmental-services)
  - [Generate and host install files](#generate-and-host-install-files)
  - [Deploy OKD](#deploy-OKD)
  - [Monitor the Bootstrap Process](#monitor-the-bootstrap-process)
  - [Remove the Bootstrap Node](#remove-the-bootstrap-node)
  - [Wait for installation to complete](#wait-for-installation-to-complete)
  - [Join Worker Nodes](#join-worker-nodes)
  - [Access the OpenShift Console](#access-the-openshift-console)
  
  
### Architecture Diagram

It's the same architecture as the OpenShift Container Platform, but without the RedHat subscription and without the RedHat CoreOS.

![Architecture Diagram](./diagram/Architecture.png)

### Download Software

1. Download any Linux based OS you want, this will server as the api, ingress and load balancer endpoints:

   -  In this example, we'll go with Debian 12 iso.
   -  You can download it via the official website: https://www.debian.org/distrib/netinst
   -  For quick download, you can [click here to download debian 12.0.0-amd64-netinst](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.0.0-amd64-netinst.iso), because that's what we'll be working with.

2. Download the pull secret from the [RedHat OpenShift Cluster Manager](https://cloud.redhat.com/openshift)

   -  Select 'Create Cluster' from the 'Clusters' navigation menu
   -  Select 'RedHat OpenShift Container Platform'
   -  Select 'Run on Bare Metal'
   -  Download Pull secret
   
      >Using a pull secret from the Red Hat OpenShift Cluster Manager is not required. You can use a pull secret for another private registry. Or, if you do not need the cluster to pull images from a private registry, you can use ```{"auths":{"fake":{"auth":"aWQ6cGFzcwo="}}}``` as the pull secret when prompted during the installation.
      >
      >If you do not use the pull secret from the Red Hat OpenShift Cluster Manager:
         > - Red Hat Operators are not available.
         > - The Telemetry and Insights operators do not send data to Red Hat.
         > - Content from the Red Hat Ecosystem Catalog Container images registry, such as image streams and Operators, are not available.



3. When you install an OKD cluster, you download the installation program ([the openshift-install tar.gz file](https://github.com/okd-project/okd/releases/download/4.13.0-0.okd-2023-06-24-145750/openshift-install-linux-4.13.0-0.okd-2023-06-24-145750.tar.gz)) from [the OKD Github Repository](https://github.com/okd-project/okd/releases)

4. Download the Fedora CoreOS image (.iso et .raw.xz) from [the Fedora CoreOS Official Website](https://getfedora.org/en/coreos/download)

### Prepare the 'Bare Metal' environment

1. Prepare 3 Control Plane physical or virtual machines with minimum settings:

   - 4 CPU
   - 16 GB RAM
   - 100 GB Storage
   - NIC connected to the internet, and on the same network as all other machines
   
2. Prepare a Bootstrap physical or virtual machine (it will be deleted once installation completes) with minimum settings:

   - 4 CPU
   - 16 GB RAM
   - 100 GB Storage
   - NIC connected to the internet, and on the same network as all other machines

3. Prepare some Worker physical or virtual machines with minimum settings (recommended to have at least 2, but you can have as many as you want, even 0):

   - 4 CPU
   - 16 GB RAM
   - 100 GB Storage
   - NIC connected to the internet, and on the same network as all other machines

3. Prepare a Services physical or virtual machine with minimum settings:
   
   - Name : svc
   - 4 CPU
   - 4GB RAM
   - NIC connected to the internet, and on the same network as all other machines
   
4. Write down all MAC addresses of all machines.

### Configure Environmental Services

1. Install the OS that you chose on the services machine, in our case it will be debian 11.

2. Boot the machine

3. Move the openshift-install tar.gz file to it, in addition of the pull secret that you downloaded it from the RedHat Cluster Manager using this command:

   ```bash
   scp ~/Downloads/<openshift-install_tar.gz_file_name> ~/Downloads/<pull_secret>  root@<IP_ADDRESS>:/root/
   ```
4. SSH to the machine

   ```bash
   ssh root@<IP_ADDRESS>
   ```
5. Navigate to https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/ and choose the folder for your operating system and architecture, and download oc.tar.gz.

   Unpack the archive:
   
   ```bash
   tar xvf oc.tar.gz
   ```
   Place the oc binary in a directory that is on your PATH.
   
   ```bash
   echo $PATH
   mv oc kubectl /usr/local/bin
   ```
   
   Confirm Client Tools are working

   ```bash
   kubectl version
   oc version
   ```
   
6. Extract the OpenShift Installer

   ```bash
   tar xvf <openshift-install_tar.gz_file_name>.tar.gz
   ```

7. Update the OS so we get the latest packages for each of the services we are about to install

   ```bash
   apt-get update && apt-get upgrade -y
   ```
   
8. Install Git
   
   
   ```bash
   apt-get install git -y
   ```
   
9. Download [config files](https://github.com/Younest9/okd) for each of the services

   ```bash
   git clone https://github.com/Younest9/okd
   ```
   Update the preferred editor

      ```bash
      export OC_EDITOR="nano"
      export KUBE_EDITOR="nano"
      ```

10. Set a Static IP for the network interface :
   The /etc/network/interfaces 
   file contains network interface configuration information for Debian Linux. Hence, edit the file:
   
    ```bash
    sudo nano /etc/network/interfaces
    ```
   
   Look for the primary network interface in the file:
   
   - Example: enp0s5
        
        ```bash
        allow-hotplug enp0s5
        iface enp0s5 inet dhcp
        ```
        Remove dhcp and allow-hotplug lines. Append the following configuration to set up/add new static IP on Debian Linux 10/11. Here is a sample config file:
   
        ```bash
        # The loopback network interface
        auto lo
        iface lo inet loopback

        # The primary network interface
        auto enp0s5
        iface enp0s5  inet static
            address 192.168.2.236
            netmask 255.255.255.0
            gateway 192.168.2.254
        ```
   
11. Setup DNS and reverse DNS records:

   - DNS Records:
   
      Replace in the following snippets the fields:
         
      - cluster_name
      - base_domain
      - ip_addresses
      
  
      ```
      ; Temp Bootstrap Node
      bootstrap.<cluster_name>.<base_domain>.        IN      A      <ip_address_reserved_for_bootstrap_node_in_dhcp> or <ip_address_we_will_setup_on_machines_on_boot>

      ; Control Plane Nodes
      cp-1.<cluster_name>.<base_domain>.         IN      A      <ip_address_reserved_for_master_node_1_in_dhcp> or <ip_address_we_will_setup_on_machines_on_boot>
      cp-2.<cluster_name>.<base_domain>.         IN      A      <ip_address_reserved_for_master_node_2_in_dhcp> or <ip_address_we_will_setup_on_machines_on_boot>
      cp-3.<cluster_name>.<base_domain>.         IN      A      <ip_address_reserved_for_master_node_3_in_dhcp> or <ip_address_we_will_setup_on_machines_on_boot>

      ; OKD Internal - Load balancer
      api.<cluster_name>.<base_domain>.        IN    A    <the_static_ip_address_we_setup>
      api-int.<cluster_name>.<base_domain>.    IN    A    <the_static_ip_address_we_setup>
      *.apps.<cluster_name>.<base_domain>.     IN    A    <the_static_ip_address_we_setup>

      ; ETCD Cluster
      etcd-0.<cluster_name>.<base_domain>.    IN    A     <ip_address_reserved_for_master_node_1_in_dhcp> or <ip_address_we_will_setup_on_machines_on_boot>
      etcd-1.<cluster_name>.<base_domain>.    IN    A     <ip_address_reserved_for_master_node_2_in_dhcp> or <ip_address_we_will_setup_on_machines_on_boot>
      etcd-2.<cluster_name>.<base_domain>.    IN    A     <ip_address_reserved_for_master_node_3_in_dhcp> or <ip_address_we_will_setup_on_machines_on_boot>

      ; OKD Internal SRV records
      _etcd-server-ssl._tcp.<cluster_name>.<base_domain>.    86400     IN    SRV     0    10    2380    etcd-0.okd
      _etcd-server-ssl._tcp.<cluster_name>.<base_domain>.    86400     IN    SRV     0    10    2380    etcd-1.okd
      _etcd-server-ssl._tcp.<cluster_name>.<base_domain>.    86400     IN    SRV     0    10    2380    etcd-2.okd

      oauth-openshift.apps.<cluster_name>.<base_domain>.     IN     A     <the_static_ip_address_we_setup>
      console-openshift-console.apps.<cluster_name>.<base_domain>.     IN     A     <the_static_ip_address_we_setup>
      ```
      
   - Reverse DNS Records
    
      ```
      <the_static_ip_address_we_setup_reversed>      IN    PTR    svc.<cluster_name>.<base_domain>. ;; Optional, if not specified, must set a static IP for the services machine.
      <the_static_ip_address_we_setup_reversed>      IN    PTR    api.<cluster_name>.<base_domain>.
      <the_static_ip_address_we_setup_reversed>      IN    PTR    api-int.<cluster_name>.<base_domain>.
      ;
      <ip_address_reserved_for_bootstrap_node_in_dhcp_reversed> or <ip_address_we_will_setup_on_machines_on_boot_reversed>    IN    PTR    bootstrap.<cluster_name>.<base_domain>.
      ;
      <ip_address_reserved_for_master_node_1_in_dhcp_reversed> or <ip_address_we_will_setup_on_machines_on_boot_reversed>    IN    PTR    cp-1.<cluster_name>.<base_domain>.
      <ip_address_reserved_for_master_node_2_in_dhcp_reversed> or <ip_address_we_will_setup_on_machines_on_boot_reversed>    IN    PTR    cp-2.<cluster_name>.<base_domain>.
      <ip_address_reserved_for_master_node_3_in_dhcp_reversed> or <ip_address_we_will_setup_on_machines_on_boot_reversed>    IN    PTR    cp-3.<cluster_name>.<base_domain>.
       ```
      
12. Configure DHCP

  - If you are using DHCP to provide the IP networking configuration to your cluster nodes, configure your DHCP service:

       - Add persistent IP addresses for the nodes to your DHCP server configuration. In your configuration, match the MAC address of the relevant network interface to the intended IP address for each node.

       - When you use DHCP to configure IP addressing for the cluster machines, the machines also obtain the DNS server information through DHCP. Define the persistent DNS server address that is used by the cluster nodes through your DHCP server configuration.
       
       - Define the hostnames of your cluster nodes in your DHCP server configuration. See the Setting the cluster node hostnames through DHCP section for details about hostname considerations.
       
   - If you are not using a DHCP service:
   
        - You must provide the IP networking configuration and the address of the DNS server to the nodes at FCOS install time. These can be passed as boot arguments if you are installing from an ISO image (--copy-network flag).
      > You can set a static ip address by editing the network configuartion while live booting the machine.
      > ```bash	
      > sudo nmtui-edit
      > ```

        
        - The cluster nodes obtain their hostname through a reverse DNS lookup.
13. Install & configure Apache Web Server (necessary to download the config files to passe in as arguments in the installation)
  
  - You can install apache on any Linux distro, in our case:
     ```
     apt install apache2 -y
     ```

14. Install & configure HAProxy

   - You can install HAProxy on any Linux distro, in our case:
   
        ```bash
      apt -y install haproxy 
        ```
      
   - Modify the config before starting haproxy
   
        - you can only modify the ip addresses to not break the config file.
   
   - Copy HAProxy config

      ```bash
     \cp ~/okd/haproxy.cfg /etc/haproxy/haproxy.cfg
      ```
   
   - Enable and start the service

       ```bash
      systemctl enable haproxy
      systemctl start haproxy
      systemctl status haproxy
       ```

### Generate and host install files

1. Generate an SSH key pair keeping all default options

   ```bash
   ssh-keygen
   ```

2. Create an install directory

   ```bash
   mkdir ~/okd-install
   ```

3. Copy the install-config.yaml included in the clone repository to the install directory

   ```bash
   cp ~/okd/install-config.yaml ~/okd-install
   ```
   
4. Update the install-config.yaml with your own pull-secret and ssh key.
   - Line 2 should contain your base domain
   - Line 10 should contain the number of control plane nodes you want (default is 3)
   - Line 12 should contain the cluster name
   - Line 17 should contain the network type (OpenShiftSDN (less features but more reliable) or OVNKubernetes( more features but less reliable))
   - Line 23 should contain the contents of your pull-secret.txt
   - Line 24 should contain the contents of your '~/.ssh/id_rsa.pub'

      ```bash
      nano ~/okd-install/install-config.yaml
      ```
5. Generate Kubernetes manifest files

   ```bash
   ~/openshift-install create manifests --dir ~/okd-install
   ```

   > A warning is shown about making the control plane nodes schedulable. It is up to you if you want to run workloads on the Control Plane nodes.
   >
   > If you dont want to, you can disable it with:
   > ```bash
   > sed -i 's/mastersSchedulable: true/mastersSchedulable: false/' ~/okd-install/manifests/cluster-scheduler-02-config.yml
   > ```
   > 
   > If you want to enable it, you can with:
   > ```bash
   > sed -i 's/mastersSchedulable: false/mastersSchedulable: true/' ~/okd-install/manifests/cluster-scheduler-02-config.yml
   > ```
   > Make any other custom changes you like to the core Kubernetes manifest files.
   > If you enable the masters, you can add them to the http and https ingress in the haproxy.cfg file by uncommenting the corresponding lines (lines 86, 87, 88 and 100, 101, 102) in the haproxy.cfg file.
   Generate the Ignition config and Kubernetes auth files

   ```bash
   ~/openshift-install create ignition-configs --dir ~/okd-install/
   ```
   
6. Create a hosting directory to serve the configuration files for the OKD booting process where the web server will be hosted

   ```bash
   mkdir /var/www/html/okd
   ```

7. Copy all generated install files and the raw.xz image to that directory

   ```bash
   cp  ~/okd-install/*  /var/www/html/okd/
   ```
8. Copy the raw.xz image to the web server directory (rename it to fcos to shorten the file name)

   ```bash
   cp  ~/okd/fedora-coreos-<whatever_version_you_downloaded>.raw.xz  /var/www/html/okd/fcos
   ```
   > Example: fedora-coreos-38.20230514.3.0-live.x86_64.raw.xz 
9. Change permissions of the web server directory

   ```bash
   chmod +r /var/www/html/okd/*
   ```
   
10. Confirm you can see all files added to the `/var/www/html/okd/` dir through Apache

   ```bash
   curl localhost/okd/
   ```
   > Note: If you are on the same machine as the haproxy server, you will need to change the port to 8080
### Deploy OKD

1. Power on the bootstrap host and cp-# hosts

    After booting up to the live ISO, use the following command then just reboot after it finishes and make sure you remove the attached .iso
    ```bash
    # Bootstrap Node - bootstrap
    sudo coreos-installer install /dev/sda -I http://<Host_apache_server>/okd/bootstrap.ign -u http://<Host_apache_server>/okd/fcos --insecure --insecure-ignition
    ```
    ```bash
    # Each of the Control Plane Nodes - cp-\#
    sudo coreos-installer install /dev/sda -I http://<Host_apache_server>/okd/master.ign -u http://<Host_apache_server>/okd/fcos --insecure --insecure-ignition
    ```
    > If you are using static ip addresses, you have to pass --copy-network to the coreos-installer command to copy the network configuration from the live environment to the installed system.
      > ```bash
      ># Bootstrap Node - bootstrap
      > sudo coreos-installer install /dev/sda -I http://<Host_apache_server>/okd/bootstrap.ign -u http://<Host_apache_server>/okd/fcos --insecure --insecure-ignition --copy-network
      > ```
      >```bash
      ># Each of the Control Plane Nodes - cp-\#
      >sudo coreos-installer install /dev/sda -I http://<Host_apache_server>/okd/master.ign -u http://><Host_apache_server>/okd/fcos --insecure --insecure-ignition --copy-network
      >```



### Monitor the Bootstrap Process

1. You can monitor the bootstrap process from the okd-svc host at different log levels (debug, error, info)

   ```bash
   ~/openshift-install --dir ~/okd-install wait-for bootstrap-complete --log-level=debug
   ```

2. Once bootstrapping is complete the bootstrap node [can be removed](#remove-the-bootstrap-node)

### Remove the Bootstrap Node

1. Remove all references to the `bootstrap` host from the `/etc/haproxy/haproxy.cfg` file

   ```bash
   # Two entries
   nano /etc/haproxy/haproxy.cfg
   # Restart HAProxy - If you are still watching HAProxy stats console you will see that the bootstrap host has been removed from the backends.
   systemctl reload haproxy
   ```

2. The bootstrap host can now be safely shutdown and deleted, the host is no longer required

### Wait for installation to complete

> **IMPORTANT:** if you set mastersSchedulable to false the [worker nodes will need to be joined to the cluster](#join-worker-nodes) to complete the installation. This is because the OKD Router will need to be scheduled on the worker nodes and it is a dependency for cluster operators such as ingress, console and authentication.

1. Collect the OpenShift Console address and kubeadmin credentials from the output of the install-complete event

   ```bash
   ~/openshift-install --dir ~/okd-install wait-for install-complete
   ```
1. Continue to [join the worker nodes to the cluster](#join-worker-nodes) in a new tab whilst waiting for the above command to complete

### Join Worker Nodes

1. Power on the worker hosts (if you have any)
   
    After booting up, use the following command then just reboot after it finishes and make sure you remove the attached .iso
    ```bash
    # Each of the Worker Nodes - worker-\#
    sudo coreos-installer install /dev/sda -I http://<Host_apache_server>/okd/worker.ign --insecure --insecure-ignition
   ```
   > If you are using static ip addresses, you have to pass --copy-network to the coreos-installer command to copy the network configuration from the live environment to the installed system.
   > ```bash
   > # Each of the Worker Nodes - worker-\#
   > sudo coreos-installer install /dev/sda -I http://<Host_apache_server>/okd/worker.ign --insecure --insecure-ignition --copy-network
   > ```

2. Setup 'oc' and 'kubectl' clients on the ocp-svc machine

   ```bash
   export KUBECONFIG=~/okd-install/auth/kubeconfig
   # Test auth by viewing cluster nodes
   oc get nodes
   ```

3. View and approve pending CSRs

   > **Note:** Once you approve the first set of CSRs additional 'kubelet-serving' CSRs will be created. These must be approved too.
   >
   > If you do not see pending requests wait until you do.

   ```bash
   # View CSRs
   oc get csr
   # Approve all pending CSRs
   oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve
   # Wait for kubelet-serving CSRs and approve them too with the same command
   oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve
   ```

4. Watch and wait for the Worker Nodes to join the cluster and enter a 'Ready' status

   > This can take 5-10 minutes

   ```bash
   watch -n5 oc get nodes
   ```

### Access the OpenShift Console

1. Wait for the 'Console' Cluster Operator to become available

   ```bash
   oc get co
   ```
   
2. Navigate to the OpenShift Console URL (``https://console-openshift-console.apps.<Cluster_name>.<Base_domain>``) and log in as the 'kubeadmin' user

   > You will get self signed certificate warnings that you can ignore
   >
   > If you need to login as kubeadmin and need to the password again you can retrieve it with: `cat ~/okd-install/auth/kubeadmin-password`

#### Sources

- [OKD 4.3 Architecture](https://docs.okd.io/latest/architecture/architecture.html)
- [OKD 4.3 Installation Guide](https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal.html)
- [OKD 4.3 Bare Metal UPI](https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal-network-customizations.html)
- [OKD 4.3 Bare Metal UPI - Advanced Networking](https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal-network-customizations.html#installation-user-infra-machines-static-network_installing-bare-metal-network-customizations)
- [OKD 4.3 Bare Metal UPI - Advanced Networking - Configuring DHCP](https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal-network-customizations.html#installation-user-infra-machines-static-network-dhcp_installing-bare-metal-network-customizations)
- [OKD 4.3 Bare Metal UPI - Advanced Networking - Configuring DNS](https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal-network-customizations.html#installation-user-infra-machines-static-network-dns_installing-bare-metal-network-customizations)
- [OKD 4.3 Bare Metal UPI - Advanced Networking - Configuring Load Balancing](https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal-network-customizations.html#installation-user-infra-machines-static-network-load-balancing_installing-bare-metal-network-customizations)
- [OKD 4.3 Bare Metal UPI - Advanced Networking - Configuring Static IP Addresses](https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal-network-customizations.html#installation-user-infra-machines-static-network-static_installing-bare-metal-network-customizations)
- [OKD 4.3 Bare Metal UPI - Advanced Networking - Configuring a Firewall](https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal-network-customizations.html#installation-user-infra-machines-static-network-firewall_installing-bare-metal-network-customizations)
- [GitHub repository - ryanhay/ocp4-metal-install](https://github.com/ryanhay/ocp4-metal-install)
- [OKD 4.3 Bare Metal UPI - Configuring SCC](https://docs.okd.io/latest/authentication/managing-security-context-constraints.html)
- [OKD 4.3 Bare Metal UPI - Security](https://docs.okd.io/latest/security/)
