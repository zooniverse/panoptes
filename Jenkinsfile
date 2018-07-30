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
        stage('Build API') {
          build job: 'Panoptes/job/Build Panoptes Staging AMI'
        }
        stage('Build Dump workers') {
          build job: 'Panoptes/job/Build Panoptes Staging Dump Worker AMI'
        }
      }
    }

    stage('Deploy staging') {
      failFast true

      parallel {
        stage('Build API') {
          build job: 'Panoptes/job/Deploy latest Panoptes Staging build'
        }
        stage('Build Dump workers') {
          build job: 'Panoptes/job/	Deploy latest Panoptes Staging dump worker build'
        }
      }
    }
  }
}
