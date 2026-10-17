# DevOps Capstone Project Report: End-to-End Cloud-Native Deployment of a Multi-Service Voting Application

## 1. Executive Summary & Project Objectives

This capstone project implements a production-grade microservice architecture deployed onto a cloud-managed Kubernetes cluster, adhering to modern DevOps principles including containerization, automated infrastructure provisioning, continuous integration, and high-availability deployment strategies.

### **Project Goals**

* Automate cloud infrastructure provisioning using **Terraform**.
* Implement a secure CI/CD pipeline with **GitHub Actions** and vulnerability scanning via **Trivy**.
* Orchestrate and deploy a 5-service containerized application onto **AWS EKS**.
* Validate zero-downtime rolling updates and instant fault recovery rollbacks.

## 2. System Architecture & Tech Stack

### **Core Microservices (`example-voting-app`)**

* **Vote (`vote`):** A Python (Flask) front-end application allowing users to submit votes between competing options.
* **Result (`result`):** A Node.js web application displaying real-time voting results fetched from the database.
* **Worker (`worker`):** A background worker service (.NET/C#) consuming queued votes from Redis and persisting them into PostgreSQL.
* **Redis (`redis`):** An in-memory data store acting as a message queue between the voting front-end and the worker service.
* **PostgreSQL (`db`):** A relational database serving as persistent storage for aggregated voting results.

### **DevOps & Cloud Tooling Stack**

* **OS & Environment:** Ubuntu Linux on WSL2.
* **Containerization:** Docker & Docker Compose.
* **Infrastructure as Code (IaC):** Terraform.
* **Cloud Provider:** Amazon Web Services (AWS) EKS (Elastic Kubernetes Service) with managed EC2 worker nodes (`t3.small`) in `us-east-1`.
* **CI/CD & Security:** GitHub Actions workflows and Trivy security scanner.
* **Orchestration:** Kubernetes (`kubectl`) with NodePort networking and rolling updates.

## 3. Infrastructure as Code (IaC) with Terraform

The cloud infrastructure is provisioned entirely through Terraform to ensure reproducibility, version control, and automated lifecycle management.

### **Provisioning Strategy & Configuration**

* **Provider & Region:** Configured for AWS (`hashicorp/aws`) in `us-east-1`.
* **Cluster Control Plane:** Provisioned using the official Terraform EKS module (`terraform-aws-modules/eks/aws`), running Kubernetes version **1.31**.
* **Worker Node Groups:** EKS Managed Node Groups configured with `t3.small` instances (2 vCPUs, 2GB RAM), maintaining a scalable cluster size (2 to 3 nodes).
* **Networking & Security:** Integrates with AWS VPCs, subnets, and security groups with least-privilege IAM permissions.

### **Infrastructure Lifecycle Commands**

1. `terraform init`: Initializes providers and modules.
2. `terraform plan`: Generates and reviews the execution plan.
3. `terraform apply`: Provisions the EKS control plane and worker nodes.
4. `terraform destroy`: Gracefully tears down all cloud resources to optimize resource utilization when testing is complete.

## 4. Automated CI/CD Pipeline & Security Scanning

To maintain software quality and prevent insecure code from reaching production, the project implements a robust CI/CD pipeline using **GitHub Actions**.

### **Pipeline Workflow & Stages**

The pipeline triggers automatically on pushes or pull requests to the `main` branch, utilizing a matrix strategy for `vote`, `result`, and `worker`:

1. **Code Checkout & Setup:** Pulls repository code and configures **Docker Buildx**.
2. **Local Build & Test:** Compiles container images within the GitHub Actions runner environment.
3. **Automated Vulnerability Scanning (Trivy):**
   * Each built image is scanned using `aquasecurity/trivy-action`.
   * Inspects container layers for CVEs, filtering by `CRITICAL` and `HIGH` severity.
4. **Registry Authentication & Push:**
   * Authenticates securely with **Docker Hub** using encrypted repository secrets (`DOCKER_HUB_USERNAME` and `DOCKER_HUB_ACCESS_TOKEN`).
   * Images are tagged with the unique **Git commit SHA** (`${{ github.sha }}`) and `latest`.

## 5. Kubernetes Deployment & Networking

### **Manifest Architecture & Workloads**

* **Deployments (`apps/v1`):** Manages pod lifecycles, replica counts, and container image references pointing directly to Docker Hub.
* **Services (`v1`):**
  * **ClusterIP Services:** Internal communication for backend services (`db`, `redis`).
  * **NodePort Services:** Exposes frontend applications (`vote` on port `31000`, `result` on port `31001`).

### **Cluster Management & Access**

* **Credential Configuration:** Cluster access managed via AWS CLI (`aws eks update-kubeconfig`).
* **Testing & Port Forwarding:** Verified using `kubectl port-forward` tunnels for real-time browser testing of vote submissions and database persistence.

## 6. Challenges Encountered & Troubleshooting

During the deployment, validation, and testing phases of the project, several technical challenges arose and were systematically resolved:

* **Port Mapping & `targetPort` Mismatch:** 
  * *Issue:* Initial deployment attempts encountered service routing errors (`Service vote does not have a service port 80`) because the container deployment configuration specified `containerPort: 80`, while mismatched service ports caused connection drops.
  * *Resolution:* Inspected the deployment manifests, aligned the container port settings (`containerPort: 80`), and updated the corresponding Service manifest `targetPort` and `port` parameters to ensure seamless traffic routing between pods and services.
* **Local Port Binding Conflicts (`Address Already in Use`):**
  * *Issue:* While setting up `kubectl port-forward svc/vote 8080:80`, execution failed with `address already in use` errors due to leftover background listeners or local processes occupying port `8080`.
  * *Resolution:* Dynamically mapped tunnels to alternative local development ports (e.g., `8090`) or terminated lingering listener processes using process ID lookups (`sudo lsof -i :8080`).
* **Handling Image Pull Failures During Rollout Testing:**
  * *Issue:* Simulating a bad deployment with an intentional non-existent tag (`broken-tag-123`) triggered an `ImagePullBackOff` state during rolling updates.
  * *Resolution:* Verified that Kubernetes successfully isolated the fault by retaining the healthy previous replica to serve traffic without downtime, then executed `kubectl rollout undo` to instantly revert the deployment to its stable state.

## 7. Zero-Downtime Rolling Updates & Rollback Validation

### **Zero-Downtime Rolling Updates**

* **Execution Strategy:** Kubernetes manages pod replacements incrementally (`maxSurge` and `maxUnavailable`), ensuring stable pods continue serving user traffic.
* **Validation:** Tracked in real time using `kubectl rollout status` to verify smooth transitions.

### **Rollback Verification & Fault Recovery**

* **Failure Simulation:** Faulty image tags (e.g., non-existent versions triggering `ImagePullBackOff`) are deployed to test disaster recovery. Kubernetes halts the rollout while preserving existing running replicas.
* **Instant Reversion:** Using `kubectl rollout undo deployment/vote`, the cluster immediately reverts to the previous stable revision.
* **Revision History Tracking:** Audited using `kubectl rollout history` for complete configuration traceability.

## 8. Conclusion & Key Takeaways

This capstone project successfully demonstrates an end-to-end cloud-native DevOps workflow, transitioning a multi-service containerized application from local development to a fully provisioned production-grade Kubernetes environment on AWS.

### **Key Achievements**

* **Infrastructure as Code:** Automated EKS provisioning and destruction via Terraform.
* **Secure CI/CD:** Automated GitHub Actions builds, Trivy security scans, and immutable image tagging.
* **High Availability & Resilience:** Deployed 5 microservices onto Kubernetes with container-port mappings, service networking, and verified zero-downtime rolling updates and rollbacks.