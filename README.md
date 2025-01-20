# Cronos-POS Helm + GitOps Deployment

### - Configuration

- dir: `/cronos-pos-container`

  Contain the `Dockerfile` and scripts needed to launch Cronos-POS nodes in STATE-SYNC mode with configurable block heights (using CUSTOM_HEIGHT env var).
  There's two helper scripts:
  - `cronospos-init-mainnet.sh` --> Help init volume data and configuration with moniker-id, only run once on init container when node is starting from stract.
  - `cronospos-enable-statesync.sh` --> enable various configuration to app.toml & config.toml, mainly to setup the STATE-SYNC configuration.


- dir: `/cronos-pos-k8s-template`:

  Stores Kubernetes deployment templates for Cronos-POS observer nodes, utilizing kustomize (https://kustomize.io/) for manifest management and patching.


- dir: `/k8s-cluster-addons`:

  Provides supplementary configurations and add-ons for the Kubernetes environment including monitoring, ArgoCD, and ingress setup.

- dir: `/workspace-gitops-deploy`:

  Derves as the GitOps deployment workspace containing individual Cronos-POS node configurations, with `example-cronos-pos-node-1` provided as a reference implementation.

- **Log file (Cronos-POS node)**

  Live log are available at https://grafana.cronos.heronimus.id/public-dashboards/b3b7220e5fa84b06b8a66ec716b3ef78?orgId=1



---
### - Tech-Stack in Use

![architecture](_assets/architecture-design.png)

---

### - Tests Run

![argocd-1](_assets/argocd-1.png)

![argocd-2](_assets/argocd-2.png)

- **ArgoCD Dashboard** (Guest Access): https://argocd.cronos.heronimus.id/applications?namespace=cronos-pos

- **Cronos-POS** Synced-Node (Running on my local but proxied through my K8S cluster)
  - RPC: https://rpc-local-mac.cronos.heronimus.id/
  - Rest API: https://rest-local-mac.cronos.heronimus.id/
  - GRPC: grpc-local-mac.grpc-cronos.heronimus.id:443

- **Cronos-POS** Not-synced-Node (Running on my K8S cluster, but due to resource limitation, it can't sync to the latest block)
  - RPC: https://rpc-example-cronos-pos-node-1.cronos.heronimus.id/
  - Rest API: https://rest-example-cronos-pos-node-1.cronos.heronimus.id/
  - GRPC: grpc-example-cronos-pos-node-1.grpc-cronos.heronimus.id:443

- Node Log: https://grafana.cronos.heronimus.id/public-dashboards/b3b7220e5fa84b06b8a66ec716b3ef78?orgId=1

![grafana-log](_assets/grafana-log.png)


---

### - Operational FAQ

- Query Balance of wallet address

  Get Balance query can be done using a query to the Cosmos Bank Module using multiple endpoint available.

  - **Rest/Cosmos API (1317)**
  Query
  ```
  curl -X GET \
    https://rest-local-mac.cronos.heronimus.id/cosmos/bank/v1beta1/balances/cro1hsr2z6lr7k2szjktzjst46rr9cfavprqas20gc \
    -H 'Content-Type: application/json'
  ```
  Response: balance = 182513776 basecro
  ```
  {
    "balances": [
      {
        "denom": "basecro",
        "amount": "182513776"
      }
    ],
    "pagination": {
      "next_key": null,
      "total": "1"
    }
  }
  ```

  - **GRPC (9090)**
  Query
  ```
  grpcurl -plaintext \
      -d '{"address":"cro1hsr2z6lr7k2szjktzjst46rr9cfavprqas20gc"}' \
      localhost:9090 \
      cosmos.bank.v1beta1.Query/AllBalances
  ```
  Response
  ```
  {
    "balances": [
      {
        "denom": "basecro",
        "amount": "182513776"
      }
    ],
    "pagination": {
      "total": "1"
    }
  }
  ```

- Block Information Query

  Get block hash for block `13947398`.

  Query
  ```
  curl -s "https://rpc.mainnet.cronos-pos.org:443/block?height=13947398" | jq -r .result.block_id.hash
  ```

  Response Block Hash
  ```
  6665D5883A7F029B37AE37D8ACDCC5B7BE6982018BB9280814A826CE2D494DDA
  ```
