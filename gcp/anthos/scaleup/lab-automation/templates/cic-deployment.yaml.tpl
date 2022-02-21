# Modified from source: https://raw.githubusercontent.com/citrix/citrix-k8s-ingress-controller/master/deployment/dual-tier/manifest/all-in-one-dual-tier-demo.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cic-k8s-ingress-controller
spec:
  selector:
    matchLabels:
      app: cic-k8s-ingress-controller
  replicas: 1
  template:
    metadata:
      name: cic-k8s-ingress-controller
      labels:
        app: cic-k8s-ingress-controller
    spec:
      serviceAccountName: cpx
      containers:
      - name: cic-k8s-ingress-controller
        image: "quay.io/citrix/citrix-k8s-ingress-controller:1.13.20"
        env:
        - name: "NS_IP"
          value: "${ns_ip}"
        - name: "NS_USER"
          value: "nsroot"
        - name: "NS_PASSWORD"
          value: "${new_password}"
        - name: "EULA"
          value: "yes"
        - name: "NS_VIP"
          value: "${ns_vip}"
        args:
          - --ingress-classes
            tier-1-vpx
          - --feature-node-watch
            true
        imagePullPolicy: Always
