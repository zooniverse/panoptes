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

    stage('Build staging AMIs') {
      when {
        anyOf { branch 'master'; branch 'fix_jenkinsfile' }
      }
      failFast true
      parallel {
        stage('Build API') {
          steps {
            build job: '/Build Panoptes Staging AMI'
          }
        }
        stage('Build Dump workers') {
          steps {
            build job: '/Build Panoptes Staging Dump Worker AMI'
          }
        }
      }
    }

    stage('Deploy staging AMIs') {
      when {
        anyOf { branch 'master'; branch 'fix_jenkinsfile' }
      }
      failFast true
      parallel {
        stage('Deploy API') {
          steps {
            build job: '/Deploy latest Panoptes Staging build'
          }
        }
        stage('Deploy Dump workers') {
          steps {
            build job: '/Deploy latest Panoptes Staging dump worker build'
          }
        }
      }
    }
  }
}
