output "gateway_ip_hint" {
  value = "kubectl -n istio-system get svc istio-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
}
