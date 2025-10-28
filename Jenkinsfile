pipeline {
    agent any
    stages {
    stage("Environment Preparation") {
        steps {
            script {
               IMAGE_NAME = "flask-app"
               IMAGE_TAG = "${env.BUILD_NUMBER}"  // Unique tag per build
               FULL_IMAGE = "${IMAGE_NAME}:${IMAGE_TAG}"
               }
        }
    }
    
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

        stage('Trivy Scan Filesystem') {
            steps {
          bat '''
          echo Running Trivy filesystem scan...

          docker run --rm ^
            -v "%cd%":/project ^
            -v "%USERPROFILE%\\.trivy-cache":/root/.cache/trivy ^
            aquasec/trivy:latest fs /project ^
            --severity HIGH,CRITICAL ^
            --ignore-unfixed ^
            --exit-code 1 ^
            --format table
        '''
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
                    def imageExists = bat(script: 'docker images -q ${FULL_IMAGE}', returnStdout: true).trim()
                    if (imageExists) {
                        echo "Docker image already exists, skipping build."
                    } else {
                        bat "docker build --no-cache -t ${FULL_IMAGE}  --build-arg BUILD_NUMBER=${env.BUILD_NUMBER} ."
                        echo "Docker image built successfully"
                    }
                }
            }
        }
             
        stage('Trivy Image Scan') {
      steps {
        bat '''
          echo Scanning Docker image...

          docker run --rm ^
            -v /var/run/docker.sock:/var/run/docker.sock ^
            -v "%USERPROFILE%\\.trivy-cache":/root/.cache/trivy ^
            aquasec/trivy:latest image ${FULL_IMAGE} ^
            --severity HIGH,CRITICAL ^
            --ignore-unfixed ^
            --exit-code 1 ^
            --format table
        '''
      }
         }


        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'DockerHubCreds', passwordVariable: 'dockerHubPass', usernameVariable: 'dockerHubUser')]) {
                    script {
                        def imageAlreadyPushed = bat(script: 'docker manifest inspect ${env.dockerHubUser}/${FULL_IMAGE}', returnStatus: true)
                        if (imageAlreadyPushed == 0) {
                            echo "Image already exists in DockerHub, skipping push."
                        } else {
                            bat "docker login -u ${env.dockerHubUser} -p ${env.dockerHubPass}"
                            bat "docker image tag ${FULL_IMAGE} ${env.dockerHubUser}/${FULL_IMAGE}"
                            bat "docker push ${env.dockerHubUser}/${FULL_IMAGE}"
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
