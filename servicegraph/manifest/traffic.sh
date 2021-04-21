export VIP=$1
#!/bin/sh
while true
do
curl http://$VIP/tv-shows -H "Host: netflix-frontend-service"
sleep 3 
curl http://$VIP/tv-shows -H "Host: netflix-frontend-service"
sleep 3
curl http://$VIP/movies -H "Host: netflix-frontend-service"
sleep 3
curl http://$VIP/recommendation-engine?type=trending -H "Host: netflix-frontend-service"
sleep 3
curl http://$VIP/recommendation-engine?type=similar-shows -H "Host: netflix-frontend-service"
sleep 3
curl http://$VIP/recommendation-engine?type=mutual-friends-interests -H "Host: netflix-frontend-service"
sleep 3
curl http://$VIP/recommendation-engine?type=best-shows -H "Host: netflix-frontend-service"
sleep 3
done
