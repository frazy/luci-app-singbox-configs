# luci-app-singbox - OpenWrt LuCI Sing-Box Configuration Manager

This LuCI application provides a web-based interface for managing multiple Sing-Box configuration JSON files on an OpenWrt device. It allows users to upload, list, activate, download, and delete Sing-Box configuration files.

**Key Features:**
- Upload new Sing-Box configuration JSON files.
- List all available configuration files in a dedicated directory (`/etc/singbox/configs/`).
- Activate a chosen configuration file by creating a symbolic link (`/etc/singbox/config.json`) to it, and automatically restarting the Sing-Box service.
- Download existing configuration files for backup or modification.
- Delete unwanted configuration files.
- Manual restart option for the Sing-Box service.

## Prerequisites

1.  **OpenWrt Build Environment:** You need a working OpenWrt build environment (matching your device's architecture and OpenWrt version, e.g., 23.05.3).
2.  **Sing-Box Core:** The `singbox` executable must already be installed and configured on your OpenWrt device. This LuCI app assumes `singbox` reads its main configuration from `/etc/singbox/config.json` and can be restarted via `/etc/init.d/singbox restart`.

## Installation (Compile from Source)

Follow these steps to compile `luci-app-singbox` and install it on your OpenWrt device:

1.  **Clone OpenWrt Source:** If you haven't already, clone the OpenWrt source code for your target version.
    ```bash
    git clone https://git.openwrt.org/openwrt/openwrt.git
    cd openwrt
    git checkout openwrt-23.05 # Or your desired branch/tag
    ```

2.  **Add `luci-app-singbox` to Source Tree:** Copy the `luci-app-singbox` directory (this entire directory) into the `package/luci/applications/` directory of your OpenWrt source tree.
    ```bash
    cp -r /path/to/this/luci-app-singbox openwrt/package/luci/applications/
    ```

3.  **Update Feeds:**
    ```bash
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    ```

4.  **Configure OpenWrt Build:**
    ```bash
    make menuconfig
    ```
    Navigate to `LuCI` -> `Applications`, find `luci-app-singbox`, and select it by pressing `Y`. Save your configuration.

5.  **Compile the Package:**
    ```bash
    make package/luci-app-singbox/compile V=s
    # If you want to generate the .ipk directly without building a full firmware:
    # make package/luci-app-singbox/install V=s
    ```
    The generated `.ipk` file will be located in `bin/packages/<target-architecture>/luci/`.

## Deployment to OpenWrt Device

1.  **Transfer the `.ipk`:** Copy the generated `luci-app-singbox_*.ipk` file to your OpenWrt device using `scp` or `winscp`.
    ```bash
    scp bin/packages/<target-architecture>/luci/luci-app-singbox_*.ipk root@your_router_ip:/tmp/
    ```

2.  **Install the Package on Router:** SSH into your OpenWrt router and install the package.
    ```bash
    ssh root@your_router_ip
    opkg install /tmp/luci-app-singbox_*.ipk
    ```

3.  **Clear LuCI Cache:**
    ```bash
    /etc/init.d/uhttpd restart
    ```
    Or simply clear your browser cache and refresh the LuCI interface.

## Usage

1.  **Access LuCI:** Open your web browser and navigate to your OpenWrt router's LuCI interface (e.g., `http://192.168.1.1`).
2.  **Navigate:** Go to `Services` -> `Sing-Box`.
3.  **Manage Configurations:**
    *   **Upload:** Use the "Upload Sing-Box Configuration" section to upload new `.json` files.
    *   **Activate:** In the "Available Configurations" table, click "Activate" next to your desired configuration file. This will make it the active `config.json` for Sing-Box and restart the service.
    *   **Download/Delete:** Use the respective buttons to download or delete configuration files.
    *   **Restart Sing-Box:** Use the "Restart Sing-Box" button in the "Sing-Box Service Control" section to manually restart the service.

---

**Important Notes for Testing (if not on a real OpenWrt device):**

This project was developed in a sandbox environment where full OpenWrt compilation was not possible. The core logic of `singbox.lua` has been validated through simulated file system operations and HTTP requests.

- **File System Simulation:** The LuCI app expects Sing-Box configuration files to be stored in `/etc/singbox/configs/` and the active configuration to be symlinked as `/etc/singbox/config.json`. Ensure these directories and the symlink target exist and have proper permissions on your actual OpenWrt device.
- **Service Restart:** The controller executes `/etc/init.d/singbox restart`. Ensure this init script exists and correctly manages your Sing-Box service.