
# QEMU Alpine Docker Setup in Termux

This project automates the installation and booting of Alpine Linux in a QEMU virtual machine, utilizing Docker inside the VM for containerized environments. The project runs seamlessly within Termux on Android. This guide will walk you through the process.

![Project Banner](https://via.placeholder.com/800x200.png?text=QEMU+Alpine+Docker+Termux)

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Video Guide](#video-guide)
- [Asciinema Demo](#asciinema-demo)
- [Contributing](#contributing)
- [License](#license)

## Introduction

This project is designed for users who want to set up and run Alpine Linux on QEMU within Termux, and manage containers via Docker. It consists of two key scripts:
- **install_alpine.sh**: Installs the necessary components for running QEMU and Alpine Linux in Termux.
- **start_alpine.sh**: Boots the Alpine Linux VM with a shared folder and Docker capabilities.

## Features
- Full Alpine Linux VM inside Termux using QEMU.
- Docker installed and configured within the Alpine Linux environment.
- Shared folder between host (Android/Termux) and VM.
- Lightweight and efficient setup for development and testing.

## Prerequisites
Before you begin, ensure you have the following installed:
- Termux (Android), Termux-API (Android)
- QEMU (installed via Termux)
- Internet access for downloading required files
- Minimum 4GB RAM recommended for smooth operation

## Installation

### Step 1: Clone the Repository
Clone this repository to your local machine:
```bash
git clone https://github.com/remo7777/alpine-vm.git && cd alpine-qemu-docker-termux
```
### Step 2: Run the Installation Script
Run the `install_alpine.sh` script to install Alpine Linux, Docker, and set up QEMU:
```bash
bash install_alpine.sh
```
### Step 3: Start the Alpine Linux VM
After installation, you can start the Alpine Linux VM with Docker pre-configured using the following command:
```bash
bash start_alpine.sh
```
The VM will start in headless mode, and you can SSH into it using the following command on termux environment:

```bash
ssh root@localhost -p 2222
```
The password is set during the installation.

if SSH will detect a mismatch between the new key and the existing key stored in ~/.ssh/known_hosts. This mismatch triggers a warning or an error.
The command `ssh-keygen -R "[localhost]:2222"` is used to remove an existing SSH key entry for the specified hostname and port from the `~/.ssh/known_hosts` file.

### Shared Folder
A shared folder between Termux and the VM is located at `~/vm-shared`. You can access this within the VM as `/vm-shared`.

### Usage
To execute Docker commands inside termux terminal not in the VM, simply use command on termux terminal:

```bash
docker run hello-world

```
### Video Guide
Watch the YouTube guide for a step-by-step walkthrough of the installation and usage:
### Asciinema Demo
Check out this Asciinema video to see the setup in action directly from the terminal.
### Contributing
Contributions are welcome! Feel free to open a pull request or issue on GitHub if you'd like to contribute to this project.

### License
This project is licensed under the MIT License. See the LICENSE file for more details.
