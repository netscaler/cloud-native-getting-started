# #Specify the ingress resource
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: cpx-ingress
  annotations:
   kubernetes.io/ingress.class: "tier-2-cpx"
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
            name: pet-service
            port: 
              number: 7030
  - host: ${demo_app_url_2}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: user-service
            port: 
              number: 7040
  - host: ${demo_app_url_3}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: play-service
            port: 
              number: 7050