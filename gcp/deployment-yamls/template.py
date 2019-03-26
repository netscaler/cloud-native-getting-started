"""Creates Citrix ADC Three NIC deployment"""
COMPUTE_URL_BASE = 'https://www.googleapis.com/compute/v1/'
def GenerateConfig(context):
  if(context.properties['assign_public_ip'] == 'yes'):
      access_configs1 = [{
             'name': 'Management NAT',
             'type': 'ONE_TO_ONE_NAT'
#             'natIP': '$(ref.static-external-mgmt-ip-' + context.env['deployment'] + '.address)'
      }]
      access_configs2 = [{
             'name': 'Management NAT',
             'type': 'ONE_TO_ONE_NAT'
#             'natIP': '$(ref.static-external-traffic-ip-' + context.env['deployment'] + '.address)'
      }]
  elif(context.properties['assign_public_ip'] == 'no'):
      access_configs1 = []
      access_configs2 = []

  network_interfaces = [{
      'network': ''.join([COMPUTE_URL_BASE, 'projects/',
                          context.env['project'], '/global/networks/',
                          context.properties['mgmt_network']]),
      'subnetwork': ''.join([COMPUTE_URL_BASE, 'projects/',
                          context.env['project'], '/regions/',
                          context.properties['region'], '/subnetworks/',
                          context.properties['mgmt_subnet']]),
      'networkIP': '192.168.10.20',
      'accessConfigs': access_configs1
      },
      {
      'network': ''.join([COMPUTE_URL_BASE, 'projects/',
                          context.env['project'], '/global/networks/',
                          context.properties['client_network']]),
      'subnetwork': ''.join([COMPUTE_URL_BASE, 'projects/',
                          context.env['project'], '/regions/',
                          context.properties['region'], '/subnetworks/',
                          context.properties['client_subnet']]),
      'networkIP': '172.16.10.20',
      'accessConfigs': access_configs2
       },
       {
       'network': ''.join([COMPUTE_URL_BASE, 'projects/',
                           context.env['project'], '/global/networks/',
                           context.properties['server_network']]),
       'subnetwork': ''.join([COMPUTE_URL_BASE, 'projects/',
                           context.env['project'], '/regions/',
                           context.properties['region'], '/subnetworks/',
                           context.properties['server_subnet']]),
       'networkIP': '10.10.10.20',
       'accessConfigs': []
        }]

  if(context.properties['service_account'] != ""):
      service_accounts = [{
        'email': context.properties['service_account']
      }]
  else:
      service_accounts = []

  if(context.properties['ssh_public_key'] != ""):
      ssh_keys = [{
        'key': 'ssh-keys',
        'value':context.properties['ssh_public_key']
      }]
  else:
      ssh_keys = []

  resources = [{
      'name': 'citrix-adc-' + context.env['deployment'],
      'type': 'compute.v1.instance',
      'properties': {
          'zone': context.properties['google_zone'],
          'machineType': ''.join([COMPUTE_URL_BASE, 'projects/',
                                  context.env['project'], '/zones/',
                                  context.properties['google_zone'], '/machineTypes/',
                                  context.properties['instance_type']]),
          'serviceAccounts': service_accounts,
          'disks': [{
              'deviceName': 'boot',
              'type': 'PERSISTENT',
              'boot': True,
              'autoDelete': True,
              'initializeParams': {
                  'sourceImage': ''.join([COMPUTE_URL_BASE, 'projects/' + context.properties['image_project_name'],
                                          '/global/images/',
                                          context.properties['image_name'],
                                         ])
              }
          }],
          'networkInterfaces': network_interfaces,
          'metadata': {
              'items': ssh_keys
          },
          'tags': {
            'items': ['mgmt-firewall-' + context.env['deployment'],
                    'client-firewall-' + context.env['deployment'],
                    'server-firewall-' + context.env['deployment']]
          }
      }
  },
  {
    'name': 'mgmt-firewall-' + context.env['deployment'],
    'type': 'compute.v1.firewall',
    'properties': {
          'network': ''.join([COMPUTE_URL_BASE, 'projects/',
                            context.env['project'], '/global/networks/',
                            context.properties['mgmt_network']]),
          'sourceRanges': ['0.0.0.0/0'],
          'allowed': [{
              'IPProtocol': 'tcp',
              'ports': context.properties['mgmt_ports']
          }],
          'direction': 'INGRESS',
          'priority': 1000
      }
  },
  {
    'name': 'client-firewall-' + context.env['deployment'],
    'type': 'compute.v1.firewall',
    'properties': {
          'network': ''.join([COMPUTE_URL_BASE, 'projects/',
                            context.env['project'], '/global/networks/',
                            context.properties['client_network']]),
          'sourceRanges': ['0.0.0.0/0'],
          'allowed': [{
              'IPProtocol': 'tcp',
              'ports': context.properties['traffic_ports']
          }],
          'direction': 'INGRESS',
          'priority': 1000
       }
  },
  {
    'name': 'server-firewall-' + context.env['deployment'],
    'type': 'compute.v1.firewall',
    'properties': {
          'network': ''.join([COMPUTE_URL_BASE, 'projects/',
                            context.env['project'], '/global/networks/',
                            context.properties['server_network']]),
          'sourceRanges': ['0.0.0.0/0'],
          'allowed': [{
              'IPProtocol': 'tcp',
              'ports': context.properties['traffic_ports']
          }],
          'direction': 'INGRESS',
          'priority': 1000
       }
  }]
  """{
    'name': 'static-internal-mgmt-ip-' + context.env['deployment'],
    'type': 'compute.v1.addresses',
    'properties': {
        'addressType': 'INTERNAL',
        'region': context.properties['region'],
        'subnetwork': ''.join([COMPUTE_URL_BASE, 'projects/',
                            context.env['project'], '/regions/',
                            context.properties['region'], '/subnetworks/',
                            context.properties['mgmt_subnet']])
    }
  },
  {
    'name': 'static-internal-client-ip-' + context.env['deployment'],
    'type': 'compute.v1.addresses',
    'properties': {
        'addressType': 'INTERNAL',
        'region': context.properties['region'],
        'subnetwork': ''.join([COMPUTE_URL_BASE, 'projects/',
                            context.env['project'], '/regions/',
                            context.properties['region'], '/subnetworks/',
                            context.properties['client_subnet']])
    }
  },
  {
    'name': 'static-internal-server-ip-' + context.env['deployment'],
    'type': 'compute.v1.addresses',
    'properties': {
        'addressType': 'INTERNAL',
        'region': context.properties['region'],
        'subnetwork': ''.join([COMPUTE_URL_BASE, 'projects/',
                            context.env['project'], '/regions/',
                            context.properties['region'], '/subnetworks/',
                            context.properties['server_subnet']])
    }
  }]

  if(context.properties['assign_public_ip'] == 'yes'):
      resources.extend([{
        'name': 'static-external-mgmt-ip-' + context.env['deployment'],
        'type': 'compute.v1.addresses',
        'properties': {
            'addressType': 'EXTERNAL',
            'region': context.properties['region']
        }
      },
      {
        'name': 'static-external-traffic-ip-' + context.env['deployment'],
        'type': 'compute.v1.addresses',
        'properties': {
            'addressType': 'EXTERNAL',
            'region': context.properties['region']
        }
      }])

      outputs = [{
        'name': 'citrx-adc-mgmt-ip',
        'value': '$(ref.citrix-adc-' + context.env['deployment'] + '.networkInterfaces[0].accessConfigs[0].natIP)'
      },
      {
        'name': 'citrix-adc-client-ip',
        'value': '$(ref.citrix-adc-' + context.env['deployment'] + '.networkInterfaces[1].accessConfigs[0].natIP)'

      },
      {
        'name': 'citrix-adc-server-ip',
        'value': '$(ref.citrix-adc-' + context.env['deployment'] + '.networkInterfaces[2].networkIP)'

      }]
  elif(context.properties['assign_public_ip'] == 'no'):
      outputs = [{
        'name': 'citrx-adc-mgmt-ip',
        'value': '$(ref.citrix-adc-' + context.env['deployment'] + '.networkInterfaces[0].networkIP)'
      },
      {
        'name': 'citrx-adc-client-ip',
        'value': '$(ref.citrix-adc-' + context.env['deployment'] + '.networkInterfaces[1].networkIP)'
      },
      {
        'name': 'citrx-adc-server-ip',
        'value': '$(ref.citrix-adc-' + context.env['deployment'] + '.networkInterfaces[2].networkIP)'
      }]

  return {'resources': resources, "outputs": outputs}
"""
  return {'resources': resources}