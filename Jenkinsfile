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

    stage('Mutation Tests - PIT') {
      steps {
        sh "mvn org.pitest:pitest-maven:mutationCoverage"
      }
      post {
        always {
          pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
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

    stage('Build and scan image') {
      steps {
        script {
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
        }
      }
    }

    stage('Push multi-platform image') {
      steps {
        script {
          def dockerImageName = "${IMAGE_NAME}:${GIT_COMMIT}"
          sh """
            jf docker buildx build --platform linux/amd64,linux/arm64 --push --tag ${dockerImageName} --file Dockerfile .

          """
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
        sh """
          export KUBECONFIG=/var/lib/jenkins/.kube/config
          kubectl get pods
          cd charts
          helm upgrade --install numeric-chart ./numeric-chart --set image.tag=${GIT_COMMIT}
        """
      }
    }
  } 
}
