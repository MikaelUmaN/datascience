FROM jupyter/datascience-notebook:7a0c7325e470

USER root
RUN apt-get update && apt-get install -y htop neovim jq graphviz

USER jovyan

# Lock jupyter client version because a bug for windows has been introduced in later versions.
# Restrict plotly version because we need it to be in sync with cufflinks.
# Degrade jupyterhub 1.0.0 -> 0.9.6 because https://github.com/jupyterhub/zero-to-jupyterhub-k8s stable depends on it.
RUN conda install -y jupyter_client=5.3.1 jupyterhub=0.9.6 \
    fastparquet pyarrow python-snappy pandas numpy=1 \
    cvxopt cvxpy lxml line_profiler cookiecutter dash=1 plotly=4 gunicorn \
    pandas-profiling requests_ntlm dask=2.9.0 distributed=2.9.0

RUN conda install -c conda-forge pymc3=3 theano mkl-service seaborn \
    tqdm aiofiles aiohttp html5lib spacy graphviz dask-kubernetes=0.10.0
RUN conda install -c r rpy2
RUN conda install -c pytorch pytorch-cpu=1 torchvision-cpu

# Install cufflinks and jupyter plotly extension, requires jupyterlab=1.2 and ipywidgets=7.5
RUN pip install cufflinks==0.17.0 chart_studio==1.0.0 impyute fancyimpute s3fs graphviz pydot

# Jupyter lab extensions
# Avoid "JavaScript heap out of memory" errors during extension installation
RUN export NODE_OPTIONS=--max-old-space-size=4096
# Jupyter widgets extension
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager@1.1 --no-build

# FigureWidget support
# and jupyterlab renderer support
RUN jupyter labextension install plotlywidget@1.4.0 --no-build
RUN jupyter labextension install jupyterlab-plotly@1.4.0 --no-build

RUN jupyter labextension install jupyterlab_vim --no-build

# Build extensions (must be done to activate extensions since --no-build is used above)
RUN jupyter lab build

# Unset NODE_OPTIONS environment variable
RUN unset NODE_OPTIONS

RUN pip install jupyter-server-proxy && jupyter serverextension enable --sys-prefix jupyter_server_proxy

# Numpy multithreading uses MKL lib and for it to work properly on kubernetes
# this variable needs to be set. Else numpy thinks it has access to all cores on the node.
ENV MKL_THREADING_LAYER=GNU

CMD ["start.sh", "jupyter", "lab"]