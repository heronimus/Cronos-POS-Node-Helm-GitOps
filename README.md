# crypto-com-devops-challenge

By: Heronimus Adie (adie@heronimus.id)

## Q1: Blockchain Installation Setup

### - Key Assumptions

The observer node implementation in my case will us a STATE-SYNC node configuration rather than a full validator node for the following reasons:
- Running a complete Full-Node requires significant computational resources
- STATE-SYNC provides near-the-head pruned data, which is sufficient for most API query needs


### - Tech-Stack Design Selection

![architecture](_assets/architecture-design.png)

The implementation follows a GitOps workflow pattern utilizing ArgoCD and Kubernetes:

- Users commit deployment changes to the Git repository
- Changes are organized in workspace deployments (e.g., cronos-pos-deploy-1, cronos-pos-deploy-2) in git repository
- ArgoCD automatically synchronizes these changes to the Kubernetes cluster

#### Kubernetes as Container Orchestrator
Advantages:
- Battle-tested platform with proven reliability in production
- Support scalability for growing workloads
- Cloud-agnostic architecture enabling multi-cloud and bare-metal deployments

#### GitOps Workflow with ArgoCD
Advantages:
- Declarative configuration management ensuring infrastructure as code
- Automated synchronization between Git repository and cluster state
- Clear audit trail and version control for all deployments
- Simplified rollback capabilities through Git history
- Enhanced collaboration through pull request workflows

#### Implementation Challenges
- Requires strong/comprehensive engineering expertise in Kubernetes architecture
- Initial setup complexity for proper proper maintainability and observability


### - Configuration/Deliverables

- `/cronos-pos-container`: houses the `Dockerfile` and scripts needed to launch Cronos-POS nodes in STATE-SYNC mode with configurable block heights (using CUSTOM_HEIGHT env var).

- `/cronos-pos-k8s-template`: stores Kubernetes deployment templates for Cronos-POS observer nodes, utilizing kustomize (https://kustomize.io/) for manifest management and patching.

- `/k8s-cluster-addons`: provides supplementary configurations and add-ons for the Kubernetes environment including monitoring, ArgoCD, and ingress setup.

- `/workspace-gitops-deploy`: serves as the GitOps deployment workspace containing individual Cronos-POS node configurations, with `example-cronos-pos-node-1` provided as a reference implementation.

- **Log file (Cronos-POS node)**: Live log are available at https://grafana.cronos.heronimus.id/public-dashboards/b3b7220e5fa84b06b8a66ec716b3ef78?orgId=1

### - Testing and HandsOn

![argocd-1](_assets/argocd-1.png)

- ArgoCD: https://argocd.cronos.heronimus.id/applications?namespace=cronos-pos

![argocd-2](_assets/argocd-2.png)

- Synced-Node (Running on my local but proxied through my K8S cluster)
  - RPC: https://rpc-local-mac.cronos.heronimus.id/
  - Rest API: https://rest-local-mac.cronos.heronimus.id/
  - GRPC: grpc-local-mac.grpc-cronos.heronimus.id:443

- Not-synced-Node (Running on my K8S cluster, but due to resource limitation, it can't sync to the latest block)
  - RPC: https://rpc-example-cronos-pos-node-1.cronos.heronimus.id/
  - Rest API: https://rest-example-cronos-pos-node-1.cronos.heronimus.id/
  - GRPC: grpc-example-cronos-pos-node-1.grpc-cronos.heronimus.id:443

- Node Log: https://grafana.cronos.heronimus.id/public-dashboards/b3b7220e5fa84b06b8a66ec716b3ef78?orgId=1

![grafana-log](_assets/grafana-log.png)

### - Questions

- What is the amount of balance address `cro1hsr2z6lr7k2szjktzjst46rr9cfavprqas20gc` has?

  Get Balance query can be done using a query to the Cosmos Bank Module using multiple endpoint available/
  - Rest API (1317)
  Query
  ```
  curl -X GET \
    https://rest-local-mac.cronos.heronimus.id/cosmos/bank/v1beta1/balances/cro1hsr2z6lr7k2szjktzjst46rr9cfavprqas20gc \
    -H 'Content-Type: application/json'
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
      "next_key": null,
      "total": "1"
    }
  }
  ```

  - GRPC (9090)
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

- What is the block hash for `13947398` information?

  Because I run the observer node using state-sync at higher trusted height so I can't query earlier block. I'll use the public RPC endpoint instead to get block hash for block `13947398`.

  Query
  ```
  curl -s "https://rpc.mainnet.cronos-pos.org:443/block?height=13947398" | jq -r .result.block_id.hash
  ```

  Response
  ```
  6665D5883A7F029B37AE37D8ACDCC5B7BE6982018BB9280814A826CE2D494DDA
  ```

----
Q2: HTTP Server
