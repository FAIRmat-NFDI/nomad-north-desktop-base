ARG  JUPYTER_VERSION=2025-12-31
FROM quay.io/jupyter/base-notebook:${JUPYTER_VERSION}

USER root

RUN apt-get -y -qq update \
 && apt-get -y -qq install \
        dbus-x11 \
        xclip \
        xfce4 \
        xfce4-panel \
        xfce4-session \
        xfce4-settings \
        xorg \
        xubuntu-icon-theme \
        fonts-dejavu \
 # Disable the automatic screenlock since the account password is unknown
 && apt-get -y -qq remove xfce4-screensaver \
 # chown $HOME to workaround that the xorg installation creates a
 # /home/jovyan/.cache directory owned by root
 && chown -R $NB_UID:$NB_GID $HOME \
 && fix-permissions "/home/${NB_USER}" \
 && rm -rf /var/lib/apt/lists/*

# Install a VNC server (TurboVNC)
# Install instructions from https://turbovnc.org/Downloads/YUM

ENV PATH=/opt/TurboVNC/bin:$PATH
RUN wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | \
    gpg --dearmor >/etc/apt/trusted.gpg.d/TurboVNC.gpg \
 && wget -O /etc/apt/sources.list.d/TurboVNC.list https://raw.githubusercontent.com/TurboVNC/repo/main/TurboVNC.list \
 && rm "/home/${NB_USER}/.wget-hsts" \
 && apt-get -y -qq update \
 && apt-get -y -qq install \
        turbovnc \
 && rm -rf /var/lib/apt/lists/*

# ---- Chrome ----
# --no-sandbox: containers can't set up Chromium's setuid sandbox, so Chrome
# fails to start without it; --disable-dev-shm-usage avoids the small default
# /dev/shm size causing renderer crashes; --password-store=basic stops Chrome
# from prompting to create a system keyring, since none runs in this desktop
# image; --disable-gpu-sandbox/--use-gl=angle/--use-angle=swiftshader/
# --enable-unsafe-swiftshader make WebGL fall back to software rendering
# instead of failing outright with no real GPU in the container.
#
# Patched into google-chrome-stable's own wrapper script (the last line of
# /opt/google/chrome/google-chrome, which /usr/bin/google-chrome-stable
# symlinks to), not just its .desktop file's Exec line - google-chrome-stable
# also registers itself as the system's x-www-browser alternative, which is
# what xfce's panel "web browser" launcher and exo's WebBrowser helper resolve
# to; patching only the .desktop file leaves those other paths launching
# Chrome unflagged.
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
 && apt-get -y -qq update \
 && apt-get -y -qq install ./google-chrome-stable_current_amd64.deb \
 && rm google-chrome-stable_current_amd64.deb \
 && apt-get clean && rm -rf /var/lib/apt/lists/* \
 && sed -i 's|exec -a "\$0" "\$HERE/chrome" "\$@"|exec -a "$0" "$HERE/chrome" --no-sandbox --disable-dev-shm-usage --password-store=basic --disable-gpu-sandbox --use-gl=angle --use-angle=swiftshader --enable-unsafe-swiftshader "$@"|' \
        /opt/google/chrome/google-chrome

USER $NB_USER

# Install the environment first, and then install the package separately for faster rebuilds
RUN mamba install --yes \
    'jupyter-server-proxy>=4.3.0' \
    'jupyterhub-singleuser' \
    'nodejs>=22'

# RUN pip install --no-cache-dir jupyter-remote-desktop-proxy
WORKDIR /opt/jupyter-remote-desktop-proxy
COPY --chown=$NB_UID:$NB_GID jupyter-remote-desktop-proxy /opt/jupyter-remote-desktop-proxy
RUN pip install --no-cache-dir .

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}
WORKDIR "${HOME}"

# Get rid ot the following message when you open a terminal in jupyterlab:
# groups: cannot find name for group ID 11320
RUN touch ${HOME}/.hushlogin

# Configure XFCE4
# - use single wokspace
COPY --chown=$NB_UID:$NB_GID configs/xfwm4.xml .config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml

# TurboVNC keyboard-layout workaround: without -noserverkeymap, the desktop
# ignores the client's actual host keyboard layout (e.g. German umlauts
# render as neighboring QWERTY keys). See configs/turbovncserver.conf.
RUN mkdir -p .vnc
COPY --chown=$NB_UID:$NB_GID configs/turbovncserver.conf .vnc/turbovncserver.conf

# Desktop icon for Chrome, reusing its own installed desktop entry instead of
# maintaining a second copy of it.
RUN mkdir -p Desktop \
 && cp /usr/share/applications/google-chrome.desktop Desktop/google-chrome.desktop \
 && chmod 755 Desktop/google-chrome.desktop

# Pre-trust every Desktop icon (see trust-desktop-icons) so xfce doesn't
# prompt "untrusted launcher" the first time one is double-clicked - runs on
# every session start since plugins/tools may add their own icons later.
RUN mkdir -p .config/autostart
COPY --chown=$NB_UID:$NB_GID configs/autostart.desktop .config/autostart/autostart.desktop
COPY --chown=$NB_UID:$NB_GID configs/trust-desktop-icons .config/autostart/trust-desktop-icons
RUN chmod 755 .config/autostart/autostart.desktop .config/autostart/trust-desktop-icons
