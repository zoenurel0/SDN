# Readme.md

## **Capturing Packets**

### **VYOS**

monitor traffic interface eth1 verbose save vyos.pcap

scp vyos.pcap k8admin@10.7.80.95:/home/k8admin/vyos.pcap

scp save k8admin@10.7.80.95:/home/k8admin/vyos.pcap

### **Windows**

#### **Pktmon**
pktmon filter add -i 10.3.224.0/24

#pktmon filter add -i 10.4.32.64/27

pktmon filter remove *

pktmon start --etw -f c:\temp\pcapout.etl

pktmon stop

pktmon pcapng C:\temp\pcapout.etl -o c:\temp\pcapout.pcap


#### **NETSH**
netsh trace start capture=yes report=di

netsh trace stop

Netsh trace start scenario=Virtualization provider=Microsoft-Windows-Hyper-V-VfpExt capture=yes captureMultilayer=yes capturetype=both report=disabled MaxSize=2000

#### **OVSDB Client Dump**

* From VM Hosts
ovsdb-client.exe dump tcp:127.0.0.1:6641 ms_vtep