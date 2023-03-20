## SSH into a container OKD
### SSH using rsh command :  ```oc rsh <pod>```
>#### You should note that the following commands are valid if you have direct access to the kubeconfig file

To open a remote shell session to a container, use this command
```bash
oc rsh [-c CONTAINER] [flags] (POD | TYPE/NAME) COMMAND [args...]
````

>This command will attempt to start a shell session in a pod for the specified resource. It works with pods, deployment
configs, deployments, jobs, daemon sets, replication controllers and replica sets. Any of the aforementioned resources (apart from pods) will be resolved to a ready pod. It will default to the first container if none is specified, and will attempt to use '/bin/sh' as the default shell. You may pass any flags supported by this command before the resource name, and an optional command after the resource name, which will be executed instead of a login shell. A TTY will be automatically allocated if standard input is interactive - use -t and -T to override. A TERM variable is sent to the environment where the shell (or command) will be executed. By default its value is the same as the TERM variable from the local environment; if not set, 'xterm' is used.  
<b>Note</b>: some containers may not include a shell - use '```oc exec```' if you need to run commands directly.

<b>Usage:</b>
  

&nbsp;&nbsp;&nbsp;&nbsp;Examples:  
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Open a shell session on the first container in pod 'foo'
                                                  ```bash
                                                  oc rsh foo
                                                  ```
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Open a shell session on the first container in pod 'foo' and namespace 'bar'
  >(Note that oc client specific arguments must come before the resource name and its arguments)
                                                  ```bash
                                                  oc rsh -n bar foo
                                                  ```
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Run the command 'cat /etc/resolv.conf' inside pod 'foo'
                                                  ```bash
                                                  oc rsh foo cat /etc/resolv.conf
                                                  ```

  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;See the configuration of your internal registry
                                                  ```bash
                                                  oc rsh dc/docker-registry cat config.yml
                                                  ```

  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Open a shell session on the container named 'index' inside a pod of your job
                                                  ```bash
                                                  oc rsh -c index job/scheduled
                                                  ```

><b>Options:</b>  
>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-c, --container='': Container name; defaults to first container  
>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-f, --filename=[]: to use to rsh into the resource  
>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-T, --no-tty=false: Disable pseudo-terminal allocation  
>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--pod-running-timeout=1m0s: The length of time (like 5s, 2m, or 3h, higher than zero) to wait until at least one  
>&nbsp;&nbsp;&nbsp;&nbsp;<b>If pod is running</b>  
>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;--shell='/bin/sh': Path to the shell command  
>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-t, --tty=false: Force a pseudo-terminal to be allocated

To list of global command-line options, use the following command:
```bash
oc options
```
>The last command applies to all commands above.

### SSH using port-forwarding

after some researches, we came to a single deduction: <strong>We can't do SSH directly on a pod through the route</strong>

though, i made a workaround using port-forwarding that'll make us do SSH to a pod, but using a script that i made : [port-forwarding.sh](./port-forwarding.sh)

<strong>Sources: </strong>

[Openshift/origin - About the ssh support in router (GitHub issue #6755)](https://github.com/openshift/origin/issues/6755)

[Opening a Remote Shell to Containers](https://docs.okd.io/3.11/dev_guide/ssh_environment.html)
