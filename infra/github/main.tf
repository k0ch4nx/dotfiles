data "github_repository" "this" {
  full_name = "${var.owner}/${var.repository}"
}

resource "github_repository_ruleset" "main" {
  name        = "main"
  repository  = data.github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion            = true
    non_fast_forward    = true
    required_signatures = true

    pull_request {
      allowed_merge_methods             = ["merge"]
      required_approving_review_count   = 0
      required_review_thread_resolution = true
    }

    required_status_checks {
      strict_required_status_checks_policy = true

      required_check {
        context        = "macOS"
        integration_id = 15368
      }

      required_check {
        context        = "Ubuntu WSL"
        integration_id = 15368
      }
    }
  }
}
