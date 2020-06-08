FROM jupyter/scipy-notebook:latest

USER root

RUN apt-get update && apt-get install -y htop neovim jq graphviz openssh-client inetutils-ping libnss3-tools

USER jovyan

    # Base image installs:

    # 'beautifulsoup4=4.9.*' \
    # 'conda-forge::blas=*=openblas' \
    # 'bokeh=2.0.*' \
    # 'bottleneck=1.3.*' \
    # 'cloudpickle=1.4.*' \
    # 'cython=0.29.*' \
    # 'dask=2.15.*' \
    # 'dill=0.3.*' \
    # 'h5py=2.10.*' \
    # 'hdf5=1.10.*' \
    # 'ipywidgets=7.5.*' \
    # 'ipympl=0.5.*'\
    # 'matplotlib-base=3.2.*' \
    # # numba update to 0.49 fails resolving deps.
    # 'numba=0.48.*' \
    # 'numexpr=2.7.*' \
    # 'pandas=1.0.*' \
    # 'patsy=0.5.*' \
    # 'protobuf=3.11.*' \
    # 'pytables=3.6.*' \
    # 'scikit-image=0.16.*' \
    # 'scikit-learn=0.22.*' \
    # 'scipy=1.4.*' \
    # 'seaborn=0.10.*' \
    # 'sqlalchemy=1.3.*' \
    # 'statsmodels=0.11.*' \
    # 'sympy=1.5.*' \
    # 'vincent=0.4.*' \
    # 'widgetsnbextension=3.5.*'\
    # 'xlrd=1.2.*' \

# Fix jupyterhub 1.x.y -> 1.1.0 because https://github.com/jupyterhub/zero-to-jupyterhub-k8s stable depends on it. 
RUN conda install -y jupyterhub \
    fastparquet pyarrow python-snappy \
    cvxopt cvxpy lxml line_profiler cookiecutter dash plotly gunicorn \
    pandas-profiling requests_ntlm distributed \
    conda-build pylint pytest portalocker

RUN conda install -c conda-forge pymc3 theano mkl-service \
    tqdm aiofiles aiohttp html5lib spacy python-graphviz dask-kubernetes s3fs \
    awscli zeep autopep8 rope blpapi zeep

RUN conda install -c pytorch pytorch=1.5 torchvision cpuonly

# Install cufflinks and jupyter plotly extension, requires jupyterlab=1.2 and ipywidgets=7.5
RUN pip install cufflinks==0.17.* chart_studio==1.1.0 impyute pydot \
    awscli-plugin-endpoint pydatastream

# Autocomplete for awz
RUN /bin/bash -c "complete -C aws_completer aws"

# Jupyter lab extensions
# Avoid "JavaScript heap out of memory" errors during extension installation
RUN export NODE_OPTIONS=--max-old-space-size=4096

# Install plotly for jupyterlab according to: https://github.com/plotly/plotly.py/blob/master/README.md
# ipywidgets is installed in base image.
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