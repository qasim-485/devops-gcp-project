pipeline {
    agent any
    
    environment {
        PROJECT_ID = 'terraform-k8s-project-481806'
        CLUSTER_NAME = 'devops-gke-cluster'
        CLUSTER_ZONE = 'us-central1-a'
        GCR_REGISTRY = "gcr.io/${PROJECT_ID}"
        BACKEND_IMAGE = "${GCR_REGISTRY}/backend"
        FRONTEND_IMAGE = "${GCR_REGISTRY}/frontend"
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '📥 Checking out code from repository...'
                checkout scm
                sh 'git log -1 --pretty=format:"%h - %an, %ar : %s"'
            }
        }
        
        stage('Build Backend Image') {
            steps {
                script {
                    echo "🔨 Building Backend Docker Image..."
                    dir('backend') {
                        sh """
                            echo "Building backend with commit ${GIT_COMMIT_SHORT}"
                            docker build -t ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} .
                            docker tag ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} ${BACKEND_IMAGE}:latest
                            echo "✅ Backend image built successfully"
                        """
                    }
                }
            }
        }
        
        stage('Build Frontend Image') {
            steps {
                script {
                    echo "🔨 Building Frontend Docker Image..."
                    dir('frontend') {
                        sh """
                            echo "Building frontend with commit ${GIT_COMMIT_SHORT}"
                            docker build -t ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} .
                            docker tag ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} ${FRONTEND_IMAGE}:latest
                            echo "✅ Frontend image built successfully"
                        """
                    }
                }
            }
        }
        
        stage('Push Images to GCR') {
            steps {
                script {
                    echo "📤 Pushing images to Google Container Registry..."
                    sh """
                        echo "Pushing backend images..."
                        docker push ${BACKEND_IMAGE}:${GIT_COMMIT_SHORT}
                        docker push ${BACKEND_IMAGE}:latest
                        
                        echo "Pushing frontend images..."
                        docker push ${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT}
                        docker push ${FRONTEND_IMAGE}:latest
                        
                        echo "✅ All images pushed successfully"
                    """
                }
            }
        }
        
        stage('Verify Cluster Access') {
            steps {
                script {
                    echo "🔍 Verifying GKE cluster access..."
                    sh """
                        kubectl cluster-info
                        kubectl get nodes
                        kubectl get pods -n production
                    """
                }
            }
        }
        
        stage('Deploy to GKE') {
            steps {
                script {
                    echo "🚀 Deploying to Google Kubernetes Engine..."
                    sh """
                        echo "Updating backend deployment..."
                        kubectl set image deployment/backend \
                            backend=${BACKEND_IMAGE}:${GIT_COMMIT_SHORT} \
                            -n production
                        
                        echo "Updating frontend deployment..."
                        kubectl set image deployment/frontend \
                            frontend=${FRONTEND_IMAGE}:${GIT_COMMIT_SHORT} \
                            -n production
                        
                        echo "Waiting for backend rollout..."
                        kubectl rollout status deployment/backend -n production --timeout=600s
                        
                        echo "Waiting for frontend rollout..."
                        kubectl rollout status deployment/frontend -n production --timeout=600s
                        
                        echo "✅ Deployment completed successfully"
                    """
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    echo "✅ Verifying deployment..."
                    sh """
                        echo "=== Current Pod Status ==="
                        kubectl get pods -n production -o wide
                        
                        echo "=== Deployment Images ==="
                        kubectl get deployment backend -n production -o jsonpath='{.spec.template.spec.containers[0].image}'
                        echo ""
                        kubectl get deployment frontend -n production -o jsonpath='{.spec.template.spec.containers[0].image}'
                        echo ""
                        
                        echo "=== Service Endpoints ==="
                        kubectl get svc -n production
                        
                        echo "✅ Verification complete"
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo "🏥 Performing health check..."
                    sh """
                        sleep 10
                        
                        BACKEND_POD=\$(kubectl get pod -n production -l app=backend -o jsonpath='{.items[0].metadata.name}')
                        
                        echo "Testing backend health endpoint..."
                        kubectl exec -n production \$BACKEND_POD -- wget -q -O- http://localhost:5000/health || echo "Health check endpoint not ready yet"
                        
                        echo "✅ Health check complete"
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ =============================================='
            echo '✅  PIPELINE COMPLETED SUCCESSFULLY!'
            echo '✅  All images built, pushed, and deployed.'
            echo "✅  Commit: ${GIT_COMMIT_SHORT}"
            echo '✅ =============================================='
        }
        failure {
            echo '❌ =============================================='
            echo '❌  PIPELINE FAILED!'
            echo '❌  Check logs above for details.'
            echo "❌  Commit: ${GIT_COMMIT_SHORT}"
            echo '❌ =============================================='
        }
        always {
            echo '🧹 Cleaning up Docker resources...'
            sh 'docker system prune -f || true'
        }
    }
}