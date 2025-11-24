pipeline {
  agent { 
    label 'jenkins-agent-docker'
    }
  
  triggers {
    pollSCM('H/5 * * * *')
  }

  environment {
    DOCKER_IMAGE_NAME = "FoodFrenzy"
    DOCKERHUB_REPO = "itzBonCar/food_frenzy"
    K8S_NAMESPACE  = "foodfrenzy-ns"
    K8S_MANIFEST_DIR = "k8s"
    MAVEN_OPTS = "-Xmx1g"
  }
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build (Maven)') {
      steps {
        sh 'mvn -B -DskipTests clean package'
      }
      post {
        always { archiveArtifacts artifacts: 'target/*.jar', fingerprint: true }
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          // tag: username/repo:branch-buildnum
          def shortCommit = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
          def tag = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}-${shortCommit}"
          env.IMAGE_TAG = tag
          sh "docker build -t ${env.DOCKERHUB_REPO}:${tag} ."
        }
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
          sh 'echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin'
          sh "docker push ${env.DOCKERHUB_REPO}:${env.IMAGE_TAG}"
          // update latest tag
          sh "docker tag ${env.DOCKERHUB_REPO}:${env.IMAGE_TAG} ${DOCKERHUB_REPO}:latest || true"
          sh "docker push ${DOCKERHUB_REPO}:latest || true"
        }
      }
    }

    stage('Deploy to K3s') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig-file', variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG=${KUBECONFIG_FILE}
            # update image with a rolling update
            kubectl -n ${K8S_NAMESPACE} set image deployment/foodfrenzy foodfrenzy=${DOCKERHUB_REPO}:${IMAGE_TAG} --record || true
            kubectl -n ${K8S_NAMESPACE} apply -f ${K8S_MANIFEST_DIR}/
          '''
        }
      }
    }
  }

  post {
    success { echo "Deployed ${DOCKERHUB_REPO}:${IMAGE_TAG}" }
    failure { echo "Pipeline failed" }
  }
}
