# #Specify the ingress resource
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: vpx-ingress
  annotations:
   kubernetes.io/ingress.class: "tier-1-vpx"
   ingress.citrix.com/insecure-termination: "allow"
spec:
  rules:
  - host: ${demo_app_url_1}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: cpx-service
            port: 
              number: 80
  - host: ${demo_app_url_2}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: cpx-service
            port: 
              number: 80
  - host: ${demo_app_url_3}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: cpx-service
            port: 
              number: 80