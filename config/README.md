## OKD
### Initial setup
#### Install OKD 
See [README.md in the root of this repository](../README.md) for instructions on how to install OKD.
#### Login to OKD

Now that we have a running OKD cluster, we can login to it.
> If you have a problem in the cluster, check the debug section in the [README.md in the root of this repository](../README.md) for instructions on how to debug the cluster.

If you are on the proxy machine, you'll use the user ```system:admin``` to login to OKD.
> The system:admin user is automatically created when OKD is installed. It has cluster-admin privileges, and we can do that by using the kubeconfig file that was created during the installation process located in the file ```~/okd-install/auth/kubeconfig```.

If you are not on the proxy machine, you can login to OKD using the user ```kube:admin```, which is also created during the installation process.
> The kube:admin user is automatically created when OKD is installed. It has cluster-admin privileges, and we can do that by using the kubeadmin password that was created during the installation process located in the file ```~/okd-install/auth/kubeadmin-password``` on the proxy machine (or the machine where you created the ignition files, which in our case is the proxy machine).

To login to OKD, run the following command:
```bash
oc login -u kubeadmin -p <kubeadmin password> https://api.<cluster name>.<base domain>:6443 --insecure-skip-tls-verify=true
```
In our case, the command would be:
```bash
oc login -u kubeadmin -p <kubeadmin password> https://api.okd.osupytheas.fr:6443 --insecure-skip-tls-verify=true
```
### Add the ssl certificates to the cluster

Every application that will be deployed and exposed to the outside world will need to have a valid ssl certificate.

So we'll create a namespace that will contain the ssl certificates, and restrict the access to it, so that only the cluster-admin can create, update and delete the certificates in that namespace (the cluster-admin will be the only one that will have access to the ssl certificates, while the other users will not be able to access them, nor create, update or delete them, nor even see the namespace that contains them).

To do that, we'll create a namespace, a service account, a role and a role binding

```yaml
# This is the namespace that will contain the ssl certificates
apiVersion: v1
kind: Namespace 
metadata:
  name: cert-manager
  annotations:
    openshift.io/description: "This namespace contains the ssl certificates"
    openshift.io/display-name: "Cert Manager"
```
> The namespace ```cert-manager``` will contain the ssl certificates

Now we can create the namespace using the following command:
```bash
oc create -f namespace.yaml
```
    
We restrict access to the namespace ```cert-manager``` so that only the cluster-admin can access it.

To do that, we'll create a ClusterRole and a ClusterRoleBinding that will give the group ```system:cluster-admins``` the permission to create, update and delete the secrets in the namespace ```cert-manager```

```yaml
# This ClusterRole grants the create, update and delete secrets permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cert-manager
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["create", "update", "delete"]
```

> The ClusterRole ```cert-manager``` grants the create, update and delete secrets permissions

Now we can create the ClusterRole using the following command:
```bash
oc create -f cluster-role.yaml
```

```yaml
# This ClusterRoleBinding grants the group "system:cluster-admins" the permissions to create, update and delete secrets in the namespace "cert-manager"
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cert-manager
roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: cert-manager
subjects:
- kind: Group
  name: system:cluster-admins
  apiGroup: rbac.authorization.k8s.io
```

> The ClusterRoleBinding ```cert-manager``` grants the group ```system:cluster-admins``` the permissions to create, update and delete secrets in the namespace ```cert-manager```

Now we can create the ClusterRoleBinding using the following command:
```bash
oc create -f cluster-role-binding.yaml
```

### Deploying the ssl certificates

Now we can deploy the ssl certificates.

Have a folder (in our case on the proxy machine) that contains the ssl certificates, and create a secret for each certificate.

To create a secret, we'll use the following command:
```bash
oc create secret tls <secret name> --cert=<path to the certificate> --key=<path to the key> -n cert-manager
```

> Example:
> ```bash
> oc create secret tls osupytheas.fr --cert=/etc/ssl/private/osupytheas_fr.pem --key=/etc/ssl/private/osupytheas_fr.key -n cert-manager
> ```

