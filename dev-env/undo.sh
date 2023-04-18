echo "Delete the code-server deployment, service, route, and persistent volume claim (pvc) in the $(oc project -q) project"
oc delete -f deploy.yaml -f svc.yaml -f route.yaml -f pvc.yaml -n test

echo "Delete the persistent volume (pv)"
oc delete -f pv.yaml

echo "Delete the unnecessary files"
rm -f deploy.yaml svc.yaml route.yaml pv.yaml pvc.yaml

echo "Do you want to delete the project? (y/n)"
read delete_project

if [ $delete_project == "y" ]; then
    echo "Delete the project"
    oc delete project $project
fi

echo "Do you want to logout from the cluster? (y/n)"
read logout

if [ $logout == "y" ]; then
    echo "Logout from the cluster"
    oc logout
fi