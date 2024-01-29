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
    while true; do
        echo "Please enter your username: "
        read username
        echo ""
    done
    while true; do
        echo "Please enter your password: "
        read password
        echo ""
    done
    while true; do
        echo "Please enter your API endpoint for the cluster (don't forget the https:// prefix and the port number): "
        read endpoint
        echo ""
    done
    while true; do
        echo "Connecting to the cluster using your credentials..."
        echo ""
        echo ""
        oc login -u $username -p $password -s $endpoint --insecure-skip-tls-verify -n dev > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "Successfully logged in"
            break
        else
            echo "Failed to log in to the cluster"
            continue
        fi
    done
fi
while true; do
    read -p "Which app you wanna connect to ? " app
    if [[ ! $(oc get pods | grep $app | shuf | head -n 1 | cut -d " " -f 1) == *"$app"* ]]; then
        echo "wrong app name"
        continue
    else
        pod=$(oc get pods | grep $app | shuf | head -n 1 | cut -d " " -f 1)
        break
    fi
done

echo "Selected pod: $pod"
if ! command -v nc &> /dev/null; then
  $SUDO apt install -y netcat
fi
while true;do
  read -p "Which port do you want the pod running on your local machine ? " port
  if echo PING | nc localhost $port >/dev/null; then
        echo "Port $port in use"
        continue
  else
        oc port-forward $pod -n dev $port:2222 &
        break
  fi
done
sleep 2

echo "pod forwaded successfully"
# Use this command to ssh on the pod
#echo "SSH on the pod $1"
#ssh dev@localhost -p $2

# To kill the port-forwarding process, use the following command:
#echo "Stopping the port-forwarding process..."
#pkill -f "port-forward"

# To Log out of the cluster, use the following command:
#echo "Logging out of the cluster..."
#oc logout