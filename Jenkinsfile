@Library('slack') _


/////// ******************************* Code for fectching Failed Stage Name ******************************* ///////
import io.jenkins.blueocean.rest.impl.pipeline.PipelineNodeGraphVisitor
import io.jenkins.blueocean.rest.impl.pipeline.FlowNodeWrapper
import org.jenkinsci.plugins.workflow.support.steps.build.RunWrapper
import org.jenkinsci.plugins.workflow.actions.ErrorAction

// Get information about all stages, including the failure cases
// Returns a list of maps: [[id, failedStageName, result, errors]]
@NonCPS
List<Map> getStageResults( RunWrapper build ) {

    // Get all pipeline nodes that represent stages
    def visitor = new PipelineNodeGraphVisitor( build.rawBuild )
    def stages = visitor.pipelineNodes.findAll{ it.type == FlowNodeWrapper.NodeType.STAGE }

    return stages.collect{ stage ->

        // Get all the errors from the stage
        def errorActions = stage.getPipelineActions( ErrorAction )
        def errors = errorActions?.collect{ it.error }.unique()

        return [ 
            id: stage.id, 
            failedStageName: stage.displayName, 
            result: "${stage.status.result}",
            errors: errors
        ]
    }
}

// Get information of all failed stages
@NonCPS
List<Map> getFailedStages( RunWrapper build ) {
    return getStageResults( build ).findAll{ it.result == 'FAILURE' }
}

pipeline {
  agent any

  tools {
    jfrog 'jfrog-cli'
  }

  environment {
    JAVA_TOOL_OPTIONS = '-Djdk.lang.Process.launchMechanism=fork'
    IMAGE_NAME = "tompazus.jfrog.io/docker-virtual/numeric-app"
    GIT_COMMIT = "${env.GIT_COMMIT}"
    BUILD_NAME = "numeric-app"
    BUILD_NUMBER = "${BUILD_NUMBER}"
    applicationURL = "http://tomnodeport.soleng.jfrog.info"
    applicationURI = "increment/99"
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
              --url=https://tompazus.jfrog.io \
              --access-token=$ACCESS_TOKEN \
              --interactive=false \
              --overwrite=true \
              --artifactory-url=https://tompazus.jfrog.io/artifactory \
              --xray-url=https://tompazus.jfrog.io/xray
            jf c use jfrog-server

            # jf rt bce numeric-app $BUILD_NUMBER
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

          def dockerImageName = "${IMAGE_NAME}:${BUILD_NUMBER}"

          // jf docker buildx build --platform linux/amd64 --load --tag ${dockerImageName} --file Dockerfile .
          sh """
            if docker buildx ls | grep -q 'mybuilder'; then
              docker buildx use mybuilder
            else
              docker buildx create --use --name mybuilder
            fi
            jf c show
            jf rt ping
            jf docker pull tompazus.jfrog.io/docker-virtual/eclipse-temurin:17-jdk-jammy
            jf docker build -t ${dockerImageName} .
          """

          sh """
            export JFROG_CLI_BUILD_NAME=${BUILD_NAME}
            export JFROG_CLI_BUILD_NUMBER=${BUILD_NUMBER}
            jf docker scan ${dockerImageName} --format json > xray-scan-report-image.json
          """
          
          sh """
            echo "Vulnerability Summary:"
            cat xray-scan-report-image.json | jq '[.vulnerabilities[] | {severity, summary, component}]' | tee xray-scan-summary-image.txt
          """

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

          // jf docker buildx build --platform linux/amd64 --push --tag ${dockerImageName} --file Dockerfile .
          def dockerImageName = "${IMAGE_NAME}:${BUILD_NUMBER}"
          sh """
            jf docker push ${dockerImageName}
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
        sh """
          jf rt build-add-git ${BUILD_NAME} ${BUILD_NUMBER} # connect to git metadata and repo
          jf rt build-collect-env ${BUILD_NAME} ${BUILD_NUMBER} # show ENV variables
          jf rt build-publish ${BUILD_NAME} ${BUILD_NUMBER} # push info to rt 
        """
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
          jf build-scan ${BUILD_NAME} ${BUILD_NUMBER} --format json > xray-report-build.json
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
        script {
          withCredentials([usernamePassword(credentialsId: 'helm-keys', usernameVariable: 'ARTIFACTORY_USERNAME', passwordVariable: 'ARTIFACTORY_PASSWORD')]) {
            sh """
              export KUBECONFIG=/var/lib/jenkins/.kube/config
              kubectl get pods

              helm pull oci://tompazus.jfrog.io/se-helm-local/numeric-chart --version 1.0.0 --username $ARTIFACTORY_USERNAME --password $ARTIFACTORY_PASSWORD

              CHART_FILE=\$(ls numeric-chart-*.tgz)
  
              # Install or upgrade from Artifactory
              helm upgrade --install numeric-chart \$CHART_FILE --set image.tag=${BUILD_NUMBER} --wait --timeout 5m --atomic
            """
          }
        }
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

    stage('Integration Tests - DEV') {
      steps {
        script {
          githubNotify credentialsId: 'github-user', context: 'Integration Tests - DEV', status: 'PENDING', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
        }
        sh """
          export KUBECONFIG=/var/lib/jenkins/.kube/config
          kubectl get pods
          bash integration-test.sh
        """
        script {
          githubNotify credentialsId: 'github-user', context: 'Integration Tests - DEV', status: 'SUCCESS', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
        }
      }
      post {
        failure {
          script {
            githubNotify credentialsId: 'github-user', context: 'Integration Tests - DEV', status: 'FAILURE', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
          }
        }
      }
    }

    stage('OWASP ZAP - DAST') {
      steps {
        script {
          githubNotify credentialsId: 'github-user', context: 'Integration Tests - DEV', status: 'PENDING', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
        }
        sh """
          export KUBECONFIG=/var/lib/jenkins/.kube/config
          kubectl get pods
          bash zap.sh
        """
        script {
          githubNotify credentialsId: 'github-user', context: 'Integration Tests - DEV', status: 'SUCCESS', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
        }
      }
      post {
        failure {
          script {
            githubNotify credentialsId: 'github-user', context: 'Integration Tests - DEV', status: 'FAILURE', repo: 'devsecops-se-onboarding', account: 'tpaz1', sha: "${env.GIT_COMMIT}"
          }
        }
        always {
          publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: 'owasp-zap-report', reportFiles: 'zap_report.html', reportName: 'OWASP ZAP HTML Report', reportTitles: 'OWASP ZAP HTML Report', useWrapperFileDirectly: true])
        }
      }
    }
  }
  post { 
        always {
		        sendNotification currentBuild.result
        }
    }
}
