pipeline {
    agent any

    environment {
        IMAGE_NAME = "flask-app"
        IMAGE_TAG = "${env.BUILD_NUMBER}"  // Unique tag per build
        FULL_IMAGE = "${IMAGE_NAME}:${IMAGE_TAG}"
        PYTHON_BIN = "/opt/homebrew/bin/python3"
    }


    stages {

        stage("Environment Preparation") {
            steps {
                echo "Preparing build environment..."
            }
        }
stage('Setup') {
  steps {
    sh '''
      echo "Creating venv with ${PYTHON_BIN}"
      ${PYTHON_BIN} -m venv .venv
      . .venv/bin/activate
      python -m pip install --upgrade pip
      pip install -r requirements.txt
    '''
  }
}

stage('Test') {
  steps {
    sh '''
      echo "Running pytest inside .venv"
      . .venv/bin/activate
      python -m pytest -q
    '''
  }
}

        stage('Trivy Scan Filesystem') {
            steps {
                sh '''
                    echo "Running Trivy filesystem scan..."
                    docker run --rm \
                        -v "$(pwd)":/project \
                        -v "$HOME/.trivy-cache":/root/.cache/trivy \
                        aquasec/trivy:latest fs /project \
                        --severity HIGH,CRITICAL \
                        --ignore-unfixed \
                        --exit-code 1 \
                        --format table
                '''
            }
        }

        stage('Start Minikube') {
            steps {
                sh "minikube start"
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build --no-cache -t ${FULL_IMAGE} --build-arg BUILD_NUMBER=${env.BUILD_NUMBER} ."
                echo "Docker image built successfully"
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh '''
                    echo "Scanning Docker image..."
                    docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        -v $HOME/.trivy-cache:/root/.cache/trivy \
                        aquasec/trivy:latest image \
                        --severity HIGH,CRITICAL \
                        --ignore-unfixed \
                        --exit-code 1 \
                        --format table \
                        ${FULL_IMAGE}
                '''
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'DockerHubCreds', passwordVariable: 'dockerHubPass', usernameVariable: 'dockerHubUser')]) {
                    sh '''
                        IMAGE_TAGGED=${env.dockerHubUser}/${FULL_IMAGE}
                        docker login -u ${env.dockerHubUser} -p ${env.dockerHubPass}
                        docker image tag ${FULL_IMAGE} ${IMAGE_TAGGED}
                        docker push ${IMAGE_TAGGED}
                    '''
                }
            }
        }

        stage('Verify Deployment Files') {
            steps {
                script {
                    def files = sh(script: 'ls k8s', returnStdout: true).trim()
                    echo "K8s folder files:\n${files}"

                    if (!files.contains("deployment.yaml") || !files.contains("service.yaml")) {
                        error "Deployment files not found in k8s/ folder!"
                    }
                }
            }
        }

        stage('Apply Kubernetes Deployment') {
            steps {
                sh '''
                    if minikube status | grep -q "Running"; then
                        kubectl apply -f k8s/deployment.yaml
                        kubectl apply -f k8s/service.yaml
                    else
                        echo "Minikube is not running!"
                        exit 1
                    fi
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh 'kubectl get pods'
                sh 'kubectl get svc'
            }
        }

        stage('Get Service URL') {
            steps {
                sh 'kubectl port-forward service/flask-app-service 5000:5000 &'
                echo "Application is accessible at http://localhost:5000"
            }
        }

    } 
}
