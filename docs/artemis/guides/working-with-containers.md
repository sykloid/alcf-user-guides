# Working with Containers and Registries

Deploying a custom workload to an Artemis cluster begins with a container image; this guide covers building it, storing it in a registry the cluster can reach, and referencing it from your workload so Kubernetes can pull it.

## Building and Pushing Containers

There are many ways to build and push a container image; this guide covers two of them: using Podman from your workstation, and using Kaniko from within the cluster.

### Preparing a Build Context

Building a container image requires two inputs:

- A `Containerfile` (also called a `Dockerfile`): the base image and the sequence of instructions used to construct the final image.
- A *build context*: the set of files available to the builder as the `Containerfile` is interpreted, most often the directory containing the `Containerfile` itself.

### Preparing Your Registry

Pushing an image requires a remote *registry* that is reachable from both your build location and the deployment cluster.

For Artemis, we strongly recommend ALCF's [GitLab container registry](https://docs.gitlab.com/user/packages/container_registry/) at `gitlab-ci.alcf.anl.gov:8443`. Each ALCF GitLab project has its own section of the registry, and it is where we run the scans and safeguards that let images be deployed safely to ALCF Kubernetes clusters. Images from other registries (such as Docker Hub) are not currently blocked, but that may change.

An image in the registry is addressed as `gitlab-ci.alcf.anl.gov:8443/<project-path>/<image>[:<tag>]`. The `<project-path>` must be an existing GitLab project you can write to; `<image>` and any further path segments are yours to choose. For example, the project `my-group/my-project` can hold an image at:

```text
gitlab-ci.alcf.anl.gov:8443/my-group/my-project/my-image:latest
```

### Building and Pushing Locally using Podman

