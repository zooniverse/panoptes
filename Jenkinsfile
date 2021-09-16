#!groovy

pipeline {
  agent none

  options {
    quietPeriod(120)
    disableConcurrentBuilds()
  }

  stages {
    stage('Update documentation site') {
      when { branch 'master' }
      agent {
        dockerfile {
          filename 'Dockerfile.docs'
          args "-v /etc/group:/etc/group:ro -v /etc/passwd:/etc/passwd:ro -v /etc/shadow:/etc/shadow:ro -u root"
        }
      }

      steps {
        sh "cd /src/docs && git config remote.origin.url git@github.com:zooniverse/panoptes.git"
        sh "cd /src/docs && git config --global user.email jenkins@zooniverse.org"
        sh "cd /src/docs && git config --global user.name Zooniverse Jenkins"
        sshagent(credentials: ["cd5582ce-30e3-49bb-8b04-a1a5d1ff7b56"]) {
          sh "cd /src/docs && ls -al && ./deploy.sh"
        }
      }
    }

    stage('Build Docker image') {
      agent any
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
        sh "sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/deployment-staging.tmpl | kubectl --context azure apply --dry-run=client --record -f -"
        sh "sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/deployment-production.tmpl | kubectl --context azure apply --dry-run=client --record -f -"
        sh "sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/job-db-migrate-production.tmpl | kubectl --context azure apply --dry-run=client --record -f -"
        sh "sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/job-db-migrate-staging.tmpl | kubectl --context azure apply --dry-run=client --record -f -"
        sh "sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/job-rake-task-production.tmpl | kubectl --context azure apply --dry-run=client --record -f -"
        sh "sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/job-rake-task-staging.tmpl | kubectl --context azure apply --dry-run=client --record -f -"
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

    stage('Migrate staging database') {
      when { branch 'master' }
      agent any
      steps {
        slackSend (
          color: '#0000FF',
          message: "Starting Panoptes staging DB migration - Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})",
          channel: "#deploys"
        )
        sh """
          export JOB_NAME="panoptes-migrate-db-staging-$env.BUILD_NUMBER"
          sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/job-db-migrate-staging.tmpl \
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

    stage('Deploy staging to Kubernetes') {
      when { branch 'master' }
      agent any
      steps {
        sh "sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/deployment-staging.tmpl | kubectl --context azure apply --record -f -"
        sh "sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/deployment-staging-azure-canary.tmpl | kubectl --context azure apply --record -f -"
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
