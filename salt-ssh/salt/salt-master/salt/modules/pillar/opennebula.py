# -*- coding: utf-8 -*-
'''
Data about OpenNebula VMs available as pillar data
'''

from __future__ import absolute_import

import logging
log = logging.getLogger(__name__)

import random
import string

try:
    import oca
    HAS_OCA = True
except ImportError:
    HAS_OCA = False

__opts__ = {'opennebula.endpoint': 'http://localhost:2633/RPC2',
            'opennebula.secret': 'oneadmin:opennebula'}

TYPE_MAP = {'bioconductor': 'student',
	    'bioconductor-teachers': 'teacher',
	    'bioconductor-nfs': 'nfs'}

def __virtual__():
    if HAS_OCA:
        return True
    return False

def ext_pillar(minion_id, pillar, _arg_):
    '''
    Finds OpenNebula VMs which belong to bio class and return their data as dict
    '''
    endpoint = __opts__['opennebula.endpoint']
    secret = __opts__['opennebula.secret']

    log.debug('endpoint: {0}, secret: {1}'.format(endpoint, secret))

    client = oca.Client(secret, endpoint)
    vm_pool = oca.VirtualMachinePool(client)
    vm_pool.info(-2)

    data = {}
    minion_id_split = minion_id.split('-', 2)
    user_token = minion_id_split[0]
    vm_id = minion_id_split[1]

    # set bio_type, bio_image, username and password
    for vm in vm_pool:
        if vm['ID'] == vm_id and vm['TEMPLATE/CONTEXT/USER_TOKEN'] == user_token:
            if vm['GNAME'] not in TYPE_MAP:
                return {}

            data['username'] = vm['UNAME']
            random.seed(user_token)
            data['password'] = ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(10))
            data['bio_type'] = TYPE_MAP[vm['GNAME']]
            bio_image_element = vm['TEMPLATE'].find('CONTEXT/BIO_IMAGE')
            if bio_image_element is None or isinstance(bio_image_element, (int,long)):
                continue
            data['bio_image'] = bio_image_element.text

    # set nfs ip
    vm_pool.info(-2)
    for vm in vm_pool:
        if vm['GNAME'] not in TYPE_MAP or TYPE_MAP[vm['GNAME']] != 'nfs':
            continue

        data['nfs_ip'] = vm.xml.findtext('TEMPLATE/NIC[last()]/IP')
        break

    if not data.has_key('bio_type') or data['bio_type'] != 'nfs':
        return data

    # set ip addresses and types for all users (only for nfs server)
    user_data = {}
    vm_pool.info(-2)
    for vm in vm_pool:
    	if vm['GNAME'] not in TYPE_MAP or TYPE_MAP[vm['GNAME']] == 'nfs':
    	    continue

        username = vm['UNAME']
        ips = []
        for nic in vm.xml.findall('TEMPLATE/NIC'):
            ips.append(nic.find('IP').text)
        if user_data.has_key(username):
            user_data[username]['ip_addresses'].extend(ips)
        else:
    	    user_data[username] = {}
    	    user_data[username]['ip_addresses'] = ips

	    user_data[username]['bio_type'] = TYPE_MAP[vm['GNAME']]

    data['user_data'] = user_data

    return data