Do that for each certificate.


### Deploying Applications
To deploy some applications, which needs some specific permissions, we'll have to configure the cluster in a way that permits us to do that for each type of application.
#### Wordpress
To deploy Wordpress, which its container image will be running in root user, we'll need to create a project, that permits us to do that. (the following steps are valid for any application that needs to run in root user)

For that we'll use a template that will create a project, a service account, a role and a role binding ([See templates folder in the wordpress repository](https://gitlab.osupytheas.fr/yelarjouni/deployer-wordpress-okd)).

But by default, the template can't create a project, because when we try to use it, we'll get the following error:
```
unable to create /v1, Resource=namespaces, Name=test: namespaces is forbidden: User "system:serviceaccount:openshift-infra:template-instance-controller" cannot create resource "namespaces" in API group "" at the cluster scope
```


Now we'll have to give the service account ```template-instance-controller``` the permission to create a project.

To do that, we'll create a ClusterRole and a ClusterRoleBinding that will give the service account ```template-instance-controller``` the permission to create, update and delete a project.

```yaml
# This ClusterRole grants the create, update and delete namespaces permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: namespace-creator-updater-deleter
rules:
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["create", "update", "delete"]
```
> The ClusterRole ```namespace-creator-updater-deleter``` will give the service account ```template-instance-controller``` the permission to create, update and delete a project.

Now we can create the ClusterRole using the following command:
```bash
oc create -f cluster-role.yaml
```

```yaml
# This ClusterRoleBinding grants the "template-instance-controller" service account the permissions necessary to create, update, and delete namespaces.
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: template-instance-controller-namespace-creator-updater-deleter
roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: namespace-creator-updater-deleter
subjects:
- kind: ServiceAccount
  name: template-instance-controller
  namespace: openshift-infra
```
> The ClusterRoleBinding ```template-instance-controller-namespace-creator-updater-deleter``` will give the service account ```template-instance-controller``` the permission to create, update and delete a project.

Now we can create the ClusterRoleBinding using the following command:
```bash
oc create -f cluster-role-binding.yaml
```

Now we have to give the service account ```template-instance-controller``` the permission to use SCC (Security Context Constraints) that allows containers to run in root user.

To do that, we'll create a ClusterRole and a ClusterRoleBinding that will give the service account ```template-instance-controller``` the permission to use the SCCs.

```yaml
# This ClusterRole grants the use of the SCCs
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: anyuid-scc-user
rules:
- apiGroups: ["security.openshift.io"]
  resources: ["securitycontextconstraints"]
  verbs: ["use"]
```

> The ClusterRole ```anyuid-scc-user``` will give the service account ```template-instance-controller``` the permission to use the SCCs

Now we can create the ClusterRole using the following command:
```bash
oc create -f cluster-role.yaml
```

```yaml
# This ClusterRoleBinding grants the "template-instance-controller" service account the permissions necessary to use the SCCs.
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: template-instance-controller-anyuid-scc-user
roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: anyuid-scc-user
subjects:
- kind: ServiceAccount
  name: template-instance-controller
  namespace: openshift-infra
```

> The ClusterRoleBinding ```template-instance-controller-anyuid-scc-user``` will give the service account ```template-instance-controller``` the permission to use the SCCs

Now we can create the ClusterRoleBinding using the following command:
```bash
oc create -f cluster-role-binding.yaml
```

We'll need nfs volumes to store the data of the wordpress application, so we'll have to give the scc used in the wordpress deployment (anyuid) the permission to use nfs volumes.

To do that, we'll modify the anyuid SCC using the following command:
```bash
oc edit scc anyuid
```

And we'll add the following line in the volumes section:
```yaml
volumes:
# Other types of volumes
- nfs
```

exit the editor and save the changes.

Now we should be able to mount nfs volumes in the containers.

Refer to the [README.md in the wordpress repository](https://gitlab.osupytheas.fr/yelarjouni/deployer-wordpress-okd) for instructions on how to deploy Wordpress.