# Virtual Machine Manager - Architecture Design & Functional Report

## 📋 **Executive Summary**

A comprehensive bash-based virtualization management system that provides automated KVM/QEMU setup, ISO management, VM lifecycle control, and storage orchestration with symlink-based flexible storage architecture.

---

## 🏗️ **System Architecture Design**

### **1. High-Level Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                    VIRTUAL MACHINE MANAGER                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  CLI Layer   │  │  Web UI      │  │  API Layer   │          │
│  │  (Bash)      │  │  (Future)    │  │  (Future)    │          │
│  └──────┬───────┘  └──────────────┘  └──────────────┘          │
│         │                                                       │
│  ┌──────▼────────────────────────────────────────────────┐     │
│  │              CORE FUNCTIONS LAYER                       │     │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │     │
│  │  │ Logger   │ │Validator │ │ System   │ │ Network  │ │     │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ │     │
│  └───────────────────────────────────────────────────────┘     │
│         │                                                       │
│  ┌──────▼────────────────────────────────────────────────┐     │
│  │           MODULES LAYER                                 │     │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │     │
│  │  │   VM     │ │ Storage  │ │Downloader│ │Template  │ │     │
│  │  │ Manager  │ │ Manager  │ │ Manager  │ │ Manager  │ │     │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ │     │
│  └───────────────────────────────────────────────────────┘     │
│         │                                                       │
│  ┌──────▼────────────────────────────────────────────────┐     │
│  │         INFRASTRUCTURE LAYER                            │     │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │     │
│  │  │  KVM/    │ │ Libvirt  │ │ Storage  │ │ Network  │ │     │
│  │  │  QEMU    │ │   API    │ │  (LVM/   │ │ Bridge   │ │     │
│  │  │          │ │          │ │  NFS)    │ │          │ │     │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ │     │
│  └───────────────────────────────────────────────────────┘     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### **2. Directory Structure Architecture**

```
/workspaces/virtula-machine/
│
├── 📁 Downloader/                    # ISO & Resource Management
│   ├── downloader.sh                 # Main downloader script
│   ├── *_source_iso.txt             # ISO source repositories
│   └── .download_manifest           # Download tracking
│
├── 📁 installer/                     # KVM/QEMU Installation
│   ├── kvm_qemu_installer.sh        # Main installer
│   ├── distros/                      # Distro-specific installers
│   │   ├── ubuntu.sh
│   │   ├── debian.sh
│   │   ├── fedora.sh
│   │   ├── centos.sh
│   │   └── arch.sh
│   └── templates/                    # VM configuration templates
│       ├── vm_template.xml
│       ├── network_default.xml
│       └── cloud_init.yml
│
├── 📁 lib/                           # Core Libraries
│   ├── core/                         # Core functionality
│   │   ├── logger.sh                 # Logging system
│   │   ├── print_info.sh             # Dual output (screen+log)
│   │   ├── system.sh                 # System utilities
│   │   └── validator.sh              # Input validation
│   ├── modules/                      # Feature modules
│   │   ├── file_ops.sh               # File operations
│   │   ├── network.sh                # Network utilities
│   │   ├── text_utils.sh             # Text processing
│   │   └── virtualization.sh         # VM management
│   ├── config/                       # Configuration
│   │   └── settings.conf             # Global settings
│   └── main_lib.sh                   # Master library
│
├── 📁 storage/                       # Symlink target directory
│   ├── iso/                          # ISO images storage
│   ├── vms/                          # VM disk images
│   │   ├── images/                   # QCOW2 files
│   │   └── disks/                    # Raw disk files
│   ├── templates/                    # VM templates
│   └── backups/                      # VM backups
│
├── 📁 logs/                          # Logging directory
│   ├── installer.log                 # Installation logs
│   ├── vm_operations.log             # VM operation logs
│   └── downloader.log                # Download logs
│
├── 📁 tests/                         # Testing framework
│   ├── test_virtualization.sh
│   ├── test_downloader.sh
│   └── test_storage.sh
│
├── 🔗 iso -> storage/iso             # Symlink for ISO access
├── 🔗 vms -> storage/vms             # Symlink for VM access
├── 🔗 templates -> storage/templates # Symlink for templates
├── 🔗 backups -> storage/backups     # Symlink for backups
│
└── 📄 README.md                      # Documentation
```

---

## 🎯 **Core Functionality Features**

### **Phase 1: Foundation (Backend Features)**

#### **1. Storage Management System**
```yaml
Features:
  - Symlink-based storage architecture
  - Multiple storage backend support (local, NFS, external drives)
  - Storage pool management
  - Automatic directory creation
  - Storage quota management
  - Space monitoring and alerts

Technical Implementation:
  - ln -sf for flexible storage mapping
  - df/du for space monitoring
  - Configurable storage paths
  - Backup and restore capabilities
```

