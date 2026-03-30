
# AWS Infrastructure with Terraform & Jenkins

This project provisions a scalable and secure AWS infrastructure using **Terraform (module-based approach)** and sets up a **Jenkins CI/CD pipeline** running in Docker.

The infrastructure is deployed in the **us-east-1 region** across two Availability Zones:
- us-east-1a  
- us-east-1b 

## Architecture Diagram
<img width="1607" height="1198" alt="diagram-export-3-30-2026-10_56_08-AM" src="https://github.com/user-attachments/assets/42e21b0c-1687-4c08-8538-b86f8345ec03" />


---

## Infrastructure Components

### Networking
- 1 VPC for resource isolation
- 2 Public Subnets (across 2 AZs)
- 1 Private Subnet
- Internet Gateway (IGW) for public internet access
- NAT Gateway (in public subnet) for private subnet outbound access
- Route Tables:
  - Public route → IGW
  - Private route → NAT Gateway

---

### Load Balancing
- Internet-facing Application Load Balancer (ALB)
- Deployed across:
  - us-east-1a
  - us-east-1b
- Distributes incoming traffic

---

### Compute Layer
- **Bastion Host (Public Subnet)**
  - Used for secure SSH access to private resources

- **Jenkins Server (Private Subnet)**
  - No direct internet exposure
  - Accessible via Bastion Host
  - Runs inside Docker container

---

### Security
Security Groups attached to:
- ALB
- Bastion Host
- Jenkins Server

Controls:
- HTTP/HTTPS access to ALB
- SSH access via Bastion only
- Internal communication restrictions

---

## Terraform Implementation

This project uses a **modular Terraform architecture**:

### 📦 Modules
- **VPC Module** → VPC, subnets, IGW, NAT, route tables
- **EC2 Module** → Bastion & Jenkins instances
- **ELB Module** → Application Load Balancer
- **IAM Module** → Roles and permissions

### Benefits
- Reusable components
- Clean structure
- Easy scalability
- Consistent deployments

---

## Jenkins Setup

- Jenkins is deployed using a **Docker container**
- Hosted on EC2 inside private subnet

### Configuration
- **Jenkins Configuration as Code (JCasc)** used for:
  - Secrets management
  - Jenkins configuration
  - Seed job setup

---

## CI/CD Pipeline

### Shared Pipeline Concept
- Jenkins pipelines implemented using **Shared Libraries**
- Benefits:
  - Reusability
  - Standardization
  - Reduced duplication

---

## End-to-End Flow

1. **Infrastructure Provisioning**
   - Terraform creates:
     - VPC, subnets, IGW, NAT
     - Route tables
     - EC2 instances (Bastion + Jenkins)
     - ALB and security groups

2. **Networking Setup**
   - Public subnets → Internet via IGW
   - Private subnet → Internet via NAT Gateway

3. **Access Flow**
   - User connects to Bastion Host via SSH
   - Bastion connects to Jenkins server in private subnet

4. **Application Access**
   - External users access via ALB
   - ALB distributes traffic to backend

5. **Jenkins Initialization**
   - Jenkins runs inside Docker
   - CASC configures:
     - Credentials
     - Pipelines
     - Plugins

6. **Pipeline Execution**
   - Shared libraries provide reusable pipeline logic
   - Seed pipeline auto-creates jobs

---

## Tools & Technologies

- Terraform (Infrastructure as Code)
- AWS (Cloud Platform)
- Docker (Containerization)
- Jenkins (CI/CD)
- CASC (Configuration as Code)
