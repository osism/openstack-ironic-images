======
VyOS
======

Use VyOS ISO image as the baseline to built disk images.

Overrides:

 * To use a non-default URL for downloading the VyOS ISO image,
   use the environment variable ``DIB_ISO_IMAGE``
 * To download a non-default release of VyOS, use the
   environment variable ``DIB_RELEASE``. This element will export the
   ``DIB_RELEASE`` variable.
 * Setting ``DIB_OFFLINE`` will prevent to download the source image again
   if is already present in to $DIB_IMAGE_CACHE path.
 * Set ``DIB_LOCAL_IMAGE`` to use an image from a local source (full path and file name)
   and not download an image from internet.
 * To specifiy a non-default minisig public key use the environment variable
   ``DIB_MINISIG_PUBLIC_KEY``
 * Use ``DIB_CONSOLE_TYPE`` to specify a different console device

.. element_deps::
