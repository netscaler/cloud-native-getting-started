# Deploy a Citrix ADC CPX proxy in docker

Citrix ADC CPX is container based proxy can be deployed as a process in docker. Purpose of this guide is to showcase CPX deployment in docker. However Load Balancing use cases of CPX will be shown in other guides.

 Install a Citrix ADC CPX on the docker container
```
docker run -dt --name cpxproxy --privileged=true -e EULA=yes -e LS_IP=10.105.158.195 quay.io/citrix/citrix-k8s-cpx-ingress:13.0-47.103
```
Yeah! CPX proxy is UP and running. Lets verify it
```
ps aux | grep cpxproxy
docker exec -it cpxproxy bash
```
Lets check the CPX Express license details
```
cli_script.sh "sh capacity"
```
![Cpx Docker Cli](images/cpx-docker-cli.png)

To know more about CPX instance in docker,[ refer here](https://docs.citrix.com/en-us/citrix-adc-cpx/12/deploy-using-docker-image-file.html)

Click on [quick-start-guides](https://github.com/citrix/cloud-native-getting-started/tree/master/quick-start-guides) for next tutorials.