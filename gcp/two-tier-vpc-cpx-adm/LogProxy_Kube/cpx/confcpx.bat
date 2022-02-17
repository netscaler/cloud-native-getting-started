enable ns feature appflow cs lb 
enable ns mode ulfd
add dns nameserver 10.244.0.2
add server amazonsvr amazon.tracing.svc.cluster.local
add server titansvr titan.tracing.svc.cluster.local
add server casiosvr casio.tracing.svc.cluster.local 
add server sonatasvr sonata.tracing.svc.cluster.local 
add server fasttracksvr fasttrack.tracing.svc.cluster.local
add server logproxysvr logproxy.tracing.svc.cluster.local 
add service logproxysvc logproxysvr LOGSTREAM 5557 
add service amazonsvc amazonsvr HTTP 1719 -maxclient 2
add service fasttracksvc fasttracksvr HTTP 1720 -maxclient 2
add service titansvc titansvr HTTP 1721 -maxclient 2
add service casiosvc casiosvr HTTP 1722 -maxclient 2
add service sonatasvc sonatasvr HTTP 1723 -maxclient 2
set appflow param -templateRefresh 60 -SecurityInsightRecordInterval 60 -httpUrl ENABLED -httpCookie ENABLED -httpReferer ENABLED -httpMethod ENABLED -httpHost ENABLED -httpUserAgent ENABLED -httpContentType ENABLED -SecurityInsightTraffic ENABLED -httpQueryWithUrl ENABLED -urlCategory ENABLED -observationPointId 2540398090 -distributedTracing ENABLED -distTracingSamplingRate 100
add lb vserver vpy_sonata HTTP 0.0.0.0 0 -persistenceType NONE -cltTimeout 180
add lb vserver vpy_amazon HTTP 0.0.0.0 0 -persistenceType NONE -cltTimeout 180
add lb vserver vpy_casio HTTP 0.0.0.0 0 -persistenceType NONE -cltTimeout 180
add lb vserver vpy_fasttrack HTTP 0.0.0.0 0 -persistenceType NONE -cltTimeout 180
add lb vserver vpy_titan HTTP 0.0.0.0 0 -persistenceType NONE -cltTimeout 180
add cs vserver cs_tracingapps HTTP 10.102.9.60 8081 -cltTimeout 180
add cs policy amazon -rule "http.req.url.contains(\"/serial/view/watches\")"
add cs policy fasttrack -rule "http.req.url.contains(\"fasttrack\")"
add cs policy sonata -rule "http.req.url.contains(\"sonata\")"
add cs policy titan -rule "http.req.url.contains(\"titan\")"
add cs policy casio -rule "http.req.url.contains(\"casio\")"
bind lb vserver vpy_sonata sonatasvc
bind lb vserver vpy_amazon amazonsvc
bind lb vserver vpy_casio casiosvc
bind lb vserver vpy_fasttrack fasttracksvc
bind lb vserver vpy_titan titansvc
bind cs vserver cs_tracingapps -policyName amazon -targetLBVserver vpy_amazon -priority 1
bind cs vserver cs_tracingapps -policyName sonata -targetLBVserver vpy_sonata -priority 2
bind cs vserver cs_tracingapps -policyName casio -targetLBVserver vpy_casio -priority 3
bind cs vserver cs_tracingapps -policyName titan -targetLBVserver vpy_titan -priority 4
bind cs vserver cs_tracingapps -policyName fasttrack -targetLBVserver vpy_fasttrack -priority 5
bind cs vserver cs_tracingapps -analyticsprofile ns_analytics_default_http_profile
bind cs vserver cs_tracingapps -analyticsprofile ns_analytics_default_tcp_profile
set analyticsprofile ns_analytics_default_http_profile -httpURL enabled -httphost enabled -httpMethod ENABLED -httpUserAgent ENABLED -urlCategory ENABLED -httpContentType ENABLED -httpVia ENABLED -httpDomainName ENABLED -httpURLQuery ENABLED -collectors logproxysvc
set analyticsprofile ns_analytics_default_tcp_profile  -collectors logproxysvc
add ntp server 91.189.89.198 -minpoll 5 -maxpoll 10
enable ntp sync
