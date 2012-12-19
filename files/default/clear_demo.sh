#!/bin/bash
set -e

# clear all settings for demo1/demo2
tenants="demo1 demo2"

function wait_for() {
    local first=0

    until $1; do
        if [ $first = 0 ]; then
            echo -n $2;
            first=1
        else
            echo -n .
        fi  

        sleep $3
    done

    echo
}

function delete_instance(){
	for tenant in $tenants; do
		. openrc $tenant

		function _instance_empty(){
			test $(nova list | grep -c 172.) = "0"
		}

		if ! _instance_empty; then
			nova list | awk '/172.16/{print $2}' | xargs -L1 nova delete
			wait_for _instance_empty "deleting instance $tenant" 1
		fi
	done
}

function delete_floatingip(){
	for tenant in $tenants; do
		tenant_id=$(keystone tenant-list | grep "$tenant " | awk '{print $2}')

		function _floatingip_empty(){
			test $(quantum floatingip-list -- --tenant_id=${tenant_id} | grep -c '10.100') = "0"
		}

		if ! _floatingip_empty; then
			quantum floatingip-list -- --tenant_id=${tenant_id} | awk '/10.100/{print $2}' | xargs -L1 quantum floatingip-delete
			wait_for _floatingip_empty "deleting floatingip $tenant" 1
		fi
	done
}

function delete_subnet(){
	for tenant in $tenants; do
		tenant_id=$(keystone tenant-list | grep "$tenant " | awk '{print $2}')

		function _subnet_empty(){
			test $(quantum subnet-list -- --tenant_id=${tenant_id} | grep -c '172.16') = "0"
		}

		if ! _subnet_empty; then
			quantum subnet-list -- --tenant_id=${tenant_id} | awk '/172.16/{print $2}' | xargs -L1 quantum subnet-delete
			wait_for _subnet_empty "deleting subnet $tenant" 1
		fi
	done
}

function delete_net(){
	for tenant in $tenants; do
		tenant_id=$(keystone tenant-list | grep "$tenant " | awk '{print $2}')

		function _net_empty(){
			test -z "$(quantum net-list -- --tenant_id=${tenant_id} | head -n -1 | tail -n +4)"
		}

		if ! _net_empty; then
			quantum net-list -- --tenant_id=${tenant_id} | head -n -1 | tail -n +4 | awk '{print $2}' | xargs -L1 quantum net-delete
			wait_for _net_empty "deleting network $tenant" 1
		fi
	done
}

function delete_router(){
	for tenant in $tenants; do
		tenant_id=$(keystone tenant-list | grep "$tenant " | awk '{print $2}')

		function _router_empty(){
			test -z "$(quantum router-list -- --tenant_id=${tenant_id} | head -n -1 | tail -n +4)"
		}

		if ! _router_empty; then
			quantum router-list -- --tenant_id=${tenant_id} | head -n -1 | tail -n +4 | awk '{print $2}' | xargs -L1 quantum router-delete
			wait_for _router_empty "deleting router $tenant" 1
		fi
	done
}

delete_instance
delete_floatingip
delete_subnet
delete_net
delete_router

# vim: nu ai ts=4 sw=4
