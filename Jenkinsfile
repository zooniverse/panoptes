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
      failFast true

      parallel {
        stage('Build staging AMI') {
          sh """
            cd "/var/jenkins_home/jobs/Zooniverse GitHub/jobs/operations/branches/master/workspace" && \
            ./rebuild.sh panoptes-api-staging
          """
        }

        stage('Build staging dump worker AMI') {
          sh """
            cd "/var/jenkins_home/jobs/Zooniverse GitHub/jobs/operations/branches/master/workspace" && \
            ./rebuild.sh panoptes-dumpworker-staging
          """
        }
      }
    }

    // stage('Deploy staging') {
    //   sh """
    //     cd "/var/jenkins_home/jobs/Zooniverse GitHub/jobs/operations/branches/master/workspace" && \
    //     ./deploy_latest.sh panoptes-api-staging
    //   """
    // }

    // stage('Deploy staging dump worker') {
    //   sh """
    //     cd "/var/jenkins_home/jobs/Zooniverse GitHub/jobs/operations/branches/master/workspace" && \
    //     ./deploy_latest.sh panoptes-dumpworker-staging
    //   """
    // }
  }
}
