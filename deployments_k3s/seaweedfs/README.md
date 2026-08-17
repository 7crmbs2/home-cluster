# SeaweedFS

Distributed, S3-compatible object storage for the k3s cluster, deployed via
the official [SeaweedFS Helm chart](https://github.com/seaweedfs/seaweedfs/tree/master/k8s/charts/seaweedfs)
(`seaweedfs/seaweedfs`, from `https://seaweedfs.github.io/seaweedfs/helm`).

## What gets deployed

| Component | Role | Exposed publicly? |
|---|---|---|
| `master` (StatefulSet) | Cluster coordination, volume assignment | No — ClusterIP only |
| `volume` (StatefulSet) | Actual blob storage | No — ClusterIP only |
| `filer` (StatefulSet) | Metadata / namespace layer | No — ClusterIP only |
| `filer` → embedded S3 gateway | S3-compatible API (port `8333`) | **Yes — via Traefik Ingress** |
| `admin` UI | Web dashboard, bucket browser, cluster metrics | No — ClusterIP only, port-forward only |
| `worker` | Maintenance jobs (vacuum, balance, EC) | Disabled (single node doesn't need it yet) |

Only **one** endpoint leaves the cluster: the S3 gateway on the filer
(`filer.s3.ingress`, port `8333`), fronted by Traefik at `s3.example.com`.
Everything else stays internal — master (`9333`), volume (`8080`), filer's
own HTTP/WebDAV API (`8888`), and the admin UI (`23646`) are all ClusterIP
only and must never be reachable from the internet.

### Accessing the admin UI

Port-forward to the admin service and open it in your browser:

```bash
kubectl -n seaweedfs port-forward svc/seaweedfs-admin 23646:23646
```

Then visit `http://localhost:23646`. Log in with the credentials set under
`seaweedfs.admin.secret` in `values.yaml` (default: `admin` /
`CHANGEME_ADMIN_PASSWORD` — rotate this in ArgoCD before going to
production).

The admin UI lets you browse buckets, inspect volume health, and trigger
maintenance tasks without needing `weed shell`. The filer's own HTTP/WebDAV
browser is on a separate port if you ever need it:

```bash
kubectl -n seaweedfs port-forward svc/seaweedfs-filer 8888:8888
```

## Prerequisites

- A default `StorageClass`
- Traefik as your ingress controller (default in k3s) with an
  `IngressClass` named `traefik`.
- `cert-manager` with a `ClusterIssuer` (the example uses
  `letsencrypt-prod`) — or drop the `cert-manager.io/cluster-issuer`
  annotation and the `tls` block if you terminate TLS elsewhere.
- Public DNS record for `s3.crmbs.net` pointed at your Traefik
  LoadBalancer/entrypoint.

## Credentials

### S3 bootstrap secret

`templates/seaweedfs-s3-secret.yaml` is bundled in this chart and deploys
the `seaweedfs-s3-secret` Secret automatically on install. It ships with
placeholder values:

| Field | Default |
|---|---|
| S3 access key | `CHANGEME_ACCESS_KEY` |
| S3 secret key | `CHANGEME_SECRET_KEY` |
| Admin UI password | `CHANGEME_ADMIN_PASSWORD` (under `seaweedfs.admin.secret.adminPassword`) |

**Before going to production**, override all three via ArgoCD. The
recommended approach is an ArgoCD `Secret` override or a Sealed Secret —
whichever secret management pattern you already use in the cluster. The
placeholders are intentionally obvious so nothing silently ships with weak
credentials.

Quick way to generate values to paste into ArgoCD:

```bash
echo "Access key:    $(openssl rand -hex 16)"
echo "Secret key:    $(openssl rand -hex 32)"
echo "Admin password: $(openssl rand -hex 24)"
```

## Install

```bash
helm dependency update ./seaweedfs
helm install seaweedfs ./seaweedfs -n seaweedfs --create-namespace -f ./seaweedfs/values.yaml
```

Check it came up:

```bash
kubectl -n seaweedfs get pods,pvc,ingress
```

You should see `seaweedfs-master-0`, `seaweedfs-volume-0`, and
`seaweedfs-filer-0` running, and an Ingress for `s3.example.com`.

## Creating a new bucket + scoped permissions

Don't hand every app the admin key — create a bucket and an identity that
can only touch that bucket. The cleanest way is `weed shell`, run against
the filer, which applies changes live (no pod restart needed):

```bash
kubectl -n seaweedfs exec -it seaweedfs-filer-0 -- weed shell
```

Inside the shell:

```
> s3.bucket.create -name myapp-bucket

> s3.configure -user=myapp \
    -access_key=<generate-a-new-key> \
    -secret_key=<generate-a-new-secret> \
    -buckets=myapp-bucket \
    -actions=Read,Write,List,Tagging \
    -apply
```

This writes a scoped identity like:

```json
{
  "name": "myapp",
  "credentials": [{ "accessKey": "...", "secretKey": "..." }],
  "actions": ["Read:myapp-bucket", "Write:myapp-bucket", "List:myapp-bucket", "Tagging:myapp-bucket"]
}
```

The `:myapp-bucket` suffix is what scopes each action to that bucket only
— `myapp` will get `AccessDenied` on any other bucket. Leave off `Admin`
unless the app genuinely needs to create/delete buckets itself.

Repeat `s3.configure` per app/bucket. To review current identities:

```
> s3.configure
```

Exit the shell with `exit` or Ctrl-D.

### Verify from outside the cluster

With the AWS CLI (path-style, since we didn't set `domainName`):

```bash
aws configure set aws_access_key_id <access_key>
aws configure set aws_secret_access_key <secret_key>

aws --endpoint-url https://s3.example.com s3 ls
aws --endpoint-url https://s3.example.com s3 mb s3://myapp-bucket
aws --endpoint-url https://s3.example.com s3 cp ./somefile.txt s3://myapp-bucket/
```

Or with the `mc` (MinIO client), which many people find nicer for
day-to-day bucket poking:

```bash
mc alias set seaweed https://s3.example.com <access_key> <secret_key>
mc ls seaweed
mc mb seaweed/myapp-bucket
```

## Notes

- **Uploads and Traefik**: Traefik has no default request-body size limit,
  so large S3 uploads work out of the box. If you've globally tightened
  limits via a Middleware, make sure the S3 IngressRoute is excluded or
  given a higher limit.
- **Backups**: this is a single master/single volume/single filer setup —
  fine for a homelab, but there's no redundancy. For real durability, bump
  `master.replicas` and `filer.replicas` to 3 (odd numbers, Raft quorum)
  and give volume more replicas with `-replication` set on your buckets,
  or look at SeaweedFS's async backup-to-cloud features.
- **Changing credentials later**: prefer `weed shell` (`s3.configure`) over
  editing the `seaweedfs-s3-secret` directly — shell changes apply live;
  secret edits require restarting the filer pod to pick up the new
  static config.
- **Rotate the CHANGEME values**: before the cluster is network-reachable,
  replace `CHANGEME_ACCESS_KEY`, `CHANGEME_SECRET_KEY`, and
  `CHANGEME_ADMIN_PASSWORD` via your ArgoCD secret management. The admin UI
  is only port-forward accessible so it's not exposed, but the S3 endpoint
  is public and weak credentials on it are a real risk.
