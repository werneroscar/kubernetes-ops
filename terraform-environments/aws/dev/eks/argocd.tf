resource "helm_release" "argocd" {
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = "true"
  name             = "argocd"
  version          = var.argo_helm_version
  repository       = "https://argoproj.github.io/argo-helm"

  values = [
    yamlencode({
      server = {
        service = {
          type = "NodePort"
        }
        ingress = {
          enabled = true
          hosts = ["argocd.${var.clustername}.${var.dns_domain}"]
          paths = ["/*"]
          extraPaths = [
            {
              path = "/*"
              backend = {
                serviceName = "ssl-redirect"
                servicePort = "use-annotation"
              }
            }
          ]
          https = true
          annotations = {
            "kubernetes.io/ingress.class" = "alb"
            "alb.ingress.kubernetes.io/backend-protocol" = "HTTPS"
            "alb.ingress.kubernetes.io/scheme" = "internet-facing"
            "alb.ingress.kubernetes.io/certificate-arn" = "${var.acm_cert_arn}"
            "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\":443}]"
            "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}"
            "external-dns.alpha.kubernetes.io/hostname" = "argocd.${var.clustername}.${var.dns_domain}"
          }
        }
        config = {
          url = "https://argocd.${var.clustername}.${var.dns_domain}"
        }
      }
      installCRDs = false
    })
  ]


  depends_on = [
    module.eks
  ]
}
