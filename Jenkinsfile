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
}