#### **2. ISO Download & Management**
```yaml
Features:
  - Multi-distribution ISO sources (Ubuntu, Debian, Fedora, Arch, CentOS)
  - Parallel downloading support
  - Checksum verification (MD5/SHA256)
  - Resume capability for interrupted downloads
  - ISO caching mechanism
  - Version management and cleanup

Technical Implementation:
  - wget/curl with resume support
  - Source files for ISO URLs
  - Download manifest tracking
  - Automatic retry with exponential backoff
```

#### **3. VM Lifecycle Management**
```yaml
Features:
  - Create VM (customizable CPU, RAM, disk)
  - Start/Stop/Restart operations
  - VM cloning and templating
  - Snapshot management
  - VM migration support
  - Resource monitoring

Technical Implementation:
  - virsh commands integration
  - qemu-img for disk operations
  - XML template generation
  - VNC/SPICE console support
```

#### **4. Network Configuration**
```yaml
Features:
  - Default NAT network setup
  - Bridge network configuration
  - MAC address management
  - Port forwarding rules
  - VLAN support
  - Network isolation

Technical Implementation:
  - netplan configuration
  - brctl bridge management
  - iptables forwarding rules
  - DNS/DHCP configuration
```

#### **5. Logging & Monitoring**
```yaml
Features:
  - Dual output (screen + file logging)
  - Log rotation (size/time based)
  - Log levels (DEBUG, INFO, WARNING, ERROR)
  - Performance metrics collection
  - Audit trail for all operations
  - Real-time monitoring dashboard

Technical Implementation:
  - Timestamp-based logging
  - logrotate integration
  - Color-coded output
  - JSON log format option
```

---

## 📊 **Functional Modules Specification**

### **Module 1: Storage Manager (`storage_manager.sh`)**

```bash
Functions:
├── storage_init()              # Initialize storage system
├── storage_add_pool()          # Add new storage pool
├── storage_remove_pool()       # Remove storage pool
├── storage_list_pools()        # List all storage pools
├── storage_get_info()          # Get storage information
├── storage_check_space()       # Check available space
├── storage_create_directory()  # Create storage directories
├── storage_set_symlink()       # Set up storage symlinks
├── storage_migrate()           # Migrate storage to new location
└── storage_backup()            # Backup storage configuration
```

### **Module 2: ISO Manager (`iso_manager.sh`)**

```bash
Functions:
├── iso_add_source()            # Add new ISO source
├── iso_remove_source()         # Remove ISO source
├── iso_list_sources()          # List all ISO sources
├── iso_download()              # Download ISO file
├── iso_verify()                # Verify ISO checksum
├── iso_list_local()            # List local ISOs
├── iso_remove()                # Remove ISO file
├── iso_search()                # Search for ISO
├── iso_update_sources()        # Update source list
└── iso_import()                # Import existing ISO
```

### **Module 3: VM Manager (`vm_manager.sh`)**

```bash
Functions:
├── vm_create()                 # Create new VM
├── vm_delete()                 # Delete VM
├── vm_start()                  # Start VM
├── vm_stop()                  # Stop VM
├── vm_restart()                # Restart VM
├── vm_list()                   # List all VMs
├── vm_info()                   # Get VM information
├── vm_clone()                  # Clone VM
├── vm_snapshot_create()        # Create snapshot
├── vm_snapshot_restore()        # Restore snapshot
├── vm_snapshot_delete()        # Delete snapshot
├── vm_resize_disk()            # Resize VM disk
├── vm_add_disk()               # Add new disk
├── vm_remove_disk()            # Remove disk
├── vm_add_network()            # Add network interface
└── vm_console()                # Open VM console
```

### **Module 4: Network Manager (`network_manager.sh`)**

```bash
Functions:
├── network_setup_nat()         # Setup NAT network
├── network_setup_bridge()      # Setup bridge network
├── network_list()              # List networks
├── network_create()            # Create network
├── network_delete()            # Delete network
├── network_attach()            # Attach VM to network
├── network_detach()            # Detach VM from network
├── network_port_forward()      # Setup port forwarding
└── network_monitor()           # Monitor network traffic
```

---

## 🔄 **Data Flow Architecture**

### **VM Creation Flow**
```
User Input → Validation → Storage Check → ISO Selection → Template Generation
     ↓
Resource Allocation (CPU/RAM/Disk)
     ↓
Network Configuration
     ↓
VM Creation (virt-install)
     ↓
Post-Configuration (Cloud-init)
     ↓
Logging & Monitoring Setup
     ↓
VM Start & Verification
```

### **Storage Management Flow**
```
User Request → Check Storage Type → Validate Path → Create Directory
     ↓
Create Symlink (ln -sf)
     ↓
Update Configuration
     ↓
Set Permissions
     ↓
Test Access
     ↓
Update Storage Manifest
     ↓
Log Operation
```

