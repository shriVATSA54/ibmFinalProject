pipeline {
    agent any

    environment {
        IMAGE_NAME = 'sanjeevkt720/jenkins-flask-app'
        IMAGE_TAG = "${IMAGE_NAME}:${env.GIT_COMMIT}"
        KUBECONFIG = credentials('kubeconfig-credentials-id')
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    }

    stages {
        stage('Setup') {
            steps {
                bat 'dir %KUBECONFIG%'
                bat 'icacls %KUBECONFIG% /grant Everyone:F'
                bat 'dir %KUBECONFIG%'
                bat "pip install -r requirements.txt"
            }
        }
        
        stage('Test') {
            steps {
                bat "pytest"
            }
        }

        stage('Login to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-creds', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    bat 'echo %PASSWORD% | docker login -u %USERNAME% --password-stdin'
                }
                echo 'Login successfully'
            }
        }

        stage('Build Docker Image') {
            steps {
                bat 'docker build -t %IMAGE_TAG% .'
                echo "Docker image built successfully"
                bat 'docker images'
            }
        }

        stage('Push Docker Image') {
            steps {
                bat 'docker push %IMAGE_TAG%'
                echo "Docker image pushed successfully"
            }
        }

        stage('Deploy to Staging') {
            steps {
                bat 'kubectl config use-context user@staging.us-east-1.eksctl.io'
                bat 'kubectl config current-context'
                bat "kubectl set image deployment/flask-app flask-app=%IMAGE_TAG%"
            }
        }

        stage('Acceptance Test') {
            steps {
                script {
                    def service = bat(script: "kubectl get svc flask-app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}:{.spec.ports[0].port}'", returnStdout: true).trim()
                    echo "${service}"
                    bat "k6 run -e SERVICE=${service} acceptance-test.js"
                }
            }
        }

        stage('Deploy to Prod') {
            steps {
                bat 'kubectl config use-context user@prod.us-east-1.eksctl.io'
                bat 'kubectl config current-context'
                bat "kubectl set image deployment/flask-app flask-app=%IMAGE_TAG%"
            }
        }
    }
}
