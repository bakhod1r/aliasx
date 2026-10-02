# Kubernetes and Helm.

if has kubectl; then
  # == kubectl
  alias k='kubectl'  # kubectl
  alias kg='kubectl get'  # get resources
  alias kd='kubectl describe'  # describe resource
  alias ka='kubectl apply -f'  # apply manifest file
  alias ke='kubectl edit'  # edit resource
  alias kdiff='kubectl diff -f'  # diff manifest against cluster

  # == Resources
  alias kgp='kubectl get pods'  # pods
  alias kgpa='kubectl get pods --all-namespaces'  # pods, all namespaces
  alias kgpw='kubectl get pods --watch'  # watch pods
  alias kgd='kubectl get deployments'  # deployments
  alias kgs='kubectl get services'  # services
  alias kgi='kubectl get ingress'  # ingresses
  alias kgn='kubectl get nodes'  # nodes
  alias kgns='kubectl get namespaces'  # namespaces
  alias kgcm='kubectl get configmaps'  # configmaps
  alias kdp='kubectl describe pod'  # describe pod
  alias kdd='kubectl describe deployment'  # describe deployment
  alias kev='kubectl get events --sort-by=.metadata.creationTimestamp'  # events, oldest first

  # == Logs and debugging
  alias kl='kubectl logs'  # pod logs
  alias klf='kubectl logs --follow --tail=200'  # follow last 200 pod log lines
  alias kexec='kubectl exec -it'  # exec into pod
  alias ktopn='kubectl top nodes'  # node CPU and memory
  alias ktopp='kubectl top pods'  # pod CPU and memory

  # == Context and namespace
  alias kctx='kubectl config current-context'  # current context
  alias kctxs='kubectl config get-contexts'  # all contexts
  alias kns='kubectl config view --minify --output "jsonpath={..namespace}"'  # current namespace

  # == Rollout
  alias kroll='kubectl rollout status'  # rollout status
  alias krestart='kubectl rollout restart'  # restart rollout
  alias khistory='kubectl rollout history'  # rollout history

  # == Troubleshooting
  alias kbad='kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded'  # pods not running
  alias kimages='kubectl get pods -A -o jsonpath="{..image}" | tr " " "\n" | sort | uniq -c'  # images in use
  alias kgall='kubectl get all'  # everything in namespace

  # ksecret NAME KEY — print decoded value of one secret key
  #   $ ksecret db-creds password
  #   s3cret
  function ksecret {
    [ "$#" -eq 2 ] || { echo "Usage: ksecret <secret> <key>" >&2; return 2; }
    kubectl get secret "$1" -o jsonpath="{.data.$2}" | base64 --decode; echo
  }

  # kshell POD — shell into pod (sh)
  #   $ kshell api-7d9f8b-x2k4
  #   /app $
  function kshell {
    [ "$#" -ge 1 ] || { echo "Usage: kshell <pod> [container]" >&2; return 2; }
    kubectl exec -it "$1" ${2:+-c "$2"} -- sh
  }

  # krun [IMAGE] — throwaway debug pod, removed on exit (default busybox)
  #   $ krun
  #   If you don't see a command prompt, try pressing enter.
  #   / #
  function krun { kubectl run "tmp-$$" --rm -it --restart=Never --image="${1:-busybox:1.36}" -- sh; }

  # kuse CONTEXT — switch kubectl context
  #   $ kuse prod
  #   Switched to context "prod".
  function kuse {
    [ "$#" -eq 1 ] || { echo "Usage: kuse <context>" >&2; return 2; }
    kubectl config use-context "$1"
  }

  # knamespace NS — set namespace for current context
  #   $ knamespace payments
  #   Context "prod" modified.
  function knamespace {
    [ "$#" -eq 1 ] || { echo "Usage: knamespace <namespace>" >&2; return 2; }
    kubectl config set-context --current --namespace="$1"
  }

  # kpf RESOURCE LOCAL:REMOTE — port-forward
  #   $ kpf svc/api 8080:80
  #   Forwarding from 127.0.0.1:8080 -> 80
  function kpf {
    [ "$#" -ge 2 ] || { echo "Usage: kpf <resource> <local:remote>" >&2; return 2; }
    kubectl port-forward "$@"
  }

  # kdebug POD [IMAGE] — attach debug container (default busybox)
  #   $ kdebug api-7d9f8b-x2k4
  #   Defaulting debug container name to debugger-x7k2.
  #   / #
  function kdebug {
    [ "$#" -ge 1 ] || { echo "Usage: kdebug <pod> [image]" >&2; return 2; }
    kubectl debug -it "$1" --image="${2:-busybox:1.36}"
  }

  # Keep completion working for k when kubectl completion is loaded.
  if [ -n "${ZSH_VERSION:-}" ]; then
    (( $+functions[compdef] )) && compdef k=kubectl
  elif typeset -f __start_kubectl >/dev/null 2>&1; then
    complete -o default -F __start_kubectl k
  fi
fi

if has helm; then
  # == Helm (prefix hm; h is history)
  alias hm='helm'  # helm
  alias hmls='helm list'  # releases
  alias hmlsa='helm list --all-namespaces'  # releases, all namespaces
  alias hmrepo='helm repo list'  # chart repositories
  alias hmrepou='helm repo update'  # update chart repositories
  alias hmsearch='helm search repo'  # search charts
  alias hmstatus='helm status'  # release status
  alias hmhistory='helm history'  # release history
  alias hmtemplate='helm template'  # render chart locally
  alias hmlint='helm lint'  # lint chart
fi
