resource "harness_platform_connector_kubernetes" "kubernetes" {
  identifier  = "GKE"
  name        = "GKE"
  org_id      = var.org_name
  project_id  = var.project_name
  description = ""
  tags        = []
  inherit_from_delegate {
    delegate_selectors = ["se-sandbox-org-delegate"]
  }
}


resource "harness_platform_environment" "example" {
  identifier = "preprod"
  name       = "Pre-Production"
  org_id      = var.org_name
  project_id  = var.project_name
  tags       = ["env:nonprod"]
  type       = "PreProduction"
  description = ""
}

resource "harness_platform_infrastructure" "infra" {
  identifier      = "GKE"
  name            = "GKE"
  depends_on = [
    harness_platform_environment.example,
    harness_platform_connector_kubernetes.kubernetes,
  ]
  org_id      = var.org_name
  project_id  = var.project_name
  env_id          = "preprod"
  type            = "KubernetesDirect"
  deployment_type = "Kubernetes"
  yaml            = <<-EOT
        infrastructureDefinition:
          name: GKE
          identifier: GKE
          description: ""
          orgIdentifier: ${var.org_name}
          projectIdentifier: ${var.project_name}
          environmentRef: preprod
          deploymentType: Kubernetes
          type: KubernetesDirect
          spec:
            connectorRef: GKE
            namespace: ${var.k8s_ns}
            releaseName: release-xyz #needs fixing
          allowSimultaneousDeployments: true
      EOT
}

resource "harness_platform_service" "k8s_service" {
  identifier  = "application_service"
  name        = var.project_name
  depends_on = [
    harness_platform_infrastructure.infra,
  ]
  description = ""
  org_id      = var.org_name
  project_id  = var.project_name
  yaml = <<-EOT
                service:
                  name: ${var.project_name}
                  identifier: application_service
                  serviceDefinition:
                    type: Kubernetes
                    spec:
                      manifests:
                        - manifest:
                            identifier: manifests
                            type: K8sManifest
                            spec:
                              store:
                                type: Harness
                                spec:
                                  files:
                                    - account:/Sample K8s Manifests/templates/deployment.yaml
                                    - account:/Sample K8s Manifests/templates/namespace.yaml
                                    - account:/Sample K8s Manifests/templates/service.yaml
                              valuesPaths:
                                - account:/Sample K8s Manifests/values.yaml
                              skipResourceVersioning: false
                              enableDeclarativeRollback: false
                      artifacts:
                        primary:
                          primaryArtifactRef: <+input>
                          sources:
                            - spec:
                                connectorRef: account.DockerHub
                                imagePath: chrisjws/ym
                                tag: <+input>
                                digest: ""
                              identifier: app
                              type: DockerRegistry
                  gitOpsEnabled: false
              EOT
}

resource "harness_platform_secret_text" "harness_github_secret" {
  identifier = "github_pat"
  name       = "Github PAT"
  org_id     = var.org_name
  project_id     = var.project_name
  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = var.github_secret

}

resource "harness_platform_connector_github" "github" {
  identifier  = "Github"
  name        = "Github"
  description = ""
  org_id     = var.org_name
  project_id       = var.project_name
  url                 = "https://github.com"
  connection_type     = "Account"
  validation_repo     = "${var.repo_org}/${var.repo_name}"
  execute_on_delegate = true
  credentials {
    http {
      username  = "chrisjws-harness"
      token_ref = "github_pat"
    }
  }
  api_authentication {
    token_ref = "github_pat"
  }
  depends_on = [harness_platform_secret_text.harness_github_secret]
}


resource "harness_platform_pipeline" "build_and_deploy" {
  identifier = "build_and_deploy"
  org_id     = var.org_name
  depends_on = [
    harness_platform_service.k8s_service,
    harness_platform_connector_github.github,
  ]
  project_id       = var.project_name
  name       = "Build and Deploy"
    yaml = <<-EOT
pipeline:
  name: Build and Deploy
  identifier: build_and_deploy
  projectIdentifier: ${var.project_name}
  orgIdentifier: ${var.org_name}
  tags: {}
  stages:
    - stage:
        name: hello world
        identifier: hello_world
        description: ""
        type: CI
        spec:
          cloneCodebase: false
          caching:
            enabled: true
            override: false
          buildIntelligence:
            enabled: true
          infrastructure:
            type: KubernetesDirect
            spec:
              connectorRef: GKE
              namespace: default
              automountServiceAccountToken: true
              nodeSelector: {}
              os: Linux
          execution:
            steps:
              - step:
                  type: Run
                  name: ls
                  identifier: ls
                  spec:
                    connectorRef: account.DockerHub
                    image: library/nginx
                    shell: Sh
                    command: ls
  EOT
}


