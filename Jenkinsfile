#!groovy

node {
  checkout scm

  def dockerRepoName = 'zooniverse/panoptes-jenkins'
  def dockerImageName = "${dockerRepoName}:${BRANCH_NAME}"
  def newImage = null

  stage('Build Docker image') {
    newImage = docker.build(dockerImageName)
    newImage.push()
  }

  if (BRANCH_NAME == 'master') {
    stage('Update latest tag') {
      newImage.push('latest')
    }

    stage('Build staging AMIs') {
      parallel api: {
        sh """
          cd "/var/jenkins_home/jobs/Zooniverse GitHub/jobs/operations/branches/master/workspace" && \
          ./rebuild.sh panoptes-api-staging
        """
      },
      worker: {
        sh """
          cd "/var/jenkins_home/jobs/Zooniverse GitHub/jobs/operations/branches/master/workspace" && \
          ./rebuild.sh panoptes-dumpworker-staging
        """
      }
    }

    stage('Migrate') {
      sh """#!/bin/bash -e

        cd "/var/jenkins_home/jobs/Zooniverse GitHub/jobs/operations/branches/master/workspace"

        source auto_cleanup.sh
        source deploylib.sh

        INSTANCE_ID=\$(./launch_latest.sh -q panoptes-api-staging)
        INSTANCE_DNS_NAME=\$(instance_dns_name \$INSTANCE_ID)

        # Wait for instance/panoptes to come up
        timeout_cmd "timeout 5m ssh ubuntu@\$INSTANCE_DNS_NAME docker-compose -f /opt/docker_start/docker-compose.yml -p panoptes-api-staging exec -T panoptes true"
        ssh ubuntu@\$INSTANCE_DNS_NAME docker-compose -f /opt/docker_start/docker-compose.yml -p panoptes-api-staging exec -T panoptes ./migrate.sh
      """
    }

    stage('Deploy staging') {
      parallel api: {
        sh """
          cd "/var/jenkins_home/jobs/Zooniverse GitHub/jobs/operations/branches/master/workspace" && \
          ./deploy_latest.sh panoptes-api-staging
        """
      },
      worker: {
        sh """
          cd "/var/jenkins_home/jobs/Zooniverse GitHub/jobs/operations/branches/master/workspace" && \
          ./deploy_latest.sh panoptes-dumpworker-staging
        """
      }
    }
  }
}
