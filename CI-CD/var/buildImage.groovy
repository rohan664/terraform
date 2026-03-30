def call(body) {
    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    def SERVICE_NAME = config.service_name
    def GIT_REPO = config.git_repo
    def ECR_REPO = config.ecr_repo
    def DOWNSTREAM_JOBS = config.downstream_jobs ?: []
    def TESTING_BRANCHES = config.testing_branch ?: ['master']
    def VALID_BRANCH = ['master','qa','staging','production','main']
    def SKIPREMAININGSTEP = false

    pipeline {
        agent any
        triggers {
            GenericTrigger(
                genericVariables: [
                        [key: 'BRANCH_REF', value: '$.ref'],
                        [key: 'commit_id', value: '$.head_commit.id'],
                        [key: 'pushed_by', value: '$.pusher.name']
                ],
                causeString: 'Triggered on Commit by $pushed_by',
                token: "build/${SERVICE_NAME}",
                silentResponse: false,
            )
        }
        stages {
            stage('checkout') {
                steps {
                    script {
                        if(env.BRANCH_REF) {
                            env.BRANCH_NAME = "${BRANCH_REF}".replaceAll('refs/heads/', '')
                        }
                        else {
                            env.BRANCH_NAME = "master"
                        }
                    }
                    git url: "${GIT_REPO}", branch: "${BRANCH_NAME}", credentialsId: 'github-pass'
                    script{
                        env.COMMIT_SHA = sh(
                                returnStdout: true,
                                script: 'git rev-parse HEAD'
                        ).trim()
                    }
                }
            }
            stage('validate') {
                steps {
                    script {
                        if(!VALID_BRANCH.contains(BRANCH_NAME)){
                            SKIPREMAININGSTEP = true
                            println "SKIPREMAININGSTAGES = ${SKIPREMAININGSTAGES}"
                            println "Branch = ${BRANCH_NAME}"
                        }
                        else {
                            echo "Branch name is correct !!!"
                        }
                    }
                } 
            }
            stage('test'){
                when { expression {!SKIPREMAININGSTEP} }
                steps {
                    script {
                        if(TESTING_BRANCHES.contains(BRANCH_NAME)){
                            echo "Running Test Cases"
                        }   
                        else{
                            echo "Skipped Test Cases"
                        }
                    }
                }
            }
            stage('build'){
                when { expression {!SKIPREMAININGSTEP} }
                steps {
                    echo "current working dir"
                    sh "pwd"
                    sh "docker build -t ${ECR_REPO}:latest ."
                }
            }
            stage('publish'){
                when { expression {!SKIPREMAININGSTEP} }
                steps {
                    // DOCKER_TAG = "${BRANCH_NAME}".replaceAll("/", "-")
                    sh '$(aws ecr get-login --no-include-email --region us-west-2)'
                    sh "docker tag ${ECR_REPO}:latest ${ECR_REPO}:${BRANCH_NAME}-${COMMIT_SHA}"
                    sh "docker push ${ECR_REPO}:${BRANCH_NAME}-${COMMIT_SHA}"
                }
            }
        }
        post {
            success {
                script {
                    DOWNSTREAM_JOBS.each() { value ->
                        build(job: "${value}", wait: false, parameters: [[$class: 'StringParameterValue', name: 'BRANCH_REF', value: "${env.BRANCH_REF}"]])
                    }
                }
            }
            always {
                sh 'yes | docker image prune'
                sh 'yes | docker volume prune'
                sh '''docker images -a |  grep "${BRANCH_NAME}-.*" | awk '{print $3}' | xargs docker rmi -f'''
            }
        }

    }


}