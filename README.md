# Semiorbit UpWatch

**Semiorbit UpWatch** is a Linux-based upload malware monitoring system designed for
shared hosting, VPS, and production servers.

It provides a **safe, queue-based architecture** for scanning newly uploaded files
using system-level malware scanners (Linux Anti-Malware **ClamAV**), without relying on
inotify, PHP shell execution, or filesystem guessing.

UpWatch is built to be:
- predictable
- low overhead
- secure by default
- easy to operate under pressure

---

## 1. How UpWatch Works

UpWatch separates responsibilities into **three clear layers**:

### 1️⃣ Application layer (PHP, framework, app code)

Your application **does not scan files**.

Instead, when a file is successfully uploaded, the app appends the absolute file path
to a queue file:

```
/home/project/website/var/log/uploads.log
```

This is done safely using file append + locking.

---

### 2️⃣ Queue layer (uploads.log)

Each project has its own queue file:

```
/home/project/website/var/log/uploads.log
```

Characteristics:
- append-only
- writable by the project user
- root-controlled permissions
- resilient against accidental deletion

Each line represents **one uploaded file to be scanned**.

---

### 3️⃣ System scanner layer (root + cron)

A root-owned cron job runs periodically:

```
/usr/local/bin/upload_scan.sh
```

It:
- reads queued file paths
- scans each file with maldet / ClamAV
- quarantines or cleans malware immediately
- records results in a global audit journal
- removes processed paths from the queue

All scanning happens **outside** the web application.

---

### 4️⃣ Audit journal

Every scan result is recorded in:

```
/var/log/upload_scan.journal.log
```

Each entry contains:
```
timestamp | file_path | OK | INFECTED | MISSING
```

This provides:
- forensic traceability
- incident review
- zero cron spam

---

## 2. Installation

### Requirements

# INSTALL ClamAV/CLAMSCAN FIRST

- Linux (Rocky Linux / RHEL / AlmaLinux compatible)
- root access
- Linux anti-malware ClamAV (`clamscan`)
- **ClamAV** installed and working [**clamscan** should be tested]
- cron enabled

---

### Install UpWatch

```bash
git clone https://github.com/semiorbit/upwatch
cd upwatch
sudo bash install.sh
```

---

### Enable cron scanning

Add this to **root’s crontab**:

```cron
* * * * * /usr/local/bin/upload_scan.sh
```

---

## 3. Full Command Reference

Assume a project located at:

```
/home/project/website
```

---

### `upwatch /path`

Start watching a project for uploads.

```bash
upwatch /home/project/website
```

Creates `uploads.log`, sets permissions, and registers the project.

---

### `upwatch --stop /path`

Stop watching a project and remove its queue.

```bash
upwatch --stop /home/project/website
```

Removes configuration and deletes the project upload log.

---

### `upwatch --list`

List all watched projects.

```bash
upwatch --list
```

---

### `upwatch --status /path`

Check watch status for a project.

```bash
upwatch --status /home/project/website
```

---

### `upwatch --log`

View the full scan journal.

```bash
upwatch --log
```

---

### `upwatch --infected`

List infected files only.

```bash
upwatch --infected
```

---

### `upwatch --clean`

Clear the scan journal.

```bash
upwatch --clean
```

---

### `upwatch --stats`

Show scan statistics.

```bash
upwatch --stats
```

---

### `upwatch --tail`

Live scan activity view.

```bash
upwatch --tail
```

---

### `upwatch --doctor`

System health check.

```bash
upwatch --doctor
```

---

## PHP Integration (Optional)

```bash
composer require semiorbit/upwatch
```

---

## License

MIT License  
2026 © Semiorbit Solutions
