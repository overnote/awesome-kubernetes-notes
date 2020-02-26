# https://github.com/keimlink/docker-sphinx-doc
FROM keimlink/sphinx-doc:latest

COPY --chown=1000:1000 requirements.pip ./

RUN . .venv/bin/activate \
    # 中国特色社会主义
    && python -m pip install  -i https://pypi.tuna.tsinghua.edu.cn/simple --requirement requirements.pip

EXPOSE 8000
# COPY source /home/python/docs
COPY build/html /home/python/docs/_build/html
CMD ["sphinx-autobuild", "--host", "0.0.0.0", "--port", "8000", "/home/python/docs", "/home/python/docs/_build/html"]