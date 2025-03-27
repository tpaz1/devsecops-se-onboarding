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
          githubNotify credentialsId: 'github-user', context: 'Build Artifact', status: 'PENDING', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
        }
        sh "mvn clean package -DskipTests=true"
        archiveArtifacts 'target/*.jar'
        script {
          githubNotify credentialsId: 'github-user', context: 'Build Artifact', status: 'SUCCESS', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
        }
      }
      post {
        failure {
          script {
            githubNotify credentialsId: 'github-user', context: 'Build Artifact', status: 'FAILURE', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
          }
        }
      }
    }

    stage('Unit Test') {
      steps {
        script {
          githubNotify credentialsId: 'github-user', context: 'Unit Test', status: 'PENDING', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
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
            githubNotify credentialsId: 'github-user', context: 'Unit Test', status: 'SUCCESS', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
          }
        }
        failure {
          script {
            githubNotify credentialsId: 'github-user', context: 'Unit Test', status: 'FAILURE', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
          }
        }
      }
    }

    stage('Mutation Tests - PIT') {
      steps {
        script {
          githubNotify credentialsId: 'github-user', context: 'Mutation Tests', status: 'PENDING', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
        }
        sh "mvn org.pitest:pitest-maven:mutationCoverage"
      }
      post {
        always {
          pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
        }
        success {
          script {
            githubNotify credentialsId: 'github-user', context: 'Mutation Tests', status: 'SUCCESS', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
          }
        }
        failure {
          script {
            githubNotify credentialsId: 'github-user', context: 'Mutation Tests', status: 'FAILURE', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
          }
        }
      }
    }

    stage('Configure JFrog CLI') {
      steps {
        script {
          githubNotify credentialsId: 'github-user', context: 'Configure JFrog CLI', status: 'PENDING', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
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

            jf bce numeric-app $BUILD_NUMBER
          """
        }
        script {
          githubNotify credentialsId: 'github-user', context: 'Configure JFrog CLI', status: 'SUCCESS', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
        }
      }
      post {
        failure {
          script {
            githubNotify credentialsId: 'github-user', context: 'Configure JFrog CLI', status: 'FAILURE', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
          }
        }
      }
    }

    stage('Build and scan image') {
      steps {
        script {
          githubNotify credentialsId: 'github-user', context: 'Build and Scan Image', status: 'PENDING', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"

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
            jf docker scan ${dockerImageName} --output json > xray-scan-report-image.json
          """
          
          sh """
            echo "Vulnerability Summary:"
            cat xray-scan-report.json | jq '[.vulnerabilities[] | {severity, summary, component}]' | tee xray-scan-summary-image.txt
          """

          # Archive both detailed report and summary
          archiveArtifacts artifacts: 'xray-scan-report-image.json, xray-scan-summary-image.txt', allowEmptyArchive: true


          githubNotify credentialsId: 'github-user', context: 'Build and Scan Image', status: 'SUCCESS', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
        }
      }
      post {
        failure {
          script {
            githubNotify credentialsId: 'github-user', context: 'Build and Scan Image', status: 'FAILURE', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
          }
        }
      }
    }

    stage('Push multi-platform image') {
      steps {
        script {
          githubNotify credentialsId: 'github-user', context: 'Push Docker Image', status: 'PENDING', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"

          def dockerImageName = "${IMAGE_NAME}:${GIT_COMMIT}"
          sh """
            jf docker buildx build --platform linux/amd64,linux/arm64 --push --tag ${dockerImageName} --file Dockerfile .
          """

          githubNotify credentialsId: 'github-user', context: 'Push Docker Image', status: 'SUCCESS', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
        }
      }
      post {
        failure {
          script {
            githubNotify credentialsId: 'github-user', context: 'Push Docker Image', status: 'FAILURE', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
          }
        }
      }
    }

    stage('Publish build info') {
      steps {
        script {
          githubNotify credentialsId: 'github-user', context: 'Publish Build Info', status: 'PENDING', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
        }
        sh "jf rt build-publish ${BUILD_NAME} ${BUILD_NUMBER}"
        script {
          githubNotify credentialsId: 'github-user', context: 'Publish Build Info', status: 'SUCCESS', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
        }
      }
      post {
        failure {
          script {
            githubNotify credentialsId: 'github-user', context: 'Publish Build Info', status: 'FAILURE', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
          }
        }
      }
    }
    stage('Xray Scan') {
      steps {
        script {
          githubNotify credentialsId: 'github-user', context: 'Xray Scan', status: 'PENDING', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
        }
        sh """
          # Perform Xray scan and save results
          jf build-scan ${BUILD_NAME} ${BUILD_NUMBER} --output json > xray-report-build.json
        """
        archiveArtifacts artifacts: 'xray-report.json', allowEmptyArchive: true
        script {
          githubNotify credentialsId: 'github-user', context: 'Xray Scan', status: 'SUCCESS', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
        }
      }
      post {
        failure {
          script {
            githubNotify credentialsId: 'github-user', context: 'Xray Scan', status: 'FAILURE', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
          }
          archiveArtifacts artifacts: 'xray-report-build.json', allowEmptyArchive: true
        }
      }
    }

    stage('Kubernetes Deployment - DEV') {
      steps {
        script {
          githubNotify credentialsId: 'github-user', context: 'Kubernetes Deploy - DEV', status: 'PENDING', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
        }
        sh """
          export KUBECONFIG=/var/lib/jenkins/.kube/config
          kubectl get pods
          cd charts
          helm upgrade --install numeric-chart ./numeric-chart --set image.tag=${GIT_COMMIT}
        """
        script {
          githubNotify credentialsId: 'github-user', context: 'Kubernetes Deploy - DEV', status: 'SUCCESS', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
        }
      }
      post {
        failure {
          script {
            githubNotify credentialsId: 'github-user', context: 'Kubernetes Deploy - DEV', status: 'FAILURE', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
          }
        }
      }
    }
  }
}
