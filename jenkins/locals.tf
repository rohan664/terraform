locals {
  aws_region                      = "us-east-1"
  instance_type                   = "m7i-flex.large"
  instance_size                   = 10
  instance_user                   = "ubuntu"
  jenkins_image_account           = "400398152242"
  git_user                        = "jenkins"
  git_email                       = "rohandesai664@gmail.com"
  github_username                 = "rohan664"
  github_password                 = "rohandesai@664"
  github_api_token                = "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"
  admin_password                  = jsondecode(data.aws_secretsmanager_secret_version.qa_jenkins_secrets.secret_string)["jenkins_admin_password"]
  jenkins_domain_name             = "rohandesai.dev"
  jenkins_seed_job_repo_url       = "https://github.com/rohan664/terraform.git"
  jenkins_seed_job_repo_branch    = "main"
  jenkins_seed_job_jenkins_file   = "CI-CD/seed-job/seed-pipelines.groovy"
  identifier                      = "JENKINS"
  docker_compose = base64encode(templatefile("${path.module}/data/docker-compose.yml", {
    jenkins_url           = "http://${local.jenkins_domain_name}/"
    admin_password        = local.admin_password
    git_user              = local.git_user
    git_email             = local.git_email
    github_username       = local.github_username
    github_password       = local.github_password
    github_api_token      = local.github_api_token
    instance_user         = local.instance_user
    seed_job_repo_url     = local.jenkins_seed_job_repo_url
    seed_job_repo_branch  = local.jenkins_seed_job_repo_branch
    seed_job_jenkins_file = local.jenkins_seed_job_jenkins_file
  }))

  startup_script = base64encode(templatefile("${path.module}/data/jenkins.sh", {
    aws_region    = local.aws_region
    instance_user = local.instance_user
    registry_id   = local.jenkins_image_account
  }))

  jenkins_service = base64encode(templatefile("${path.module}/data/jenkins.service", {
    instance_user = local.instance_user
  }))

  jenkins = base64encode(templatefile("${path.module}/data/jenkins.yaml", {
    jenkins_admin_password  = jsondecode(data.aws_secretsmanager_secret_version.qa_jenkins_secrets.secret_string)["jenkins_admin_password"]
    developer_password = jsondecode(data.aws_secretsmanager_secret_version.qa_jenkins_secrets.secret_string)["developer_password"]
    devops_password = jsondecode(data.aws_secretsmanager_secret_version.qa_jenkins_secrets.secret_string)["devops_password"]
  }))

  cleanup_script = filebase64("${path.module}/data/cleanup.sh")

  lb_policy_attributes = {
    "Reference-Security-Policy" = "ELBSecurityPolicy-TLS-1-2-2017-01"
  }

  bootstrap_script = templatefile("${path.module}/data/user-data.sh",{
    instance_user   = local.instance_user
    casc            = local.jenkins
    docker_compose  = local.docker_compose
    startup_script  = local.startup_script
    jenkins_service = local.jenkins_service
    cleanup_script  = local.cleanup_script
    cleanup_schedule = var.cleanup_schedule
  })

  bastion_info = {
    bastion_user = "ubuntu"
    bastion_public_ip = "34.205.37.10"
    bastion_sgs = "sg-05963e520a9db355a"
  }

}

data "aws_secretsmanager_secret_version" "qa_jenkins_secrets" {
    secret_id = "qa_secrets"
}

