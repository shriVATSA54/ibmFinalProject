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
        
    }
}
