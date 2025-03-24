pipeline {
  agent any
  environment {
    IMAGE_NAME = "setompaz.jfrog.io/serepo-docker/numeric-app"
    GIT_COMMIT = "${env.GIT_COMMIT}"
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

    stage('Docker Build and Push') {
      steps {
        script {
          def server = Artifactory.server 'JFROG_ARTIFACTORY'

          def docker = Artifactory.docker server: server

          // Login to Artifactory Docker repo
          docker.login()

          def imageTag = "${IMAGE_NAME}:${GIT_COMMIT}"

          // Build Docker image
          sh "docker build -t ${imageTag} ."

          // Push Docker image
          docker.push imageTag, 'my-docker-dev'

          // Optionally logout after push
          docker.logout()
        }
      }
    }
  }
}