---

## 📈 **Performance Metrics & KPIs**

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| VM Creation Time | < 30 sec | Timer on creation command |
| ISO Download Speed | Max bandwidth | wget/curl stats |
| Storage Access Latency | < 10ms | dd latency test |
| Log Processing | < 100ms | Timestamp diff |
| Script Response Time | < 2 sec | Shell time command |
| Concurrent VM Operations | 10+ | Background jobs |
| Backup/Restore Speed | > 50 MB/s | rsync stats |

---

## 🛡️ **Security & Error Handling**

### **Security Features**
```yaml
Authentication:
  - Sudo permission checking
  - User group validation (libvirt)
  - SSH key management for remote access

Authorization:
  - Role-based access control
  - Operation logging for audit
  - Command whitelisting

Data Protection:
  - Checksum verification for ISOs
  - Backup before destructive operations
  - Transaction-based operations
```

### **Error Handling Strategy**
```yaml
Level 1 - Validation:
  - Input sanitization
  - Path validation
  - Resource availability check

Level 2 - Recovery:
  - Automatic retry with backoff
  - Rollback on failure
  - Emergency cleanup procedures

Level 3 - Fallback:
  - Alternative storage paths
  - Degraded mode operation
  - User notification system
```

---

## 🚀 **Implementation Roadmap**

### **Phase 1: Core Foundation (Week 1-2)**
- [x] Directory structure setup
- [x] Logging system (print_info.sh)
- [x] Configuration management
- [x] Symlink storage architecture

### **Phase 2: Storage & ISO Management (Week 2-3)**
- [ ] Storage pool management
- [ ] ISO downloader with sources
- [ ] Checksum verification
- [ ] Download resume capability

### **Phase 3: VM Operations (Week 3-4)**
- [ ] VM creation wizard
- [ ] Start/Stop/Restart operations
- [ ] VM cloning and templates
- [ ] Snapshot management

### **Phase 4: Network & Advanced Features (Week 4-5)**
- [ ] Bridge network setup
- [ ] Port forwarding
- [ ] VM migration
- [ ] Performance monitoring

### **Phase 5: Testing & Documentation (Week 5-6)**
- [ ] Unit tests for all modules
- [ ] Integration testing
- [ ] User documentation
- [ ] Performance optimization

---

## 📊 **Configuration Schema**

```yaml
# config/settings.conf
storage:
  iso_location: "/storage/iso"
  vm_location: "/storage/vms"
  template_location: "/storage/templates"
  backup_location: "/storage/backups"
  min_free_space: "10G"

vm_defaults:
  memory: 2048
  cpus: 2
  disk_size: 20
  disk_format: "qcow2"
  network: "default"

downloader:
  parallel_downloads: 3
  checksum_verify: true
  resume_downloads: true
  timeout: 300

logging:
  level: "INFO"
  rotation_size: "10M"
  retention_days: 30
  dual_output: true

network:
  default_bridge: "br0"
  dhcp_range_start: "192.168.122.2"
  dhcp_range_end: "192.168.122.254"
```

---

## 🎯 **Success Criteria**

1. **Functional Requirements**
   - ✅ Successfully install KVM/QEMU on major Linux distros
   - ✅ Download and manage ISOs from multiple sources
   - ✅ Create, start, stop, delete VMs
   - ✅ Manage storage with symlinks
   - ✅ Complete logging of all operations

2. **Performance Requirements**
   - VM creation under 30 seconds
   - ISO verification under 10 seconds
   - Log search under 2 seconds for 10K entries

3. **Reliability Requirements**
   - 99.9% operation success rate
   - Automatic recovery from download failures
   - No data loss on error conditions

---

## 📝 **Report Generation Template**

```bash
# Generate architecture report
generate_architecture_report() {
    cat > ARCHITECTURE_REPORT.md << 'EOF'
# Architecture Report - $(date)

## System Status
- Storage Usage: $(du -sh storage/)
- Active VMs: $(virsh list --all | wc -l)
- ISO Count: $(ls -1 storage/iso/ | wc -l)
- Log Size: $(du -sh logs/)

## Performance Metrics
- Avg VM Creation Time: $(measure_vm_creation_time)
- Storage I/O: $(measure_storage_io)
- Network Throughput: $(measure_network_throughput)

## Resource Utilization
- CPU Usage: $(top -bn1 | grep "Cpu(s)")
- Memory Usage: $(free -h)
- Disk Usage: $(df -h storage/)

## Recent Operations
$(tail -20 logs/installer.log)

## Health Check
$(run_health_check)
EOF
}
```

This architecture provides a **robust, scalable, and maintainable** virtualization management system with clear separation of concerns, comprehensive logging, and flexible storage management through symlinks.