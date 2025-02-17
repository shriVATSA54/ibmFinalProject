pipeline {
    agent any
    stages {
        stage('Setup') {
            steps {
    
                bat "pip install -r requirements.txt"
            }
        }
        
        stage('Test') {
            steps {
                bat "pytest"
            }
        }
        stage('Start Minikube') {
            steps {
                bat 'minikube start'
            }
        }
stage('Build Docker Image') {
            steps {
                script {
                    // Build Docker image
                    bat "docker build -t flask-app:latest ."
                    echo "Docker image built successfully"
                    bat 'docker images'
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                echo "Push image to Docker"
                withCredentials([usernamePassword(credentialsId: 'DockerHubCreds', passwordVariable: 'dockerHubPass', usernameVariable: 'dockerHubUser')]) {
                    script {
                        try {
                            // Log into DockerHub
                            bat "docker login -u ${env.dockerHubUser} -p ${env.dockerHubPass}"
                            // Tag the Docker image
                            bat "docker image tag flask-app:latest ${env.dockerHubUser}/flask-app:latest"
                            // Push the Docker image to DockerHub
                            bat "docker push ${env.dockerHubUser}/flask-app:latest"
                        } catch (Exception e) {
                            error "Docker push failed: ${e.getMessage()}"
                        }
                    }
                }
            }
        }

        stage('Apply Kubernetes Deployment') {
            steps {
                bat 'kubectl apply -f deployment.yaml'
                bat 'kubectl apply -f service.yaml'
            }
        }
        stage('Verify Deployment') {
            steps {
                bat 'kubectl get pods'
                bat 'kubectl get svc'
            }
        }
        stage('Get Service URL') {
            steps {
                script {
                    def svc_output = bat(script: 'kubectl get svc flask-app-service', returnStdout: true).trim()
                    echo "Service Details:\n${svc_output}"

                    def minikube_url = bat(script: 'minikube service flask-app-service --url', returnStdout: true).trim()
                    echo "Application is accessible at: ${minikube_url}"
                }
            }
        }
        
    }
}
