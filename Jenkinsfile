#!groovy

pipeline {
  agent none

  options {
    quietPeriod(120)
    disableConcurrentBuilds()
  }

  stages {
    stage('Build Docker image') {
      agent any
      environment {
        DOCKER_BUILDKIT = 1
      }
      steps {
        script {
          def dockerRepoName = 'zooniverse/panoptes'
          def dockerImageName = "${dockerRepoName}:${GIT_COMMIT}"
          def newImage = docker.build(dockerImageName)
          newImage.push()

          if (BRANCH_NAME == 'master') {
            stage('Update latest tag') {
              newImage.push('latest')
            }
          }
        }
      }
    }

    stage('Dry run deployments') {
      agent any
      steps {
        sh "sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/job-db-migrate-production.tmpl | kubectl --context azure apply --dry-run=client --record -f -"
        sh "sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/job-rake-task-production.tmpl | kubectl --context azure apply --dry-run=client --record -f -"
      }
    }

    stage('Deploy production to Kubernetes') {
      when { tag 'production-release' }
      agent any
      steps {
        sh "sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/deployment-production.tmpl | kubectl --context azure apply --record -f -"
        sh "sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/deployment-production-azure-canary.tmpl | kubectl --context azure apply --record -f -"
      }
    }

    stage('Migrate production database') {
      when { tag 'production-migrate' }
      agent any
      steps {
        slackSend (
          color: '#0000FF',
          message: "Starting Panoptes production DB migration - Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})",
          channel: "#deploys"
        )
        sh """
          export JOB_NAME="panoptes-migrate-db-production-$env.BUILD_NUMBER"
          sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/job-db-migrate-production.tmpl \
            | sed "s/__JOB_NAME__/\$JOB_NAME/g" \
            | kubectl --context azure apply --record -f -

          kubectl wait --for=condition=complete --timeout=86400s job/\$JOB_NAME
          SUCCESS=\$?

          kubectl describe job/\$JOB_NAME
          kubectl logs \$(kubectl get pods --selector=job-name=\$JOB_NAME --output=jsonpath='{.items[*].metadata.name}')

          if [ \$SUCCESS -eq 0 ]
          then
            kubectl delete job \$JOB_NAME
          fi

          exit \$SUCCESS
        """
      }
    }

  }
  post {
    success {
      script {
        if (env.BRANCH_NAME == 'master' || env.TAG_NAME == 'production-release' || env.TAG_NAME == 'production-migrate') {
          slackSend (
            color: '#00FF00',
            message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})",
            channel: "#deploys"
          )
        }
      }
    }

    failure {
      script {
        if (env.BRANCH_NAME == 'master' || env.TAG_NAME == 'production-release' || env.TAG_NAME == 'production-migrate') {
          slackSend (
            color: '#FF0000',
            message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})",
            channel: "#deploys"
          )
        }
      }
    }
  }
}
