apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: my-{{.name}}-ingress
  namespace: {{.namespace}}
spec:
  rules:
  - host: gmt.blue.me
    http:
      paths:
      - path: /
        backend:
          serviceName: {{.name}} 
          servicePort: 80
