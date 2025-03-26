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
        script {
          githubNotify context: 'Build Artifact', status: 'PENDING'
        }
        sh "mvn clean package -DskipTests=true"
        archiveArtifacts 'target/*.jar'
        script {
          githubNotify context: 'Build Artifact', status: 'SUCCESS'
        }
      }
      post {
        failure {
          script {
            githubNotify context: 'Build Artifact', status: 'FAILURE'
          }
        }
      }
    }

    stage('Unit Test') {
      steps {
        script {
          githubNotify context: 'Unit Test', status: 'PENDING'
        }
        sh "mvn test"
      }
      post {
        always {
          junit 'target/surefire-reports/*.xml'
          jacoco execPattern: 'target/jacoco.exec'
        }
        success {
          script {
            githubNotify context: 'Unit Test', status: 'SUCCESS'
          }
        }
        failure {
          script {
            githubNotify context: 'Unit Test', status: 'FAILURE'
          }
        }
      }
    }

    stage('Mutation Tests - PIT') {
      steps {
        script {
          githubNotify context: 'Mutation Tests', status: 'PENDING'
        }
        sh "mvn org.pitest:pitest-maven:mutationCoverage"
      }
      post {
        always {
          pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
        }
        success {
          script {
            githubNotify context: 'Mutation Tests', status: 'SUCCESS'
          }
        }
        failure {
          script {
            githubNotify context: 'Mutation Tests', status: 'FAILURE'
          }
        }
      }
    }

    stage('Configure JFrog CLI') {
      steps {
        script {
          githubNotify context: 'Configure JFrog CLI', status: 'PENDING'
        }
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
        script {
          githubNotify context: 'Configure JFrog CLI', status: 'SUCCESS'
        }
      }
      post {
        failure {
          script {
            githubNotify context: 'Configure JFrog CLI', status: 'FAILURE'
          }
        }
      }
    }

    stage('Build and scan image') {
      steps {
        script {
          githubNotify context: 'Build and Scan Image', status: 'PENDING'

          def dockerImageName = "${IMAGE_NAME}:${GIT_COMMIT}"

          sh """
            if docker buildx ls | grep -q 'mybuilder'; then
              docker buildx use mybuilder
            else
              docker buildx create --use --name mybuilder
            fi
            jf docker buildx build --platform linux/amd64 --load --tag ${dockerImageName} --file Dockerfile .
          """

          sh """
            export JFROG_CLI_BUILD_NAME=${BUILD_NAME}
            export JFROG_CLI_BUILD_NUMBER=${BUILD_NUMBER}
            jf docker scan ${dockerImageName}
          """

          githubNotify context: 'Build and Scan Image', status: 'SUCCESS'
        }
      }
      post {
        failure {
          script {
            githubNotify context: 'Build and Scan Image', status: 'FAILURE'
          }
        }
      }
    }

    stage('Push multi-platform image') {
      steps {
        script {
          githubNotify context: 'Push Docker Image', status: 'PENDING'

          def dockerImageName = "${IMAGE_NAME}:${GIT_COMMIT}"
          sh """
            jf docker buildx build --platform linux/amd64,linux/arm64 --push --tag ${dockerImageName} --file Dockerfile .
          """

          githubNotify context: 'Push Docker Image', status: 'SUCCESS'
        }
      }
      post {
        failure {
          script {
            githubNotify context: 'Push Docker Image', status: 'FAILURE'
          }
        }
      }
    }

    stage('Publish build info') {
      steps {
        script {
          githubNotify context: 'Publish Build Info', status: 'PENDING'
        }
        sh "jf rt build-publish ${BUILD_NAME} ${BUILD_NUMBER}"
        script {
          githubNotify context: 'Publish Build Info', status: 'SUCCESS'
        }
      }
      post {
        failure {
          script {
            githubNotify context: 'Publish Build Info', status: 'FAILURE'
          }
        }
      }
    }

    stage('Kubernetes Deployment - DEV') {
      steps {
        script {
          githubNotify context: 'Kubernetes Deploy - DEV', status: 'PENDING'
        }
        sh """
          export KUBECONFIG=/var/lib/jenkins/.kube/config
          kubectl get pods
          cd charts
          helm upgrade --install numeric-chart ./numeric-chart --set image.tag=${GIT_COMMIT}
        """
        script {
          githubNotify context: 'Kubernetes Deploy - DEV', status: 'SUCCESS'
        }
      }
      post {
        failure {
          script {
            githubNotify context: 'Kubernetes Deploy - DEV', status: 'FAILURE'
          }
        }
      }
    }
  }
}
