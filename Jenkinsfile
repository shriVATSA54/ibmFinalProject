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
                script {
                    bat "minikube start"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def imageExists = bat(script: 'docker images -q flask-app:latest', returnStdout: true).trim()
                    if (imageExists) {
                        echo "Docker image already exists, skipping build."
                    } else {
                        bat "docker build --cache-from flask-app:latest -t flask-app:latest ."
                        echo "Docker image built successfully"
                    }
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'DockerHubCreds', passwordVariable: 'dockerHubPass', usernameVariable: 'dockerHubUser')]) {
                    script {
                        def imageAlreadyPushed = bat(script: 'docker manifest inspect ${env.dockerHubUser}/flask-app:latest', returnStatus: true)
                        if (imageAlreadyPushed == 0) {
                            echo "Image already exists in DockerHub, skipping push."
                        } else {
                            bat "docker login -u ${env.dockerHubUser} -p ${env.dockerHubPass}"
                            bat "docker image tag flask-app:latest ${env.dockerHubUser}/flask-app:latest"
                            bat "docker push ${env.dockerHubUser}/flask-app:latest"
                        }
                    }
                }
            }
        }

        stage('Verify Deployment Files') {
            steps {
                script {
                    def files = bat(script: 'dir /b k8s', returnStdout: true).trim()
                    echo "K8s folder files:\n${files}"

                    if (!files.contains("deployment.yaml") || !files.contains("service.yaml")) {
                        error "Deployment files not found in k8s/ folder!"
                    }
                }
            }
        }

        stage('Apply Kubernetes Deployment') {
            steps {
                script {
                    def minikubeStatus = bat(script: 'minikube status', returnStdout: true).trim()
                    if (!minikubeStatus.contains("Running")) {
                        error "Minikube is not running! Cannot apply Kubernetes deployment."
                    } else {
                        bat 'kubectl apply -f k8s/deployment.yaml'
                        bat 'kubectl apply -f k8s/service.yaml'
                    }
                }
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
            // Port-forward the service to localhost
            bat 'kubectl port-forward service/flask-app-service 5000:5000 &'
            echo "Application is accessible at http://localhost:5000"
        }
    }
}
    }
}
