# #Specify the ingress resource
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: online-boutique-ingress
  annotations:
   kubernetes.io/ingress.class: "tier-1-vpx"
   ingress.citrix.com/insecure-termination: "allow"
spec:
  rules:
  - host: ${demo_app_url}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port: 
              number: 80