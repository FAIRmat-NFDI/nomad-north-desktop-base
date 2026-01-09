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
