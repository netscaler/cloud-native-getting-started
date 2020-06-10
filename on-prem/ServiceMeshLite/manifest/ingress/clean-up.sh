kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/LB/rbac.yaml
kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/LB/cpx.yaml -n tier-2-adc
kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/LB/hotdrink-secret.yaml -n tier-2-adc
kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/LB/team_hotdrink.yaml -n team-hotdrink
kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/LB/hotdrink-secret.yaml -n team-hotdrink
kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/LB/team_colddrink.yaml -n team-colddrink
kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/LB/colddrink-secret.yaml -n team-colddrink
kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/LB/team_guestbook.yaml -n team-guestbook
kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/LB/cic_vpx.yaml -n tier-2-adc
kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/ingress/ingress_vpx.yaml -n tier-2-adc
kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/LB/vip.yaml
kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/LB/ipam_deploy.yaml
kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/LB/monitoring.yaml -n monitoring
kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/LB/ingress_vpx_monitoring.yaml -n monitoring
kubectl delete -f https://raw.githubusercontent.com/citrix/cloud-native-getting-started/master/on-prem/ServiceMeshLite/manifest/LB/namespace.yaml

  