FROM jupyter/datascience-notebook:76402a27fd13

USER root

RUN apt-get update && apt-get install -y htop neovim jq graphviz openssh-client inetutils-ping libnss3-tools

USER jovyan

# Fix jupyterhub 1.x.y -> 1.1.0 because https://github.com/jupyterhub/zero-to-jupyterhub-k8s stable depends on it. 
RUN conda install -y jupyterhub=1.1.0 \
    fastparquet pyarrow python-snappy pandas=1 numpy=1 \
    cvxopt cvxpy lxml line_profiler cookiecutter dash=1 plotly=4 gunicorn \
    pandas-profiling requests_ntlm dask=2.17.2 distributed=2.17 \
    conda-build bottleneck pylint pytest portalocker h5py

RUN conda install pytorch=1.5 torchvision cpuonly -c pytorch
RUN conda install -c conda-forge nodejs=12 pymc3=3 theano mkl-service seaborn \
    tqdm aiofiles aiohttp html5lib spacy python-graphviz dask-kubernetes s3fs \
    awscli blpapi zeep autopep8 rope

# Install cufflinks and jupyter plotly extension, requires jupyterlab=1.2 and ipywidgets=7.5
RUN pip install cufflinks==0.17.* chart_studio==1.1.0 impyute pydot \
    awscli-plugin-endpoint pydatastream

# Autocomplete for awz
RUN /bin/bash -c "complete -C aws_completer aws"

# Jupyter lab extensions
# Avoid "JavaScript heap out of memory" errors during extension installation
RUN export NODE_OPTIONS=--max-old-space-size=4096

# Install plotly for jupyterlab according to: https://github.com/plotly/plotly.py/blob/master/README.md
RUN conda install jupyterlab "ipywidgets=7.5"

# Basic JupyterLab renderer support
RUN jupyter labextension install jupyterlab-plotly@4.8.1
# OPTIONAL: Jupyter widgets extension for FigureWidget support
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager plotlywidget@4.8.1

# Unset NODE_OPTIONS environment variable
RUN unset NODE_OPTIONS

RUN pip install jupyter-server-proxy && jupyter serverextension enable --sys-prefix jupyter_server_proxy

# Numpy multithreading uses MKL lib and for it to work properly on kubernetes
# this variable needs to be set. Else numpy thinks it has access to all cores on the node.
ENV MKL_THREADING_LAYER=GNU

# Allow insecure writes according to https://github.com/jupyter/docker-stacks/issues/963
# because otherwise we cannot mount jovyan home folder.
ENV JUPYTER_ALLOW_INSECURE_WRITES=true

CMD ["start.sh", "jupyter", "lab"]