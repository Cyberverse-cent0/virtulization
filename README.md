# Virtualization Management Suite

A comprehensive collection of tools and utilities for managing virtual machines, organizing files, and system administration tasks.

## 📁 Project Overview

This repository contains multiple interconnected projects focused on virtualization management and system utilities:

### 🚀 Main Components

#### 1. **Virtual Machine Manager** (`virtual-machine-manager/`)
A comprehensive bash-based virtualization management system that provides automated KVM/QEMU setup, ISO management, VM lifecycle control, and storage orchestration.

**Key Features:**
- Automated KVM/QEMU installation for multiple Linux distributions
- ISO download and management with checksum verification
- VM creation, management, and lifecycle operations
- Symlink-based flexible storage architecture
- Network configuration (NAT, Bridge, VLAN support)
- Comprehensive logging and monitoring
- Template system for rapid VM deployment

**Quick Start:**
```bash
cd virtual-machine-manager
chmod +x main.sh
sudo ./main.sh
```

#### 2. **Python File Organizer** (`python_File_organiser/`)
An intelligent file organization system written in Python that helps categorize and manage files automatically.

**Features:**
- Automatic file categorization based on type and content
- Configurable organization rules
- Duplicate detection and management
- Support for multiple file formats
- Command-line interface for automation

**Installation:**
```bash
cd python_File_organiser
pip install -r requirements.txt
python setup.py install
```

#### 3. **Python Virtualization Manager** (`python_virtulization_manger/`)
Python-based utilities for virtualization management tasks.

#### 4. **Additional Utilities**
- **Password Manager** (`Password_mager/`) - Secure password storage and management
- **C File Simulator** (`c_file_simulator/`) - File system simulation tools
- **Chat Application** (`chat_app/`) - Communication utilities
- **Go File Organizer** (`go_File_organiser/`) - Go-based file organization
- **Mini Shell** (`mini_shell/`) - Lightweight shell implementation

## 🏗️ Architecture

The project follows a modular architecture with clear separation of concerns:

```
virtulization/
├── virtual-machine-manager/     # Main VM management system
├── python_File_organiser/       # Python-based file organization
├── python_virtulization_manger/  # Python VM utilities
├── Password_mager/              # Password management
├── c_file_simulator/            # File system simulation
├── chat_app/                    # Communication tools
├── go_File_organiser/           # Go-based organization
├── mini_shell/                  # Lightweight shell
└── README.md                    # This file
```

## 🛠️ System Requirements

### For Virtual Machine Manager:
- Linux operating system (Ubuntu, Debian, Fedora, CentOS, Arch)
- KVM/QEMU support
- libvirt
- sudo/root privileges
- 4GB+ RAM recommended
- 20GB+ free disk space

### For Python Components:
- Python 3.7+
- pip package manager
- Dependencies listed in individual `requirements.txt` files

## 📦 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/Cyberverse-cent0/virtulization.git
cd virtulization
```

### 2. Virtual Machine Manager Setup
```bash
cd virtual-machine-manager
chmod +x main.sh
sudo ./main.sh --install
```

### 3. Python File Organizer Setup
```bash
cd python_File_organiser
pip install -r requirements.txt
python setup.py install
```

## 🚀 Quick Start Guide

### Virtual Machine Manager
1. **Initialize the system:**
   ```bash
   cd virtual-machine-manager
   sudo ./main.sh --init
   ```

2. **Download an ISO:**
   ```bash
   sudo ./main.sh --download-iso ubuntu
   ```

3. **Create a VM:**
   ```bash
   sudo ./main.sh --create-vm my-vm --cpu 2 --memory 4096 --disk 20 --iso ubuntu-22.04.iso
   ```

4. **Start the VM:**
   ```bash
   sudo ./main.sh --start-vm my-vm
   ```

### Python File Organizer
1. **Organize a directory:**
   ```bash
   python -m file_organiser organize /path/to/directory
   ```

2. **Use custom rules:**
   ```bash
   python -m file_organiser organize /path/to/directory --config custom_rules.json
   ```

## 📚 Documentation

### Virtual Machine Manager
- Detailed architecture documentation: `virtual-machine-manager/README.md`
- Installation guides: `virtual-machine-manager/installer/`
- API documentation: `virtual-machine-manager/lib/`

### Python File Organizer
- Usage guide: `python_File_organiser/doc/Plan.md`
- Configuration: `python_File_organiser/file_organiser/config.py`

## 🧪 Testing

### Virtual Machine Manager Tests
```bash
cd virtual-machine-manager/tests
./test_virtualization.sh
./test_downloader.sh
./test_storage.sh
```

### Python Components Tests
```bash
cd python_File_organiser
python -m pytest tests/
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes and add tests
4. Run the test suite
5. Commit your changes: `git commit -m "Add feature description"`
6. Push to the branch: `git push origin feature-name`
7. Submit a pull request

## 📝 Development Status

### ✅ Completed Features
- [x] Virtual Machine Manager core architecture
- [x] KVM/QEMU installation scripts
- [x] ISO download management system
- [x] Storage management with symlinks
- [x] Python file organization framework
- [x] Comprehensive logging system
- [x] Basic VM lifecycle operations

### 🚧 In Progress
- [ ] Web UI for VM management
- [ ] Advanced network configuration
- [ ] VM migration tools
- [ ] Performance monitoring dashboard
- [ ] REST API for remote management

### 📋 Planned Features
- [ ] Multi-host management
- [ ] Container integration (Docker/LXC)
- [ ] Backup and disaster recovery
- [ ] High availability setup
- [ ] Mobile application

## 🐛 Troubleshooting

### Common Issues

**1. Permission Denied Errors**
```bash
# Ensure proper permissions
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER
# Logout and login again
```

**2. KVM Not Available**
```bash
# Check if virtualization is enabled
egrep -c '(vmx|svm)' /proc/cpuinfo
# Should return 1 or more
```

**3. Network Issues**
```bash
# Restart libvirt networking
sudo systemctl restart libvirtd
sudo virsh net-start default
```

### Getting Help
- Check the logs: `virtual-machine-manager/logs/`
- Review documentation in individual components
- Open an issue on GitHub

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- KVM/QEMU development team
- Libvirt project contributors
- Python packaging community
- Open source virtualization community

## 📞 Contact

- **Repository:** https://github.com/Cyberverse-cent0/virtulization.git
- **Issues:** https://github.com/Cyberverse-cent0/virtulization/issues
- **Discussions:** https://github.com/Cyberverse-cent0/virtulization/discussions

---

**Last Updated:** $(date '+%Y-%m-%d')
**Version:** 1.0.0-alpha
