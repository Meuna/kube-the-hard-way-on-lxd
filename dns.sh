#!/bin/bash
resolvectl dns k8sthw $(lxc network get k8sthw ipv4.address | cut -d'/' -f1)
resolvectl domain k8sthw '~k8sthw.local'