[Podman](https://podman.io/) is an open-source container runtime and frontend that you can use interactively on your own laptop, workstation, or server, to build an image from a `Containerfile` and build context and push it to a remote registry.

First, [authenticate to the registry](https://docs.gitlab.com/user/packages/container_registry/authenticate_with_container_registry/) using a credential with the `read_registry` and `write_registry` scopes:

```console
$ podman login gitlab-ci.alcf.anl.gov:8443
```

Next, build the image, tagging it with its full registry path:

```console
$ podman build -t gitlab-ci.alcf.anl.gov:8443/my-group/my-project/my-image:latest .
```

Then push it:

```console
$ podman push gitlab-ci.alcf.anl.gov:8443/my-group/my-project/my-image:latest
```

You can confirm the image and tag are present by browsing to your project's container registry in the GitLab web interface, under **Deploy > Container Registry**.

!!! warning "Containers are Architecture-Specific"

    Images are built for the architecture of the machine you build on. An image built on an ARM machine (such as an Apple Silicon Mac) will fail to run on Artemis, whose nodes are `x86-64`. Build for the target architecture explicitly with `--platform`:

    ```console
    $ podman build --platform linux/amd64 -t gitlab-ci.alcf.anl.gov:8443/my-group/my-project/my-image:latest .
    ```

    or use a build machine whose architecture matches the cluster you intend to deploy on.

### Building and Pushing from GitLab CI using Kaniko

Building in the cluster runs the build on the same architecture as your deployment, avoiding the mismatch described above. The simplest way to do this is with [Kaniko](https://github.com/osscontainertools/kaniko), which builds an image from a `Containerfile` without a running Docker daemon, executed as a job on the `hermes` GitLab CI runner.

Add a `build-image` job to your project's `.gitlab-ci.yml`. The example below builds the `Containerfile` at the repository root and pushes the result to the project's own registry, tagged with the commit SHA and `latest`:

```yaml
stages:
  - build

build-image:
  stage: build
  tags:
    - hermes
  image:
    name: ghcr.io/osscontainertools/kaniko:debug
  before_script:
    - echo "{\"auths\":{\"${CI_REGISTRY}\":{\"username\":\"${CI_REGISTRY_USER}\",\"password\":\"${CI_REGISTRY_PASSWORD}\"}}}" > /kaniko/.docker/config.json
  script:
    - /kaniko/executor
      --context="${CI_PROJECT_DIR}"
      --dockerfile="${CI_PROJECT_DIR}/Containerfile"
      --build-arg HTTP_PROXY="${HTTP_PROXY}"
      --build-arg HTTPS_PROXY="${HTTPS_PROXY}"
      --build-arg NO_PROXY="${NO_PROXY}"
      --destination="${CI_REGISTRY_IMAGE}:${CI_COMMIT_SHORT_SHA}"
      --destination="${CI_REGISTRY_IMAGE}:latest"
```

The `hermes` tag directs the job to the Artemis CI runner, which also supplies the `HTTP_PROXY`, `HTTPS_PROXY`, and `NO_PROXY` variables the build needs for outbound network access. Authentication uses GitLab's built-in `CI_REGISTRY_*` variables, so no separate credential is required: the `before_script` writes them into the configuration file Kaniko reads, and `CI_REGISTRY_IMAGE` expands to your project's registry path. Each `--destination` publishes the image under a tag, so this job pushes both a commit-specific tag and `latest`.

!!! note "Enabling the runner"

    The job stays pending until a `hermes`-tagged runner is enabled for your project. If your project is not already configured with one, contact ALCF support.

As with a local push, you can confirm the result under **Deploy > Container Registry**.

## Using Containers from Artemis

Regardless of how it was built, the end result is an image in the registry. Deploying a workload that uses it requires two things: a reference to the image, and a credential that lets the cluster pull it from your private registry.

### Referencing the Image

Set the container's `image` field to the full path of the image you pushed, and list the pull credential (created below) under `imagePullSecrets`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-app
          image: gitlab-ci.alcf.anl.gov:8443/my-group/my-project/my-image:latest
      imagePullSecrets:
        - name: registry-credentials
```

### Providing Pull Credentials

A private registry only serves clients that authenticate, and the cluster is no exception. Kubernetes reads registry credentials from a secret of type `kubernetes.io/dockerconfigjson`, referenced from the pod through `imagePullSecrets`.

Create the secret in your namespace using a [deploy token](https://docs.gitlab.com/user/project/deploy_tokens/) scoped to `read_registry`:

```console
$ kubectl create secret docker-registry registry-credentials \
    --docker-server=gitlab-ci.alcf.anl.gov:8443 \
    --docker-username=<deploy-token-username> \
    --docker-password=<deploy-token>
```

With the secret in place and referenced under `imagePullSecrets`, the cluster can pull the image when the workload is applied. If it cannot, the pod reports `ImagePullBackOff`; inspect the cause with:

```console
$ kubectl -n <namespace> events
```

!!! tip "Managing the credential as a secret"

    The pull credential is an ordinary Kubernetes secret. To keep it out of your manifests and in sync with a source of truth, define it as an `ExternalSecret` rather than creating it by hand -- see [Secrets Management](secrets.md).

## Links, References, and Recommended Reading

- [Podman](https://podman.io/)
    - [podman build](https://docs.podman.io/en/latest/markdown/podman-build.1.html)
    - [podman push](https://docs.podman.io/en/latest/markdown/podman-push.1.html)
- [GitLab Container Registry](https://docs.gitlab.com/user/packages/container_registry/)
    - [Authenticate with the container registry](https://docs.gitlab.com/user/packages/container_registry/authenticate_with_container_registry/)
    - [Build and push by using GitLab CI/CD](https://docs.gitlab.com/user/packages/container_registry/build_and_push_images/)
    - [Deploy tokens](https://docs.gitlab.com/user/project/deploy_tokens/)
- [Kaniko](https://github.com/osscontainertools/kaniko)
- [Kubernetes](https://kubernetes.io/docs/)
    - [Pull an Image from a Private Registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)
