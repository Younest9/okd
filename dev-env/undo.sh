oc delete -f deploy.yaml -f svc.yaml -f route.yaml -f pvc.yaml -n test
oc delete -f pv.yaml

oc logout