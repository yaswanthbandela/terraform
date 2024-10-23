resource "aws_codepipeline" "mtap_nextjs_pipeline" {
  name     = var.pipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner         = split("/", var.github_repo)[0]
        Repo          = split("/", var.github_repo)[1]
        Branch        = var.github_branch
        OAuthToken    = var.github_token
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      configuration = {
        ProjectName = aws_codebuild_project.mtap_nextjs_build.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name             = "Deploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "CodeDeploy"
      version          = "1"
      input_artifacts  = ["build_output"]
      configuration = {
        ApplicationName     = aws_codedeploy_app.mtap_nextjs_deploy.name
        DeploymentGroupName = aws_codedeploy_deployment_group.mtap_nextjs_deploy_dg.id
      }
    }
  }
}
