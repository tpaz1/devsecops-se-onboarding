pipeline {
  agent any
  tools {
      jfrog 'jfrog-cli'
    }
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
    stage('Build Docker image') {
      steps {
        script {
            docker.build("$DOCKER_IMAGE_NAME", 'docker-oci-examples/docker-example')
        }
      }
    }

    stage('Scan and push image') {
      steps {
        dir('docker-oci-examples/docker-example/') {
            // Scan Docker image for vulnerabilities
            jf 'docker scan $DOCKER_IMAGE_NAME'
            // Push image to Artifactory
            jf 'docker push $DOCKER_IMAGE_NAME'
        }
      }
    }

    stage('Publish build info') {
      steps {
          jf 'rt build-publish'
      }
    }
  }
}
