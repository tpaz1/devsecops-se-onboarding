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

    stage('Build Docker image') {
      steps {
        script {
          def dockerImageName = "${IMAGE_NAME}:${GIT_COMMIT}"
          docker.build("${dockerImageName}", 'docker-oci-examples/docker-example')
        }
      }
    }

    stage('Scan and push image') {
      steps {
        script {
          def dockerImageName = "${IMAGE_NAME}:${GIT_COMMIT}"
          dir('docker-oci-examples/docker-example/') {
            sh "jf docker scan ${dockerImageName}"
            sh "jf docker push ${dockerImageName} serepo-docker --build-name=${BUILD_NAME} --build-number=${BUILD_NUMBER}"
          }
        }
      }
    }

    stage('Publish build info') {
      steps {
        sh "jf rt build-publish ${BUILD_NAME} ${BUILD_NUMBER}"
      }
    }
  }
}
