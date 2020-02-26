首先要学习安装
1. [Sphinx](https://www.sphinx-doc.org/en/master/contents.html)
1. [Install MacPorts](https://guide.macports.org/chunked/installing.macports.html)

```bash
  pip3 install sphinx_rtd_theme
  brew install sphinx-doc pandoc
  echo 'export PATH="/usr/local/opt/sphinx-doc/bin:$PATH"' >> ~/.zshrc
```

编辑/更新/添加 source 目录下面的 *.rst , *.md

```bash
# 重新编译HTML
make html
# 查看命令帮助
make help html
```

参考：
1. [](https://github.com/mathLab/PyGeM/issues/94)
1. [](https://www.jianshu.com/p/78e9e1b8553a)
1. []()
1. []()
1. []()