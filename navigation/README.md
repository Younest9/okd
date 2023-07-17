# Documentation on Essential Commands for Openshift (OKD) Cluster

This document provides a list of essential commands for using and navigating an OKD cluster via the command line interface. The commands listed below are commonly used for managing applications, projects, and resources in an OKD cluster.

## Prerequisites
- Make sure you have installed the OpenShift command-line client (oc) on your local machine.

## Cluster Login
```bash
oc login <CLUSTER_URL> --token=<ACCESS_TOKEN>
```

This command will log you into the cluster using the cluster URL and access token. The access token can be obtained from the Openshift web console.

```bash
oc login <CLUSTER_URL> --username=<USERNAME> --password=<PASSWORD> --insecure-skip-tls-verify=true
```

This command will log you into the cluster using the cluster URL, username, and password. The username and password can be obtained from the Openshift web console.

## Verify Connection
```bash
oc whoami
```

This command will display the username of the currently logged in user.

```bash
oc whoami --show-server
```

This command will display the URL of the currently logged in cluster.

## Cluster Navigation

```bash
oc project <PROJECT_NAME>
```

This command allows you to switch to a specific project within the cluster.

```bash
oc get projects
```

This command will display a list of all projects within the cluster.

```bash
oc get pods
```

This command will display a list of all pods within the current project.

```bash
oc get pods -n <PROJECT_NAME>
```

This command will display a list of all pods within a specific project.

```bash
oc get pods --all-namespaces
```

This command will display a list of all pods within all projects.

```bash
oc get pods -o wide
```

This command will display a list of all pods within the current project along with additional information such as node name and IP address.

```bash
oc get pods -o wide -n <PROJECT_NAME>
```

This command will display a list of all pods within a specific project along with additional information such as node name and IP address.

```bash
oc get pods -o wide --all-namespaces
```

This command will display a list of all pods within all projects along with additional information such as node name and IP address.

```bash
oc get services
```

This command will display a list of all services within the current project.

```bash
oc get services -n <PROJECT_NAME>
```

This command will display a list of all services within a specific project.

```bash
oc get services --all-namespaces
```

This command will display a list of all services within all projects.

```bash
oc get routes
```

This command lists all the exposed routes in the current project.

```bash
oc get routes -n <PROJECT_NAME>
```

This command will display a list of all routes within a specific project.

```bash
oc get routes --all-namespaces
```

This command will display a list of all routes within all projects.

```bash
oc get deployments
```

This command will display a list of all deployments within the current project.

```bash
oc get deployments -n <PROJECT_NAME>
```

This command will display a list of all deployments within a specific project.

```bash
oc get deployments --all-namespaces
```

This command will display a list of all deployments within all projects.

```bash
oc get pv
```

This command will display a list of all persistent volumes within the current project.

```bash
oc get pvc
```

This command will display a list of all persistent volume claims within the current project.

```bash
oc get pvc -n <PROJECT_NAME>
```

This command will display a list of all persistent volume claims within a specific project.

```bash
oc get pvc --all-namespaces
```

This command will display a list of all persistent volume claims within all projects.

## Resource Management

```bash
oc create -f <FILE_NAME>
```

This command will create a resource from a file.

```bash
oc create -f <FILE_NAME> -n <PROJECT_NAME>
```

This command will create a resource from a file in a specific project.

```bash
oc apply -f <FILE_NAME>
```

This command will create or update a resource from a file.

```bash
oc apply -f <FILE_NAME> -n <PROJECT_NAME>
```

This command will create or update a resource from a file in a specific project.

```bash
oc delete -f <FILE_NAME>
```

This command will delete a resource from a file.

```bash
oc delete -f <FILE_NAME> -n <PROJECT_NAME>
```

This command will delete a resource from a file in a specific project.

```bash
oc delete <RESOURCE_TYPE> <RESOURCE_NAME>
```

This command will delete a resource by name.

```bash
oc delete <RESOURCE_TYPE> <RESOURCE_NAME> -n <PROJECT_NAME>
```

This command will delete a resource by name in a specific project.

```bash
oc describe <RESOURCE_TYPE> <RESOURCE_NAME>
```

This command will display detailed information about a resource by name.

```bash
oc describe <RESOURCE_TYPE> <RESOURCE_NAME> -n <PROJECT_NAME>
```

This command will display detailed information about a resource by name in a specific project.

```bash
oc edit <RESOURCE_TYPE> <RESOURCE_NAME>
```

This command will edit a resource by name.

```bash
oc edit <RESOURCE_TYPE> <RESOURCE_NAME> -n <PROJECT_NAME>
```

This command will edit a resource by name in a specific project.

## Application Deployment

```bash
oc new-app <SOURCE_CODE_URL>
```

This command will create a new application from source code.

```bash
oc new-app <SOURCE_CODE_URL> -n <PROJECT_NAME>
```

This command will create a new application from source code in a specific project.

```bash
oc expose service <SERVICE_NAME>
```

This command will expose a service as a route.

```bash
oc scale --replicas=<REPLICA_COUNT> <RESOURCE_TYPE> <RESOURCE_NAME>
```

This command will scale a resource by name.

This document has provided a list of essential commands for using and navigating an OKD cluster via the command line interface. Use these commands as a reference for managing your applications, projects, and resources in your OKD cluster. Feel free to consult the OKD official documentation for more information on each command and its options.

## References

- [OKD CLI Reference](https://docs.okd.io/latest/cli_reference/openshift_cli/getting-started-cli.html)
- [OKD CLI Cheat Sheet](https://www.openshift.com/blog/openshift-cli-commands-for-beginners)
- [OpenShift command cheat sheet](https://github.com/nekop/openshift-sandbox/blob/master/docs/command-cheatsheet.md)
- [OpenShift cheat sheet](./openshift_cheat_sheet_r5v1.pdf)
- [OpenShift CLI (oc) developer commands](https://docs.okd.io/latest/cli_reference/openshift_cli/developer-cli-commands.html)
- [OpenShift CLI (oc) administrator commands](https://docs.okd.io/latest/cli_reference/openshift_cli/administrator-cli-commands.html)

