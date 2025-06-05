# SSH Router App

## Description
This is a simple Terminal User Interface (TUI) application built with Textual for managing and connecting to SSH hosts. It allows you to search, add, and select hosts from your SSH configuration file, making it easier to work with remote servers.

## Features
- **Search Functionality**: Quickly filter and search for SSH hosts by name.
- **Add New Hosts**: Easily add new hosts with details like name, IP/URL, and user via a dedicated form.
- **Keyboard Navigation**: Use arrow keys to navigate fields, Ctrl+N to add a host, and ESC or Q to quit.
- **One-Command Launch**: Run the app with a simple command after installation.

## Installation
To install and set up the app with a single command, run the following in your terminal:

```
curl -sSL https://raw.githubusercontent.com/AlexMolio/ssh_router/main/install.sh | bash
```

This command will download the installation script and run it automatically. Make sure you have Python 3.8+ installed. **Note:** Always inspect scripts from the internet before running them for security reasons.

## Usage
1. After installation, launch the app by running `s` in your terminal.
2. Use the search bar to find hosts.
3. Press Ctrl+N to add a new host, fill in the details, and save.
4. Select a host from the list to connect via SSH.

Make sure you have Python 3.8+ installed. For any issues, check the app.py file or run the install script again.