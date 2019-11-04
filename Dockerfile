FROM jupyter/datascience-notebook:latest

USER root
RUN apt-get update && apt-get install -y htop neovim jq
USER jovyan

RUN conda install fastparquet pyarrow python-snappy pandas numpy

RUN pip install cufflinks==0.17.0 plotly==4.2.1 chart_studio==1.0.0 && \
    jupyter labextension install @jupyterlab/plotly-extension && \
    jupyter labextension install jupyterlab_vim

RUN conda install -c conda-forge pymc3 theano mkl-service seaborn tqdm

RUN conda install -c r rpy2

RUN conda install -y dask distributed

RUN conda install pytorch-cpu torchvision-cpu -c pytorch

# Restrict plotly version because we need it to be in sync with cufflinks.
RUN conda install cvxopt cvxpy lxml dash plotly==4.2.1 gunicorn line_profiler cookiecutter

RUN pip install pandas-profiling impyute fancyimpute requests_ntlm

ENV MKL_THREADING_LAYER=GNU

CMD ["start.sh", "jupyter", "lab"]