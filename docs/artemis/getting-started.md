# Getting Started

!!! warning "Artemis is in Preview"

    The Artemis platform is currently in preview with a single active cluster -- `hermes`.

    While the tools and technologies used are expected to remain stable as the platform transitions to general availability, all aspects of this documentation are subject to change during this preview period.

## Gaining Access to Artemis

You will need to complete a few steps of bookkeeping in order to gain access to the cluster and proceed with this tutorial.

1. You must first get `hermes` added as a resource to your ALCF account. This should be as simple as posting a request in the [`#alcf_hermes`][hermes-slack] Slack channel and being confirmed by cluster administrators. This step needs only to be performed once per user, even if you are working on multiple projects within the cluster.
2. You will need to be part of a `hermes` _tenant_, which is the unit of user access and permissions management within the cluster. Each tenant is associated with an ALCF project or UNIX group.
    1. If you are already part of an ALCF project or UNIX group that has an allocated tenant, no further action is needed on your part.
    2. If you are the PI of an ALCF project or the owner of a UNIX group which you would like to associate with a new tenant, make a post in the [`#alcf_hermes`][hermes-slack] Slack channel stating that you would like this tenant to be created for you, with the name of the group.
    3. If you would like to have a new UNIX group created for you, send an email to <support@alcf.anl.gov> with that request. Once you have received confirmation that the group has been created, follow the step above to complete the process.

At the conclusion of this sequence of steps, you should be a member of a project or UNIX group. If you are also the PI of the project or the owner of the group, you should be able to use the interfaces available at [myALCF](https://my.alcf.anl.gov) to manage membership within this tenant.

## Prerequisite Tools

To get started using Artemis, you will need the following tools available in an environment **connected to the Argonne VPN**. Ideally, this environment is your personal workstation, but can also be an ALCF bastion host.

- [**kubectl**](https://kubernetes.io/docs/tasks/tools/#kubectl): The Kubernetes CLI, necessary for most of the cluster-interaction in this documentation.
- [**kubectl oidc-login plugin**](https://github.com/int128/kubelogin): The Kubernetes OIDC-plugin, necessary to allow `kubectl` to authenticate with ALCF.

## Testing Cluster Connectivity

Start by downloading the [user configuration file](assets/user@hermes.kubeconfig.yml). You may tell `kubectl` to find this file in one of the following ways:

- Place the file at `$HOME/.kube/config`
- Store the path of the file in the `$KUBECONFIG` environment variable.
- Pass the path of the file to every `kubectl` invocation using the `--kubeconfig` flag.

You should now be able to run:

```console
$ kubectl auth whoami
ATTRIBUTE                                           VALUE
Username                                            alcf:<your-ALCF-username>
Groups                                              [<a-list-of-your-LDAP-groups>, system:authenticated]
Extra: authentication.kubernetes.io/credential-id   [JTI=<a-long-uuid>]
```

This should pop you out to a browser to perform an ALCF CryptoCard/MobilePass authentication flow. Type your credentials in, and close the browser window when prompted to.

You are now connected to the cluster! You will be prompted periodically to redo the authentication flow.

??? tip "Large volumes of error messages when attempting to use `kubectl`?"

    Are you connected to the Argonne VPN?

??? tip "Seeing a `"<resource> is forbidden"` error?"

    If you are seeing the following error message (or variation thereof):

    ```
    Error from server (Forbidden): <resource> is forbidden: User "alcf:<user>" cannot list resource "<resource>" in API group "<group>" [at the cluster scope][in the namespace <namespace>]
    ```

    You have successfully connected and authenticated with the cluster, but are not authorized to run the command you are trying to run. Make sure you are a member of a valid tenant, and are accessing resources within that tenant.

## Accessing your Tenant

If you have gotten this far, it means that you are part of a tenant, and have an associated namespace (the name of which should have been communicated to you as part of tenant creation).

You can verify this state as follows:

```console
$ kubectl get all -n <tenant-namespace>
No resources found in <tenant-namespace> namespaces.
```

## Deploying to your Tenant

You are now free to deploy resources to your namespace as needed. As a simple example, create the following file, named `nginx.yml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: <tenant-namespace>
spec:
  containers:
    - name: nginx
      image: nginx
```

As you may have guessed, this file describes a _pod_ resource object, which runs a single instance of an `nginx` web server, as a container. You can apply this object to the cluster as follows:

```console
$ kubectl apply -n <tenant-namespace> -f nginx.yml
pod/nginx created
$ kubectl get pod -n <tenant-namespace>
NAME                       READY   STATUS    RESTARTS   AGE
nginx                      1/1     Running   0          12s
```

To access this server from your environment, you must port-forward to the pod:

```console
$ kubectl port-forward -n <tenant-namespace> pod/nginx 8080:80
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

and either visit <http://localhost:8080> in your browser, or `curl http://localhost:8080`:

```console
$ curl http://localhost:8080
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

[hermes-slack]: https://grid-cels-anl.enterprise.slack.com/archives/C0AC6FQPTTK
