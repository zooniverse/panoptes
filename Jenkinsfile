pipeline {
  agent any

  stages {
    stage('Build Docker image') {
      steps {
        script {
          def dockerRepoName = 'zooniverse/panoptes-jenkins'
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

    stage('Building and deploying') {
      when {
        // change back to branch 'master', remove anyOf
        anyOf { branch 'master'; branch 'fix_jenkinsfile' }

        stage('Build staging AMIs') {
          failFast true
          parallel {
            stage('Build API') {
              steps {
                build job: 'Panoptes/job/Build Panoptes Staging AMI'
              }
            }
            stage('Build Dump workers') {
              steps {
                build job: 'Panoptes/job/Build Panoptes Staging Dump Worker AMI'
              }
            }
          }
        }

        stage('Deploy built staging AMIs') {
          failFast true

          parallel {
            stage('Build API') {
              steps {
                build job: 'Panoptes/job/Deploy latest Panoptes Staging build'
              }
            }
            stage('Build Dump workers') {
              steps {
                build job: 'Panoptes/job/	Deploy latest Panoptes Staging dump worker build'
              }
            }
          }
        }
      }
    }
  }
}
