buildImage {
  service_name      = 'brishon-consultant'
  git_repo          = 'https://github.com/rohan664/brishon_consultant.git'
  ecr_repo          = '959315332053.dkr.ecr.us-west-2.amazonaws.com/freelancing/brishon-consultant'
  downstream_jobs   = []
  testing_branch    = []
}