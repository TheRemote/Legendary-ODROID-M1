# Legendary ODROID M1 Ubuntu 22.04.1 Images
<img src="https://jamesachambers.com/wp-content/uploads/2022/10/Legendary_ODROID_M1_Images.webp" alt="Legendary ODROID M1 Ubuntu 22.04.1 Images">
NOTE:  You do not have to build this yourself.  Images are <a href="https://github.com/TheRemote/Legendary-ODROID-M1/releases">available in the Releases section.</a><br>
<br>
I made this image because I got tired of installing the server version of Ubuntu and then upgrading it on my M1 to 22.04.1 and then having to install the desktop.  It is currently building 6 different flavors (many of which are not officially available as an image).<br>
<br>
This is not using a mainline kernel.  It is using the official ODROID 5.19.x kernel packages from their PPA repository.  It looks like to me they're getting really close to finishing support.  The NPU overlay (rknpu) is not present in the 5.19x branch yet so they aren't quite finished but if you aren't using the NPU it's finished enough.  Since it's using official packages these will update with apt over time so there's a good chance the NPU may fix itself when they add a compatible rknpu overlay to the kernel package.<br>
<br>
If you'd like to build it yourself I have included the build script I used to make the images.  It is based off <a href="https://github.com/TheRemote/Ubuntu-Server-raspi4-unofficial">another project I did here on GitHub for Ubuntu 18.04</a> to make Ubuntu work with the Raspberry Pi (before it was officially supported).  See the "Build Instructions" section for more information.<br>
<br>
If you find any problems (or even better know how to fix them) you can submit them as a pull request or just let me know in the comments on my blog and I'll try to fix them!  Please keep in mind when looking for support that this is an unofficial image and I don't work for ODROID.  I won't be able to support you doing things that have nothing to do with the image itself.  If it's related to the image or how I've packaged it though definitely let me know as I am happy to clean up my packaging / image!<br>
<br>

<h2>Flavors Available</h2>
<ul>
  <li>Ubuntu 22.04.1 Server</li>
  <li>Ubuntu 22.04.1 Desktop (ubuntu-desktop)</li>
  <li>Ubuntu 22.04.1 MATE Desktop (ubuntu-mate-desktop)</li>
  <li>Xubuntu 22.04.1 XFCE Desktop (xubuntu-desktop)</li>
  <li>Kubuntu 22.04.1 KDE Desktop (kubuntu-desktop)</li>
  <li>Lubuntu 22.04.1 LXQt Desktop (lubuntu-desktop)</li>
</ul>

<h2>Known Issues</h2>
<ul>
  <li>NPU overlay is not present in the ODROID 5.19 kernel branch yet so the NPU will not work with this updated image/kernel yet</li>
</ul>

<h2>Image Instructions</h2>
The images are in .tar.xz format and should not be written to disk until you decompressed them with tar -xf *.tar.xz.  That will give you a .img file you can write.

<h2>First Startup Instructions</h2>
Note that the first startup is slow.  This is due to resizing your root filesystem to fit your drive.  After the first startup it will boot much faster but it may take several minutes on a black screen the first startup.  Be patient.  If you see a few lines of text then it is resizing your root filesystem.<br>
<br>
Set correct timezone:
<pre>sudo dpkg-reconfigure tzdata</pre>
Set correct locale:
<pre>sudo apt install locales -y && sudo dpkg-reconfigure locales</pre>
Get web browser (desktop only):
<pre>sudo snap install firefox</pre>
<pre>sudo snap install chromium</pre>

<h2>Build Instructions</h2>
The build system will first download the original ODROID image and update it to 22.04 desktop and server versions.  This makes repeat builds much faster as downloading the updates the first time takes a huge amount of time.  After this your individual changes you're making will be much faster.<br>
<br>
If you would like to build the image yourself it is pretty straightforward with the included script.  You will need a few dependencies such as:
<pre>sudo apt install build-essential guestfs-tools kpartx</pre>
Now run the build script with sudo ./BuildImage.sh.  It will retrieve the base image from ODROID's servers and update it.

<h2>Buy A Coffee / Donate</h2>
<p>People have expressed some interest in this (you are all saints, thank you, truly)</p>
<ul>
 <li>PayPal: 05jchambers@gmail.com</li>
 <li>Venmo: @JamesAChambers</li>
 <li>CashApp: $theremote</li>
 <li>Bitcoin (BTC): 3H6wkPnL1Kvne7dJQS8h7wB4vndB9KxZP7</li>
</ul>

<h2>Update History</h2>
<ul>
  <li>November 9th 2022 - V1.3</li>
    <ul>
        <li>Assign permanent randomly generated MAC address at first startup via netplan to prevent MAC changing every reboot</li>
        <li>Upgrade to ODROID Linux kernel 6.0 branch</li>
        <li>Add packages: lsusb ethtool ufw macchanger man locales</li>
    </ul>

  <li>October 18th 2022 - V1.2</li>
    <ul>
        <li>Reupload images as some were not mounting properly</li>
    </ul>
  <li>October 3rd 2022 - V1.1</li>
    <ul>
        <li>Add lubuntu-desktop flavor</li>
        <li>Purge old 4.x kernels to save image space</li>
        <li>Run update-initramfs -u on first startup</li>
        <li>Make resize-rootfs.sh find real root drive so that automatic expansion of rootfs works on SSDs/NVMe/etc.</li>
    </ul>
  <li>October 2nd 2022 - V1.0</li>
    <ul>
        <li>Initial Release</li>
    </ul>
</ul>
