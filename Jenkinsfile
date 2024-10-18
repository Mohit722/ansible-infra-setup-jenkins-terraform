pipeline {
    agent { label 'TERRAFORMCORE' } // Use the label of your Terraform node

    parameters {
        choice(name: 'ACTION', choices: ['Create', 'Destroy'], description: 'Select action to perform')
    }

    environment {
        AWS_CREDENTIALS_ID = 'aws_credentials' // Replace with your AWS credentials ID in Jenkins
        GITHUB_REPO = 'https://github.com/Mohit722/ansible-infra-setup-jenkins-terraform.git' // Replace with your repository
    }

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()  // Clean the workspace to remove previous files
            }
        }
        
        stage('Setup AWS Credentials') {
            steps {
                // Unset any existing AWS credentials to avoid conflicts
                sh 'unset AWS_ACCESS_KEY_ID'
                sh 'unset AWS_SECRET_ACCESS_KEY'
            }
        }
        
        stage('Clone Repository') {
            steps {
                // Clone the GitHub repository
                git GITHUB_REPO
            }
        }
        
        stage('Terraform Init and Plan') {
            when {
                expression { params.ACTION == 'Create' } // Run this stage only if 'Create' is selected
            }
            steps {
                dir("${WORKSPACE}") {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                        sh '''
                        terraform init
                        terraform validate
                        terraform plan -out=terraform_plan.out
                        '''
                    }
                }
            }
        }
        
        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'Create' } // Run this stage only if 'Create' is selected
            }
            steps {
                dir("${WORKSPACE}") {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }
        
        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'Destroy' } // Run this stage only if 'Destroy' is selected
            }
            steps {
                dir("${WORKSPACE}") {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                        sh 'terraform destroy -auto-approve'
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs() // Clean up the workspace after the pipeline finishes
        }
    }
}
