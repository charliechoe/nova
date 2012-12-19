#!/bin/bash
set -e

tenants="demo1 demo2"
vm_for_tenant=2

for tenant in $tenants; do
	. openrc $tenant

	for n in `seq 1 $vm_for_tenant`; do
		./vm_create.sh ${tenant}_test${n}
	done
done

# vim: ai nu ts=4 sw=4
