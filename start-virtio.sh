#!/bin/bash
qemu-system-x86_64 
  -enable-kvm 
  -cpu host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time 
  -smp 2 -m 4096 
  -drive file=win-server-diff.qcow2,format=qcow2,index=0,media=disk,if=virtio 
  -drive file=data-storage.qcow2,format=qcow2,index=1,media=disk,if=virtio 
  -netdev user,id=net0,hostfwd=tcp::3389-:3389 
  -device virtio-net-pci,netdev=net0 
  -display sdl,gl=on -vga virtio 
  -usb -device usb-tablet 
  -boot order=c
