pipeline {
  agent any

  tools {
    jfrog 'jfrog-cli'
  }

  environment {
    IMAGE_NAME = "setompaz.jfrog.io/serepo-docker/numeric-app"
    GIT_COMMIT = "${env.GIT_COMMIT}"
    BUILD_NAME = "numeric-app"
    BUILD_NUMBER = "${BUILD_NUMBER}"
  }

  stages {
    stage('Build Artifact') {
      steps {
        sh "mvn clean package -DskipTests=true"
        archiveArtifacts 'target/*.jar'
      }
    }

    stage('Unit Test') {
      steps {
        sh "mvn test"
      }
      post {
        always {
          junit 'target/surefire-reports/*.xml'
          jacoco execPattern: 'target/jacoco.exec'
        }
      }
    }

    stage('Configure JFrog CLI') {
      steps {
        withCredentials([string(credentialsId: 'jfrog-access-token', variable: 'ACCESS_TOKEN')]) {
          sh """
            jf c add jfrog-server \
              --url=https://setompaz.jfrog.io \
              --access-token=$ACCESS_TOKEN \
              --interactive=false \
              --overwrite=true \
              --artifactory-url=https://setompaz.jfrog.io/artifactory \
              --xray-url=https://setompaz.jfrog.io/xray

            jf rt bce numeric-app $BUILD_NUMBER
          """
        }
      }
    }

    stage('Build Docker image') {
      steps {
        script {
          def dockerImageName = "${IMAGE_NAME}:${GIT_COMMIT}"
          sh "jf docker buildx build --platform linux/amd64 --tag ${dockerImageName} --file Dockerfile ."
        }
      }
    }

    stage('Scan and push image') {
      steps {
        script {
          def dockerImageName = "${IMAGE_NAME}:${GIT_COMMIT}"
          sh "jf docker scan ${dockerImageName}"
          sh "export JFROG_CLI_BUILD_NAME=${BUILD_NAME}"
          sh "export JFROG_CLI_BUILD_NUMBER=${BUILD_NUMBER}"
          sh "jf docker push ${dockerImageName}"
        }
      }
    }

    stage('Publish build info') {
      steps {
        sh "jf rt build-publish ${BUILD_NAME} ${BUILD_NUMBER}"
      }
    }

    stage('Kubernetes Deployment - DEV') {
      steps {
        withKubeConfig([credentialsId: 'kubeconfig-dev']) {
          sh """
            cd charts
            helm upgrade --install numeric-chart ./numeric-chart --set image.tag=${GIT_COMMIT}
          """
        }
      }
    }
  } 
}
