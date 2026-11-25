# ShopLite – Multi-Service Application with AWS & CI/CD

**ShopLite** is a containerized online shopping application developed to demonstrate microservices architecture, Docker networking, AWS cloud deployment, and automated CI/CD.

The project includes four application services and a PostgreSQL database, deployed on AWS EC2 with Docker and automated through GitHub Actions.

## Project Architecture

ShopLite consists of:

- **Frontend:** React application served through Nginx.
- **Catalog Service:** Node.js service for product management.
- **Inventory Service:** Go service for inventory management.
- **Order Service:** Java service for order processing.
- **Database:** PostgreSQL for persistent application data.

## Technology Stack

| Category | Technologies |
|---|---|
| Application | React, Node.js, Go, Java |
| Database | PostgreSQL |
| Containerization | Docker |
| Networking | Docker Bridge Networks |
| Cloud Platform | AWS EC2 |
| Container Registry | Amazon ECR |
| Web Server & Reverse Proxy | Nginx |
| SSL/TLS | Let's Encrypt, Certbot |
| CI/CD | GitHub Actions |
| Remote Deployment | SSH |
| Operating System | Ubuntu Linux |

## Infrastructure & Networking

- Containerized all four application services and PostgreSQL.
- Created dedicated Docker networks for frontend and backend communication.
- Configured an isolated internal backend network to restrict external access to backend services.
- Used persistent Docker volumes for PostgreSQL data.
- Configured Nginx as a reverse proxy with HTTPS.
- Hosted the application on AWS EC2.

## CI/CD Pipeline

Implemented an automated CI/CD workflow using GitHub Actions.

**Continuous Integration (CI):**

1. Triggered by code pushes to the `main` branch.
2. Builds Docker images for all four application services.
3. Tags images with the release version and Git commit SHA.
4. Pushes images to Amazon ECR.

**Continuous Deployment (CD):**

1. Establishes an SSH connection to the EC2 instance.
2. Executes the deployment script.
3. Pulls updated images from Amazon ECR.
4. Recreates application containers.
5. Preserves PostgreSQL data through persistent storage.

## Team

- **Team Lead:** Awais
- **Team Member:** Barkatullah Khan

## Project Outcomes

- Successfully deployed a multi-service shopping application.
- Implemented isolated container networking.
- Configured AWS cloud infrastructure and container image management.
- Enabled HTTPS for the hosted application.
- Implemented and tested automated CI/CD using GitHub Actions and SSH.

## Learning & Experience

This project provided practical experience in Linux administration, Docker, container networking, AWS infrastructure, cloud deployment, reverse proxy configuration, and CI/CD automation.

---

**Project:** ShopLite

**Repository:** [shoplite-devops](https://github.com/barkatullah-khan/shoplite-devops)