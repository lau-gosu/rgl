# Enable SSH Access for Administrator on Windows

This script automates the setup of SSH access to a Windows machine for the `Administrator` user using a public key. It installs and configures the OpenSSH Server, enables the firewall rule, adjusts the SSH configuration, and ensures proper permissions are set.

> ⚠️ **Important**: This must be run as **Administrator**.

---

## 📁 Files Included

- `enable-ssh.bat` — Launch script to run PowerShell setup
- `enable-ssh.ps1` — PowerShell script that performs all the setup
- `key.pub` — **Replace this file’s contents with your own SSH public key**
- `README.md` — This documentation

---

## 🔑 Step 1 — Provide Your Public Key

Open `key.pub` in a text editor and **replace its contents** with your own SSH public key. For example:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEG2... your_user@your_host
```


## ▶ Step 2 — Run the Setup

Right-click `enable-ssh.bat` and choose **"Run as administrator"**.

ALTERNATIVELY, run from Power shell:
 **Run the script**:
   ```powershell
   .\enable-ssh.ps1
   ```

   Or run the `.bat` wrapper:
   ```cmd
   enable-ssh.bat
   ```

---

## ⚙️ What the Script Does

- Installs **OpenSSH Server** (if missing)
- Enables **OpenSSH-Server-In-TCP** firewall rule
- Starts and configures `sshd` and `ssh-agent`
- Creates `.ssh` and `authorized_keys` for the `Administrator` user
- Adds your public key from `key.pub` if not already present
- Sets permissions:
  - Grants **Administrator** and **SYSTEM** users full access to `.ssh` and `authorized_keys`
- Updates `C:\ProgramData\ssh\sshd_config`:
  - Ensures `PubkeyAuthentication yes`
  - Enables `PasswordAuthentication yes`
  - Disables strict mode (`StrictModes no`)
  - Ensures `AuthorizedKeysFile` is set to `.ssh/authorized_keys`
- Restarts the SSH service

---

## ✅ After Setup

You should now be able to connect via SSH using:

```bash
ssh -i ~/.ssh/your_private_key Administrator@your-server-ip
```

## 📌 Notes

- If connection still fails, verify permissions on `.ssh` and `authorized_keys`:
  - Both **Administrator** and **SYSTEM** must have **full access**
- Check logs at:
  - `C:\ProgramData\ssh\logs\sshd.log`
  - Windows Event Viewer → Applications and Services Logs → OpenSSH → Admin

---