# Spring on Kubernetes: Deploying and Managing Cloud-Native Applications
This is the repository for the LinkedIn Learning course `Spring on Kubernetes: Deploying and Managing Cloud-Native Applications`. The full course is available from [LinkedIn Learning][lil-course-url]. The [GitHub][github-repo-url] from course.

## Course Description

<p>Interested in building a cloud-native application with Spring Boot? This course was designed for you. Join instructor Frank P Moley III as he outlines the basics of creating images, including native images for eventual deployment to Kubernetes. Get a comprehensive overview of the entire development lifecycle of deploying and testing an application. Along the way, Frank covers some additional real-world operational concerns related to deploying applications with this methodology, including testing strategies, automation in CI/CD, security considerations, and more.</p><p>This course is integrated with GitHub Codespaces, an instant cloud developer environment that offers all the functionality of your favorite IDE without the need for any local machine setup. With GitHub Codespaces, you can get hands-on practice from any machine, at any time-all while using a tool that you'll likely encounter in the workplace. Check out the "Using GitHub Codespaces with this course" video to learn how to get started.</p>

_See the readme file in the main branch for updated instructions and information._
## Instructions
This repository has branches for each of the videos in the course. You can use the branch pop up menu in github to switch to a specific branch and take a look at the course at that stage, or you can add `/tree/BRANCH_NAME` to the URL to go to the branch you want to access.

## Branches
The branches are structured to correspond to the videos in the course. The naming convention is `CHAPTER#_MOVIE#`. As an example, the branch named `02_03` corresponds to the second chapter and the third video in that chapter. 
Some branches will have a beginning and an end state. These are marked with the letters `b` for "beginning" and `e` for "end". The `b` branch contains the code as it is at the beginning of the movie. The `e` branch contains the code as it is at the end of the movie. The `main` branch holds the final state of the code when in the course.

When switching from one exercise files branch to the next after making changes to the files, you may get a message like this:

    error: Your local changes to the following files would be overwritten by checkout:        [files]
    Please commit your changes or stash them before you switch branches.
    Aborting

To resolve this issue:
	
    Add changes to git using this command: git add .
	Commit changes using this command: git commit -m "some message"

## Running the local Kubernetes environment

The `scripts/` directory sets up a local `kind` cluster with ingress-nginx, the kube-prometheus-stack monitoring stack, and a CloudNativePG-managed Postgres instance, then seeds it with sample data.

### Prerequisites

- `docker`, `kubectl`, `helm`, and `kind` available on your `PATH`
- Inside GitHub Codespaces, these are already provided by the devcontainer

### Setup

```bash
cd scripts
./install.sh
```

This runs, in order: `kind` cluster creation, ingress-nginx, the monitoring stack, CloudNativePG + the `localdb` Postgres cluster, then `populate-db.sh` to load `dat/data.sql`. Each step waits on the previous one's actual readiness (nodes ready, deployments available, Postgres instance pods ready) before continuing, so a slow step won't cause a later one to fail against a resource that isn't up yet.

Once finished, Postgres is reachable at `localhost:5432` (via the ingress's TCP passthrough) using the credentials in the `localdb-secret` Secret (`postgres` namespace):

```bash
kubectl get secret localdb-secret -n postgres -o jsonpath='{.data.username}' | base64 -d
kubectl get secret localdb-secret -n postgres -o jsonpath='{.data.password}' | base64 -d
```

Grafana, Prometheus, and Alertmanager are exposed as NodePorts `31000`, `30000`, and `32000` respectively.

### Teardown

```bash
cd scripts
./destroy.sh
```

Deletes the `kind` cluster named `local` entirely.

### Known issue: DNS inside GitHub Codespaces

Some Codespaces (notably Azure-hosted ones) block outbound UDP:53 to public DNS resolvers, which can make the `kind` node unable to resolve registries like `ghcr.io`, even though the Codespace host itself has working DNS. `config/kind/deploy.sh` works around this automatically by pointing the node at whichever non-loopback nameserver the host itself was given, and `config/postgres/deploy.sh` preloads the operator and Postgres images from the host directly into the node as an extra safety net. If you still see a pod stuck in `ImagePullBackOff` after `install.sh`, check:

```bash
kubectl describe pod -n <namespace> <pod-name>
```

If the error mentions a DNS `i/o timeout`, pull the named image on the host and import it manually:

```bash
docker pull --platform linux/amd64 <image>
docker save <image> -o /tmp/preload.tar
docker exec -i local-control-plane ctr --namespace=k8s.io images import \
  --platform linux/amd64 --digests --snapshotter=overlayfs - < /tmp/preload.tar
kubectl delete pod -n <namespace> <pod-name>
```

### Instructor

Frank P Moley III

Principal Software Architect at Vertex, Inc.
        

Check out my other courses on [LinkedIn Learning](https://www.linkedin.com/learning/instructors/frank-p-moley-iii?u=104).

[0]: # (Replace these placeholder URLs with actual course URLs)

[lil-course-url]: https://www.linkedin.com/learning/spring-on-kubernetes-deploying-and-managing-cloud-native-applications
[lil-thumbnail-url]: https://media.licdn.com/dms/image/v2/D4E0DAQGbScwnzErsnw/learning-public-crop_675_1200/learning-public-crop_675_1200/0/1726684715855?e=2147483647&v=beta&t=6m5UmFBAPLHndQQE3unqON2AfzkgHsLw4QWHxRVOhfc
[github-repo-url]: https://github.com/LinkedInLearning/spring-on-kubernetes-deploying-and-managing-cloud-native-applications-5913242
