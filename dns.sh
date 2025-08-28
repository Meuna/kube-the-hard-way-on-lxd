#!/bin/bash
resolvectl dns kube-thw-on-lxd $(lxc network get kube-thw-on-lxd ipv4.address | cut -d'/' -f1)
resolvectl domain kube-thw-on-lxd '~kthw.local'