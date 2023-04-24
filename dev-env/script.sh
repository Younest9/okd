#!/bin/bash

# Please run this script from the svc vm
# This script will create a new project for developement, create a persistent volume to store the git repository code, create a persistent volume claim to use the persistent volume, create a route to access the code-server service, and deploy the code-server service
# This script will also install the gitlab-runner and deploy it in the same project as the code-server service
# This script will also install the oc and kubectl command line tools if they are not installed
# This script will also install the helm command line tool if it is not installed


if [[ $EUID != 0 ]] ; then
# Check if the user is root, elevate if not (using sudo)
    SUDO='sudo'
fi

if ! command -v oc &> /dev/null; then
# Check if oc is installed, install it if not
  if [ "$(cat /etc/*-release | grep ID | grep -v -e VERSION_ID | cut -d "=" -f 2 | head -1)" = "debian" ] || [ "$(cat /etc/*-release | grep ID | grep -v -e VERSION_ID | cut -d "=" -f 2 | head -1)" = "ubuntu" ]; then
  # Check if the OS is debian or ubuntu, install oc if it is
    $SUDO apt update
    $SUDO apt install wget curl -y
    $SUDO wget https://github.com/okd-project/okd/releases/download/4.12.0-0.okd-2023-04-16-041331/openshift-client-linux-4.12.0-0.okd-2023-04-16-041331.tar.gz
    $SUDO tar xzf openshift-client-linux-4.12.0-0.okd-2023-04-16-041331.tar.gz
    $SUDO mv kubectl oc /usr/local/bin/
    $SUDO rm openshift-client-linux-4.12.0-0.okd-2023-04-16-041331.tar.gz README.md
  else
    if [ "$(cat /etc/*-release | grep ID | grep -v -e VERSION_ID | cut -d "=" -f 2 | head -1)" = "centos" ]; then
    # Check if the OS is centos, install oc if it is
      $SUDO yum install wget curl -y
      $SUDO wget https://github.com/okd-project/okd/releases/download/4.12.0-0.okd-2023-04-16-041331/openshift-client-linux-4.12.0-0.okd-2023-04-16-041331.tar.gz
      $SUDO tar xzf openshift-client-linux-4.12.0-0.okd-2023-04-16-041331.tar.gz
      $SUDO mv kubectl oc /usr/local/bin/
      $SUDO rm openshift-client-linux-4.12.0-0.okd-2023-04-16-041331.tar.gz README.md
    else
        if [ "$(cat /etc/*-release | grep ID | grep -v -e VERSION_ID | cut -d "=" -f 2 | head -1)" = "fedora" ]; then
        # Check if the OS is fedora, install oc if it is
          $SUDO dnf install wget curl -y
          $SUDO wget https://github.com/okd-project/okd/releases/download/4.12.0-0.okd-2023-04-16-041331/openshift-client-linux-4.12.0-0.okd-2023-04-16-041331.tar.gz
          $SUDO tar xzf openshift-client-linux-4.12.0-0.okd-2023-04-16-041331.tar.gz.gz
          $SUDO mv kubectl oc /usr/local/bin/
          $SUDO rm openshift-client-linux-4.12.0-0.okd-2023-04-16-041331.tar.gz README.md
        fi
    fi
  fi
fi

# Function to print asterisks for each character entered
# mask_input() {
    # # Initialize password variable
    # password=''
    # # Allowed characters
    # allowed_chars='A-Za-z0-9_@./#&+-'
    # # Read input from either stdin or clipboard
    # if [[ -t 0 ]]; then
    #     read -rs -d '' input
    # else
    #     input=$(xclip -o -selection clipboard)
    # fi
    # # Print newline character to move cursor to next line after pasting input
    # printf '\n'
    # # Loop through each character in the input
    # for (( i=0; i<${#input}; i++ )); do
    #     char="${input:$i:1}"
    #     # Break out of loop if Enter key is pressed
    #     if [[ $char == $'\0' ]]; then
    #        break
    #     fi
    #     # Check if character is the delete key
    #     if [[ $char == $'\177' ]]; then
            # Delete the last character from the password string and move the cursor back one space
    #        if [[ ${#password} -gt 0 ]]; then
    #            password=${password%?}
    #            printf '\b \b'
    #        fi
    #     # Check if character is a valid alphanumeric or special character
    #     elif [[ $char =~ [$allowed_chars] ]]; then
    #         # Print asterisk for each character entered
    #         printf '*'
    #         password+="$char"
    #     fi
    # done
# }






if [[ $(oc projects 2> /dev/null) == *"You have access to the following projects and can switch between them with ' project <projectname>':"* ]]; then
# Check if the user is already logged in
    echo "User is already logged in"
