```markdown
# 🚀 Garage S3 Agent Guide (Advanced)
**Goal**: Create a secure bucket for remote access via S3 API using your `garage.yaml` config

---

## 📁 1. Locate `garage.toml` from ConfigMap
The `garage.toml` is stored in a Kubernetes ConfigMap named `garage-config` (from your YAML). Extract it:
```bash
kubectl -n garage get cm garage-config -o jsonpath='{.data.garage\.toml}'
```
**Expected Output** (example):
```toml
[s3_api]
api_bind_addr = "[::]:3900"
root_domain = ".s3.crmbs.net"
```
**Note**: Use the `root_domain` (`.s3.crmbs.net`) as your public S3 endpoint.

---

## 🛠 2. Access Garage CLI via Kubernetes API
**No `/bin/sh` in container** — use **port-forwarding** and **AWS CLI**/**Rclone**. 

### ✅ Step 1: Port-Forward S3 API
Forward the S3 API port (3900) to your local machine:
```bash
kubectl -n garage port-forward svc/garage-s3 3900:3900
```
**Verify**:
```bash
curl -v https://localhost:3900
```
You should get a `404` (normal — Garage is a minimal API).

---

## 📦 3. Create a Bucket for Your Brother
### 📁 Step 1: Use AWS CLI
Install AWS CLI and configure a profile:
```bash
aws configure set region garage
aws configure set endpoint_url https://localhost:3900
aws configure set s3 endpoint_url https://localhost:3900
```
Create the bucket:
```bash
aws s3api create-bucket --bucket colleague-backups
```

### 🛠 Step 2: Grant Permissions (Least Privilege)
Create a policy file `policy.json`:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::colleague-backups/*"]
    }
  ]
}
```
Apply the policy:
```bash
aws s3api put-bucket-policy --bucket colleague-backups --policy file://policy.json
```

---

## 🧱 4. Configure Your Brother’s Client
Provide him with this config:
```
S3 Endpoint:      https://s3.crmbs.net
Region:           garage
Access Key ID:    YOUR_ACCESS_KEY
Secret Access Key: YOUR_SECRET_KEY
Bucket Name:      colleague-backups
```
**Note**: Replace `YOUR_ACCESS_KEY` and `YOUR_SECRET_KEY` with the keys you’ll generate next.

---

## 🧾 5. Generate Access Key for Your Brother
Use the **Garage API** (via port-forwarding):
```bash
curl -X POST https://localhost:3900/api/v1/key \
  -H "Content-Type: application/json" \
  -d '{"name": "colleague-backup-key"}'
```
**Response**:
```json
{"access_key_id": "GKXXXXXXXXXXXXXXXX", "secret_access_key": "xxxxxxxxxxxxxxxxxxxxxxxx"}
```
**Save both keys securely** — the secret key is shown only once.

---

## 🔍 6. Verify Permissions
Check bucket permissions:
```bash
aws s3api get-bucket-policy --bucket colleague-backups
```
Ensure the policy grants only the necessary permissions.

---

## ⚠️ Critical Notes
1. **Single-Node Setup**:
   - Your `replicationFactor: "1"` is correct for a single-node setup.
   - Ensure `replicaCount: 2` in `deployment.yaml` is adjusted to `1` if you’re using a single node.

2. **DNS Configuration**:
   - Ensure `s3.crmbs.net` and `*.s3.crmbs.net` resolve to your cluster IP.
   - Use `nslookup` or `dig` to verify DNS:
     ```bash
     nslookup s3.crmbs.net
     ```

3. **Layout Initialization**:
   If you see `Layout not ready`, initialize the cluster:
   ```bash
   kubectl -n garage exec -it garage-0 -- ./garage layout assign -z dc1 -c 1T <node-id>
   ```
   Replace `<node-id>` with the ID from `kubectl -n garage get pods`.

4. **Monitoring**:
The `monitoring.metrics.enabled: true` config will automatically create a Prometheus ServiceMonitor for Garage metrics.

---

## 📌 Summary
| Task                | Method                          |
|---------------------|---------------------------------|
| CLI Access          | Port-forward + AWS CLI/Rclone   |
| Bucket Creation     | AWS CLI                        |
| Permissions         | S3 Policy Files                |
| Troubleshoot        | Check ConfigMaps, DNS, Layout  |
```