# Download Ubuntu Server ISO first, then:
$vms = @("k8s-master", "k8s-worker1", "k8s-worker2")

foreach ($vm in $vms) {
    New-VM -Name $vm -MemoryStartupBytes 4GB -Generation 2 -Path "C:\Hyper-V\VMs"
    Set-VMProcessor $vm -Count 2
    New-VHD -Path "C:\Hyper-V\Disks\$vm.vhdx" -SizeBytes 20GB -Dynamic
    Add-VMHardDiskDrive -VMName $vm -Path "C:\Hyper-V\Disks\$vm.vhdx"
    Add-VMDvdDrive -VMName $vm -Path "C:\ISOs\ubuntu-24.04.4-live-server-amd64.iso"
    Connect-VMNetworkAdapter -VMName $vm -SwitchName "k8s-switch"
    # Required for Ubuntu Gen2
    Set-VMFirmware $vm -EnableSecureBoot Off
    Start-VM -Name $vm
}