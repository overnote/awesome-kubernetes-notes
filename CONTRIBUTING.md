首先要学习安装
1. [Sphinx](https://www.sphinx-doc.org/en/master/usage/quickstart.html)
1. [Install MacPorts](https://guide.macports.org/chunked/installing.macports.html)

```bash
  brew install sphinx-doc
  echo 'export PATH="/usr/local/opt/sphinx-doc/bin:$PATH"' >> ~/.zshrc
```

编辑更新[awesome-kubernetes-notes.md](/source/awesome-kubernetes-notes.md)

```bash
# 重新编译HTML
make help html
```