else
# If the user is not logged in, ask for credentials, and the api 
    echo "Log In to the cluster..."
    echo ""
    while true; do
    # Ask for the api url, username and password to login
        echo "Please enter the API URL of your cluster with the port number and https protocol (Normally it's: https://api.<cluster-name>.<base-domain>:6443): "
        read -re api_url
        history -s "$api_url"
        read -rep "Please enter your username: " username
        history -s "$username"
        printf "Please enter your password: "
        read -rep "" password
        history -s "$password"
        echo ""
        echo "Connecting to the cluster using your credentials..."
        if [[ "$(oc login -u "$username" -p "$password" -s $api_url  --insecure-skip-tls-verify 1> /dev/null)" == *"error"* ]]; then
        # Check if the server is reachable (no server error), if not, exit the script
            echo "Server is not reachable"
            echo "Please check that your cluster is running"
            echo "If your cluster is running, please check the apiserver pods in the openshift-oauth-apiserver namespace"
            echo "Try Executing this script again after you have fixed the issue"
            exit 1
        fi
        if oc login -u "$username" -p "$password" -s $api_url --insecure-skip-tls-verify > /dev/null 2>&1 ; then
        # If the server is reachable, try to login with the credentials provided
            echo "Successfully logged in"
            break
        else
        # If the login fails, ask for the credentials again
            echo "Failed to log in to the cluster"
            echo "Please check your credentials and try again"
            continue
        fi
    done
fi
# Output all the projects available to the user (execpt the system projects)
echo "Available projects:"
oc projects | grep -v NAME | grep -v openshift | grep -v kube- | grep -v "You have access to the following projects and can switch between them with ' project <projectname>':" | grep -v "Using project"
echo ""
# Output the current project
echo "You are currently connected to the project: $(oc project -q)"
echo ""
# Ask if the user wants to create a new project
read -rep "Do you want to create a new project ? [Y/n] : " create
echo ""
project=$(oc project -q)
if  [[ ($create == "yes")  || ($create == "y") || ($create == "O") || ($create == "Y") || ($create == "Yes") || ($create == "YES") || ($create == "Oui") || ($create == "OUI") ]]; then
# If the user wants to create a new project, ask for the name, display name and description of the project
    echo "Please enter the name of the project you want to create (required):"
    read -re project
    history -s "$project"
    echo "Please enter the display name of the project you want to create (optional)"
    read -re display
    history -s "$display"
    echo "Please enter the description of the project you want to create (optional)"
    read -re description
    history -s "$description"
    echo ""
    oc new-project "$project" --display-name="$display" --description="$description"
    oc project "$project"
else
# If the user does not want to create a new project, ask if he wants to change the current project
  while true; do
    echo "Current project: $project"
    echo ""
    read -rep "Do you want to change the current project ? [Y/n] : " change
    echo ""
    if [[ ($change == "no") || ($change == "n") || ($change == "N") || ($change == "No") || ($change == "NO") || ($change == "Non") || ($change == "NON") ]]; then
    # If the user does not want to change the current project, stick with the current project
        break
    fi
    # If the user wants to change the current project, ask for the name of the project
    read -rep "Please enter the name of the name of the project that you want to connect to: "  project
    echo ""
    if oc project "$project" > /dev/null 2>&1; then
    # If the project doesn't exist, ask for the name of the project again
        echo "Project $project does not exist"
        continue
    fi
    # If the project exists, connect to it
    oc project "$project"
    break
  done
fi

# Ask for the git instance url
while true; do
  read -rep "Git instance URL (required): " git_url
  history -s "$git_url"
  if [[ $repo != "" && ( $repo == *".com"* || $repo == *".fr"* ) && ( $repo == *"gitlab"* || $repo == *"github"* ) ]]; then
    break
  else
    echo "Please enter a valid git instance URL"
    continue
  fi
done

