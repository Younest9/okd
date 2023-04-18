#!/bin/bash

SUDO=''
if (( $EUID != 0 )); then
    SUDO='sudo'
fi
if ! command -v oc &> /dev/null; then
    $SUDO apt update
    $SUDO apt install wget curl -y
    $SUDO wget https://github.com/okd-project/okd/releases/download/4.12.0-0.okd-2023-03-18-084815/openshift-client-linux-4.12.0-0.okd-2023-03-18-084815.tar.gz
    $SUDO tar xzf openshift-client-linux-4.12.0-0.okd-2023-03-18-084815.tar.gz
    $SUDO mv kubectl oc /usr/local/bin/
    $SUDO rm openshift-client-linux-4.12.0-0.okd-2023-03-18-084815.tar.gz README.md
fi
if [[ $(oc projects 2> /dev/null) == *"You have access to the following projects and can switch between them with ' project <projectname>':"* ]]; then
    echo "User is already logged in"
else
    echo "Log In to the cluster..."
    echo ""
    while true; do
        echo "Please enter your username: "
        read username
        echo "Please enter your password: "
        read password
        echo ""
        echo "Connecting to the cluster using your credentials..."
        sleep 1
        echo "..."
        sleep 1
        echo "..."
        sleep 1
        echo ""
        oc login -u $username -p $password -s https://api.okd.osupytheas.fr:6443 --insecure-skip-tls-verify > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "Successfully logged in"
            break
        else
            echo "Failed to log in to the cluster"
            continue
        fi
    done
fi

echo "Available projects:"
oc projects
echo ""
echo "Do you want to create a new project ? (yes/no)"
read create
if [[ $create == "yes" ]]; then
    echo "Please enter the name of the project you want to create"
    read project
    echo "Please enter the display name of the project you want to create (optional)"
    read display
    echo "Please enter the description of the project you want to create (optional)"
    read description
    oc new-project $project --display-name="$display" --description="$description"
    oc project $project
else
    echo "Please enter the name of the project you want to connect to"
    read project
    oc project $project
fi


read -p "Git repository URL: " repo
read -p "Git repository username: " username
read -p "Git repository email: " email

oc create secret generic git-creds --from-literal=username=$username --from-literal=email=$email --namespace=$project
echo "Git credentials secret created"

echo "Creating code-server deployment..."

read -p "Choose a password for code-server: " password

echo "
apiVersion: v1
kind: PersistentVolume
metadata:
  name: vscode-config
  labels:
    code-server: config
spec:
    capacity:
        storage: 2Gi
    accessModes:
        - ReadWriteMany
    persistentVolumeReclaimPolicy: Retain
    claimRef:
      namespace: $project
      name: vscode-config
    local:
        path: /mnt/config
    nodeAffinity:
      required:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
            - okd-cp-1.okd.osupytheas.fr
            - okd-cp-2.okd.osupytheas.fr
            - okd-cp-3.okd.osupytheas.fr
            - worker-1.okd.osupytheas.fr
            - worker-2.okd.osupytheas.fr
" > pv.yaml
echo "
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: vscode-config
  labels:
    app: code-server
  namespace: $project
spec:
  accessModes:
    - ReadWriteMany
  selector:
    matchLabels:
      code-server: config
  resources:
    requests:
      storage: 2Gi
" > pvc.yaml
echo "
kind: Deployment
apiVersion: apps/v1
metadata:
  name: code-server
  namespace: $project
  labels:
    app: code-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: code-server
  template:
    metadata:
      labels:
        app: code-server
    spec:
      containers:
        - name: code-server
          image: linuxserver/code-server
          imagePullPolicy: Always
          volumeMounts:
            - name: vscode-config
              mountPath: /config
          env:
            - name: PUID
              value: '1000'
            - name: PGID
              value: '1000'
            - name: TZ
              value: 'Europe/Paris'
            - name: PASSWORD
              value: '$password'
            - name: SUDO_PASSWORD
              value: '$password'
      initContainers:
        - args:
            - clone
            - '--single-branch'
            - '--'
            - '$repo'
            - '/config/workspace'
          image: alpine/git
          name: init-clone-repo
          resources: {}
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          volumeMounts:
            - mountPath: /config
              name: vscode-config
        # - args:
        #     - config
        #     - '--global'
        #     - 'user.name'
        #     - '$username'
        #   image: alpine/git
        #   name: init-git-config-user
        #   resources: {}
        #   terminationMessagePath: /dev/termination-log
        #   terminationMessagePolicy: File
        # - args:
        #     - config
        #     - '--global'
        #     - 'user.email'
        #     - '$email'
        #   image: alpine/git
        #   name: init-git-config-email
        #   resources: {}
        #   terminationMessagePath: /dev/termination-log
        #   terminationMessagePolicy: File
      volumes:
        - name: vscode-config
          persistentVolumeClaim:
            claimName: vscode-config
" > deploy.yaml
echo "
apiVersion: v1
kind: Service
metadata:
  name: code-server
  labels:
    app: code-server
  namespace: $project
spec:
    selector:
        app: code-server
    ports:
        - protocol: TCP
          port: 8443
          targetPort: 8443
          name: 8443-tcp
    type: ClusterIP
" > svc.yaml
echo "
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: code-server
  namespace: $project
  labels:
    app: code-server
spec:
    host: code-server.$project.apps.okd.osupytheas.fr # Or any other domain you want
    port:
        targetPort: 8443
    tls:
        insecureEdgeTerminationPolicy: Redirect
        termination: edge
    to:
        kind: Service
        name: code-server
        weight: 100
    wildcardPolicy: None
" > route.yaml

oc apply -f deploy.yaml -f svc.yaml -f route.yaml -f pv.yaml -f pvc.yaml


echo "Deployment created"

echo "You can now access your code-server instance at https://code-server.dev.apps.okd.osupytheas.fr"
echo "The default password is 'password'"
