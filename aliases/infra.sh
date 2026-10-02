# Infrastructure as code: Terraform, OpenTofu, Ansible.
# No short alias for destroy.

if has terraform; then
  # == Terraform
  alias tf='terraform'  # terraform
  alias tfi='terraform init'  # init
  alias tff='terraform fmt -recursive'  # format all files
  alias tfv='terraform validate'  # validate
  alias tfp='terraform plan'  # plan
  alias tfa='terraform apply'  # apply (asks to confirm)
  alias tfpo='terraform plan -out=tfplan'  # plan and save to tfplan
  alias tfao='terraform apply tfplan'  # apply exactly the saved plan
  alias tfo='terraform output'  # outputs
  alias tfs='terraform show'  # show state or plan
  alias tfwl='terraform workspace list'  # list workspaces
  alias tfstate='terraform state list'  # list state resources
fi

if has tofu; then
  # == OpenTofu
  alias tofui='tofu init'  # tofu init
  alias tofuf='tofu fmt -recursive'  # tofu format all files
  alias tofuv='tofu validate'  # tofu validate
  alias tofup='tofu plan'  # tofu plan
  alias tofua='tofu apply'  # tofu apply (asks to confirm)
fi

if has ansible; then
  # == Ansible
  alias ap='ansible-playbook'  # run playbook
  alias apcheck='ansible-playbook --check --diff'  # dry-run playbook with diff
  alias ainv='ansible-inventory --graph'  # inventory graph
  alias alint='ansible-lint'  # lint playbooks
fi
