apiVersion: apps/v1
kind: Deployment
metadata:
  name: citrix-node-controller
spec:
  selector:
    matchLabels:
      app: citrix-node-controller
  replicas: 1
  template:
    metadata:
      labels:
        app: citrix-node-controller
    spec:
      serviceAccountName: citrix-node-controller
      containers:
      - name: citrix-node-controller
        image: "quay.io/citrix/citrix-k8s-node-controller:2.2.5"
        imagePullPolicy: Always
        env:
        - name: NS_IP
          value: "${ns_ip}"
        - name: NS_USER
          value: "nsroot"
        - name: NS_PASSWORD
          value: "${new_password}"
        - name: NETWORK
          value: "172.16.3.0/24"
        - name: REMOTE_VTEPIP
          value: "${ns_ip}"
        - name: VXLAN_PORT
          value: "3267"
        - name: VNID
          value: "300"
        - name: CNI_TYPE
          value: "calico"