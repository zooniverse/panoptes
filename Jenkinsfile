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
          if (env.TAG_NAME == 'production-release') {
            stage('Update production release tag') {
              newImage.push('production-release')
            }
          }
        }
      }
    }

    stage('Build AMIs') {
      when { tag 'production-release' }
      failFast true
      parallel {
        stage('Production API') {
          options {
            skipDefaultCheckout true
          }
          agent {
            docker {
              image 'zooniverse/operations:latest'
              args '-v "$HOME/.ssh/:/home/ubuntu/.ssh" -v "$HOME/.aws/:/home/ubuntu/.aws"'
            }
          }
          steps {
            sh """#!/bin/bash -e
              while true; do sleep 3; echo -n "."; done &
              KEEP_ALIVE_ECHO_JOB=\$!
              cd /operations
              ./rebuild.sh -c panoptes-api
              kill \${KEEP_ALIVE_ECHO_JOB}
            """
          }
          post {
            success {
              slackSend (
                  color: '#00FF00',
                  message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})",
                  channel: "#ops"
                  )
            }
            failure {
              slackSend (
                  color: '#FF0000',
                  message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})",
                  channel: "#ops"
                  )
            }
          }
        }
        stage('Production Dump workers') {
          options {
            skipDefaultCheckout true
          }
          agent {
            docker {
              image 'zooniverse/operations:latest'
              args '-v "$HOME/.ssh/:/home/ubuntu/.ssh" -v "$HOME/.aws/:/home/ubuntu/.aws"'
            }
          }
          steps {
            sh """#!/bin/bash -e
              while true; do sleep 3; echo -n "."; done &
              KEEP_ALIVE_ECHO_JOB=\$!
              cd /operations
              ./rebuild.sh -c panoptes-dumpworker
              kill \${KEEP_ALIVE_ECHO_JOB}
            """
          }
          post {
            success {
              slackSend (
                  color: '#00FF00',
                  message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})",
                  channel: "#ops"
                  )
            }
            failure {
              slackSend (
                  color: '#FF0000',
                  message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})",
                  channel: "#ops"
                  )
            }
          }
        }
      }
    }

    stage('Deploy production AMIs') {
      when { tag 'production-release' }
      failFast true
      parallel {
        stage('Deploy API') {
          options {
            skipDefaultCheckout true
          }
          agent {
            docker {
              image 'zooniverse/operations:latest'
              args '-v "$HOME/.ssh/:/home/ubuntu/.ssh" -v "$HOME/.aws/:/home/ubuntu/.aws"'
            }
          }
          steps {
            sh """#!/bin/bash -e
              while true; do sleep 3; echo -n "."; done &
              KEEP_ALIVE_ECHO_JOB=\$!
              cd /operations
              ./deploy_latest.sh panoptes-api
              kill \${KEEP_ALIVE_ECHO_JOB}
            """
          }
        }
        stage('Deploy Dump workers') {
          options {
            skipDefaultCheckout true
          }
          agent {
            docker {
              image 'zooniverse/operations:latest'
              args '-v "$HOME/.ssh/:/home/ubuntu/.ssh" -v "$HOME/.aws/:/home/ubuntu/.aws"'
            }
          }
          steps {
            sh """#!/bin/bash -e
              while true; do sleep 3; echo -n "."; done &
              KEEP_ALIVE_ECHO_JOB=\$!
              cd /operations
              ./deploy_latest.sh panoptes-dumpworker
              kill \${KEEP_ALIVE_ECHO_JOB}
            """
          }
        }
      }
      post {
        failure {
          slackSend (
              color: '#FF0000',
              message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})",
              channel: "#ops"
              )
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
      }
    }

    stage('Deploy production to Kubernetes') {
      when { tag 'production-release' }
      agent any
      steps {
        sh "sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/deployment-production.tmpl | kubectl --context azure apply --record -f -"
      }
    }

    stage('Migrate production database') {
      when { tag 'production-migrate' }
      agent any
      steps {
        sh "sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/job-db-migrate-production.tmpl | kubectl --context azure apply --record -f -"
      }
    }

    stage('Deploy staging to Kubernetes') {
      when { branch 'master' }
      agent any
      steps {
        sh "sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/deployment-staging.tmpl | kubectl --context azure apply --record -f -"
      }
    }

    stage('Migrate staging database') {
      when { branch 'master' }
      agent any
      steps {
        sh "sed 's/__IMAGE_TAG__/${GIT_COMMIT}/g' kubernetes/job-db-migrate-staging.tmpl | kubectl --context azure apply --record -f -"
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
            channel: "#ops"
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
            channel: "#ops"
          )
        }
      }
    }
  }
}