if [[ $git_url == "https://"* ]]; then
# If the git instance url starts with https://, remove it
    git_url=${git_url#"https://"}
else
  if [[ $git_url == "http://"* ]]; then
  # If the git instance url starts with http://, remove it
      git_url=${git_url#"http://"}
  fi
fi
if [[ $git_url == *"/"* ]]; then
# If the git instance url contains a / at the end, remove it
    git_url=${git_url%"/"}
fi
# Ask if the user wants to create a new git repository
read -rep "Git username: " username
read -rep "Git password: " email

read -rep "Do you want to create a new git repository ? [Y/n] : " create
echo ""
if  [[ ($create == "yes")  || ($create == "y") || ($create == "O") || ($create == "Y") || ($create == "Yes") || ($create == "YES") || ($create == "Oui") || ($create == "OUI") ]]; then
  read -rep "Git repository name (required): " repo_name
  mkdir $repo_name
  cd $repo_name
  git init
  touch README.md .gitignore
  git add -A
  git commit -m "Initial commit"
  git remote add origin https://$username:$password@$git_url/$username/$repo_name.git
  git push --set-upstream https://$username:$password@$git_url/$username/$repo_name.git
  cd ..
  rm -rf $repo_name
  repo="https://$git_url/$username/$repo_name.git"
else
# If the user does not want to create a new git repository, ask for the git repository url
  while true; do
    read -rep "Git repository URL (required): " repo
    if [[ $repo != "" && ( $repo == *".com"* || $repo == *".fr"* ) && $repo == *"git"* && $repo == *"$username"* ]]; then
        break
    else
        echo "Please enter a valid git repository URL"
        continue
    fi
  done
fi
echo ""
echo "Creating git credentials secret..."
while true; do
  if [[ $(oc create secret generic git-creds --from-literal=username="$username" --from-literal=password="$password" --namespace="$project") = *"Error from server (AlreadyExists): secrets \"git-creds\" already exists"* ]]; then
      echo "Git credentials secret already exists"
      echo 
      read -rep "Do you want to update the secret ? [Y/n] : " update
      if [[ ($update == "yes") || ($update == "y") || ($update == "O") || ($update == "Y") || ($update == "Yes") || ($update == "YES") || ($update == "Oui") || ($update == "OUI") ]]; then
          oc delete secret git-creds --namespace="$project"
          oc create secret generic git-creds --from-literal=username="$username" --from-literal=password="$password" --namespace="$project"
      fi
      break
  fi
  if [[ $(oc create secret generic git-creds --from-literal=username="$username" --from-literal=password="$password" --namespace="$project") == *"error: failed to create secret Unauthorized"* ]]; then
      echo "Failed to create secret"
      echo "Server is not reachable or you have been disconnected from the cluster"
      exit 1
  fi
  echo "Git credentials secret created"
  break
done
echo ""
echo "Creating code-server deployment..."

read -rep "Choose a password for code-server: " password

cat <<EOF > pv.yaml
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
EOF

cat <<EOF > pvc.yaml
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
EOF
cat <<EOF > deploy.yaml
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
EOF
cat <<EOF > svc.yaml
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
EOF
cat <<EOF > route.yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: code-server
  namespace: $project
  labels:
    app: code-server
spec:
    host: code-server.$project.apps.okd.osupytheas.fr # Or any other domain you want (you will need to add it to your DNS server)
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
EOF


while true; do
  if oc apply -f deploy.yaml -f svc.yaml -f route.yaml -f pv.yaml -f pvc.yaml 2> /dev/null; then
    break
  fi
  echo "Failed to deploy code-server"
  echo "Server is not reachable or you have been disconnected from the cluster"
  echo "Trying again in 5 seconds..."
  sleep 5
  oc delete -f deploy.yaml -f svc.yaml -f route.yaml -f pv.yaml -f pvc.yaml >/dev/null 2>&1
  oc apply -f deploy.yaml -f svc.yaml -f route.yaml -f pv.yaml -f pvc.yaml 
done
if oc delete -f deploy.yaml -f svc.yaml -f route.yaml -f pv.yaml -f pvc.yaml >/dev/null 2>&1; then
    echo "Successfully deployed code-server"
else
    echo "Failed to deploy code-server"
    exit 1
fi
echo ""
echo "You can now access your code-server instance at https://code-server.$project.apps.okd.osupytheas.fr"

echo "The default password is 'password'"

echo "You can change it by running the following command:"
echo "oc set env deployment/code-server PASSWORD=<your_password> -n $project"

echo ""
echo "GitLab runner deployment"

echo "Installing helm..."
echo "Install dependencies"
if [ "$(cat /etc/*-release | grep ID | grep -v -e VERSION_ID | cut -d "=" -f 2 | head -1)" = "debian" ] || [ "$(cat /etc/*-release | grep ID | grep -v -e VERSION_ID | cut -d "=" -f 2 | head -1)" = "ubuntu" ]; then
    $SUDO apt-get update
    $SUDO apt-get install apt-transport-https --yes
    $SUDO apt-get install ca-certificates --yes
    $SUDO apt-get install curl --yes
    $SUDO apt-get install gnupg --yes
    $SUDO apt-get install lsb-release --yes
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | $SUDO tee /usr/share/keyrings/helm.gpg > /dev/null
    echo "Add helm repository"
    echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | $SUDO tee /etc/apt/sources.list.d/helm-stable-debian.list
    $SUDO apt-get update
    $SUDO apt-get install helm --yes
fi
if [ "$(cat /etc/*-release | grep ID | grep -v -e VERSION_ID | cut -d "=" -f 2 | head -1)" = "fedora" ]; then
    $SUDO dns install helm --yes
fi
if [ "$(cat /etc/*-release | grep ID | grep -v -e VERSION_ID | cut -d "=" -f 2 | head -1)" = "centos" ]; then
    $SUDO yum install helm --yes
fi
echo "Helm installed"
echo "Installing gitlab runner..."
echo "Add gitlab helm repository"
helm repo add gitlab https://charts.gitlab.io
helm repo update
echo "Install gitlab runner"
helm install --namespace gitlab-runner --create-namespace -f https://raw.githubusercontent.com/Younest9/okd/main/dev-env/values.yaml gitlab-runner gitlab/gitlab-runner
echo "Gitlab runner installed"
echo "GitLab runner deployed"
