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
          def dockerImageName = "${dockerRepoName}:${BRANCH_NAME}"
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

    stage('Build AMIs') {
      failFast true
      parallel {
        stage('Staging API') {
          when { branch 'master' }
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
              ./rebuild.sh panoptes-api-staging
              kill \${KEEP_ALIVE_ECHO_JOB}
            """
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
        stage('Staging Dump workers') {
          when { branch 'master' }
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
              ./rebuild.sh panoptes-dumpworker-staging
              kill \${KEEP_ALIVE_ECHO_JOB}
            """
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
        stage('Production API') {
          when { tag 'production-release' }
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
              ./rebuild.sh panoptes-api
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
          when { tag 'production-release' }
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
              ./rebuild.sh panoptes-dumpworker
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

    stage('Migrate Staging DB') {
      when { branch 'master' }
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
          source auto_cleanup.sh
          source deploylib.sh
          INSTANCE_ID=\$(./launch_latest.sh -q panoptes-api-staging)
          INSTANCE_DNS_NAME=\$(instance_dns_name \$INSTANCE_ID)
          # Wait for instance/panoptes to come up
          timeout_cmd "timeout 5m ssh ubuntu@\$INSTANCE_DNS_NAME docker-compose -f /opt/docker_start/docker-compose.yml -p panoptes-api-staging exec -T panoptes true"
          ssh ubuntu@\$INSTANCE_DNS_NAME docker-compose -f /opt/docker_start/docker-compose.yml -p panoptes-api-staging exec -T panoptes ./migrate.sh
          kill \${KEEP_ALIVE_ECHO_JOB}
        """
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

    stage('Deploy staging AMIs') {
      when { branch 'master' }
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
              ./deploy_latest.sh panoptes-api-staging
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
              ./deploy_latest.sh panoptes-dumpworker-staging
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
  }
}
