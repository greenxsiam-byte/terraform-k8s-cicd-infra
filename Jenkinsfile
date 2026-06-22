// Jenkinsfile
// Equivalent pipeline to the GitHub Actions / GitLab CI examples, using Jenkins declarative syntax

pipeline {
    agent any

    tools {
        nodejs 'node-20'   // configured under Jenkins > Global Tool Configuration
    }

    environment {
        SLACK_WEBHOOK_URL = credentials('slack-webhook-url')
    }

    stages {

        stage('Build') {
            steps {
                sh 'npm ci'
                sh 'npm run build'
                archiveArtifacts artifacts: 'dist/**', fingerprint: true
            }
        }

        stage('Test') {
            parallel {
                stage('Lint') {
                    steps {
                        sh 'npm run lint'
                    }
                }
                stage('Unit tests') {
                    steps {
                        sh 'npm test -- --coverage'
                    }
                }
            }
        }

        stage('Deploy to staging') {
            when {
                branch 'main'
            }
            steps {
                sh 'echo "Deploying to staging..."'
                // sh 'aws s3 sync dist/ s3://my-staging-bucket --delete'
                sh 'npm run test:smoke -- --url=https://staging.example.com'
            }
        }

        stage('Approval') {
            when {
                branch 'main'
            }
            steps {
                // This is the manual approval gate in Jenkins
                input message: 'Deploy this build to production?', ok: 'Deploy'
            }
        }

        stage('Deploy to production') {
            when {
                branch 'main'
            }
            steps {
                sh 'echo "Deploying to production..."'
                // sh 'aws s3 sync dist/ s3://my-production-bucket --delete'
                sh '''
                  curl -X POST -H 'Content-type: application/json' \
                    --data '{"text":"Deployed to production"}' \
                    "$SLACK_WEBHOOK_URL"
                '''
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed — notifying team.'
            // mail to: 'team@example.com', subject: 'Build failed', body: "${env.BUILD_URL}"
        }
    }
}
