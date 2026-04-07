# Stop and remove the VMs
$vms = @("k8s-master", "k8s-worker1", "k8s-worker2")
foreach ($vm in $vms) {
    Stop-VM -Name $vm -Force -ErrorAction SilentlyContinue
    Remove-VM -Name $vm -Force -ErrorAction SilentlyContinue
}

# Delete the old VHD files
Remove-Item "C:\Hyper-V\Disks\k8s-master.vhdx" -ErrorAction SilentlyContinue
Remove-Item "C:\Hyper-V\Disks\k8s-worker1.vhdx" -ErrorAction SilentlyContinue
Remove-Item "C:\Hyper-V\Disks\k8s-worker2.vhdx" -ErrorAction SilentlyContinue