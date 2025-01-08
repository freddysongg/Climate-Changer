# Climate Changer Project

This project processes and analyzes climate data using an R script. It leverages Docker and Kubernetes for containerized deployment and scalability.

---

## Overview

The Climate Changer project automates climate data processing and analysis with the following key components:

- **R Script**: Processes climate data and outputs clean datasets.
- **Docker**: Containerizes the application for portability.
- **Kubernetes**: Manages application deployment, scaling, and orchestration.

---

## Objectives

- Simplify climate data analysis.
- Ensure scalability and portability using modern containerization and orchestration technologies.
- Enable seamless integration and deployment for users.

---

## Features

- Data processing via an R script.
- Containerized deployment using Docker.
- Scalable deployment with Kubernetes.
- Persistent data storage and easy access to processed results.

---

## Usage Instructions

### 1. **Build and Start Your Docker Image**

Build and start the Docker image to ensure the application works locally:

```bash
docker compose up --build
```

This will:
- Build the `climate-analyzer:latest` image.
- Start a container locally to confirm the application works as expected.

### 2. **Load the Image into Kubernetes**

After confirming the image works locally, load it into the Kubernetes cluster:

1. **Save the Image**:
   ```bash
   docker save climate-analyzer:latest -o climate-analyzer.tar
   ```

2. **Copy the Image to the Kubernetes Node**:
   ```bash
   docker cp climate-analyzer.tar climate-cluster-control-plane:/climate-analyzer.tar
   ```

3. **SSH into the Node**:
   ```bash
   docker exec -it climate-cluster-control-plane bash
   ```

4. **Load the Image into the Node's Container Runtime**:
   ```bash
   ctr --namespace k8s.io images import /climate-analyzer.tar
   ```

5. **Exit the Node**:
   ```bash
   exit
   ```

### 3. **Reapply the Deployment**

Reapply the deployment to ensure the latest image is used:

1. **Delete the Old Pods**:
   ```bash
   kubectl delete pod -l app=climate-analyzer
   ```

2. **Reapply the Deployment**:
   ```bash
   kubectl apply -f deployment.yaml
   ```

### 4. **Verify Pod Status**

Check the status of the pods to confirm the application is running:

```bash
kubectl get pods
```

### 5. **Access Processed Data**

The processed climate data is saved in the `data/` directory inside the container. To extract the data:

1. **Identify the Running Pod**:
   ```bash
   kubectl get pods
   ```

2. **Access the Pod**:
   ```bash
   kubectl exec -it <pod-name> -- bash
   ```

3. **Navigate to the Data Directory**:
   ```bash
   cd /app/data
   ```

4. **Copy Data to Your Local Machine**:
   ```bash
   kubectl cp <pod-name>:/app/data ./data
   ```

---

## Directory Structure

```plaintext
Climate-Changer/
├── data/                      # Data folder (mapped to container's /app/data)
├── Dockerfile                 # Docker build file
├── deployment.yaml            # Kubernetes deployment configuration
├── compose.yaml               # Docker Compose file
├── data_analysis.R            # R script for data analysis
├── README.md                  # Project documentation
```

---

## Additional Notes

### Error Handling
- Ensure all required R libraries are installed in the Docker image if the application fails to start.
- Debug errors by viewing the logs:
  ```bash
  kubectl logs <pod-name>
  ```

### Scaling the Application
- To scale the application, update the `replicas` field in the `deployment.yaml` file:
  ```yaml
  replicas: <desired-number-of-replicas>
  ```

### Environment Variables
- Add necessary environment variables in `deployment.yaml` to configure the application dynamically.

### Persistent Storage
- Mount a persistent volume in Kubernetes to store processed data long-term.

---

## Contributing

We welcome contributions to improve the project!  
- Open an issue for suggestions or bug reports.  
- Create a pull request for any improvements or features you'd like to propose.  

Feel free to reach out with any questions or feedback!