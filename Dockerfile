FROM krallin/ubuntu-tini:16.04

MAINTAINER Matt Gardner <matt.w.gardner@gmail.com>

RUN apt-get -y update

RUN apt-get install -yq --no-install-recommends \
    wget \
    ca-certificates \
    bzip2 \
    build-essential \
    libsasl2-dev \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

# Add Tini
#ENV TINI_VERSION v0.14.0
#ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
#RUN chmod +x /tini

# Configure environment
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
ENV SHELL /bin/bash
ENV NB_USER matt 
ENV NB_UID 1000
ENV HOME /home/$NB_USER

# create nbuser with UID 1000 in the users group
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER $CONDA_DIR

USER $NB_USER


# Install conda
RUN cd /tmp && \
    mkdir -p $CONDA_DIR && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh && \ 
    echo "d573980fe3b5cdf80485add2466463f5 *Miniconda2-latest-Linux-x86_64.sh" | md5sum -c - && \
    /bin/bash Miniconda2-latest-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda2-latest-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda config --system --add channels conda-forge && \
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    conda clean -tipsy

# Install Jupyter Notebook
RUN conda install --quiet --yes \
    'notebook' \
    && conda clean -tipsy

USER root

EXPOSE 8888
WORKDIR /home/$NB_USER/work

# Configure container startup
#ENTRYPOINT ["tini", "--"]
CMD ["start-notebook.sh"]

# Add local files as late as possible to avoid cache busting
COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
#COPY start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /home/$NB_USER/.jupyter/
RUN chown -R $NB_USER:users /home/$NB_USER/.jupyter

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_USER
