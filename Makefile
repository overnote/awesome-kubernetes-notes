# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line, and also
# from the environment for the first two.
SPHINXOPTS    ?=
SPHINXBUILD   ?= sphinx-build
SOURCEDIR     = source
BUILDDIR      = build
IMAGE 		  = awesome-kubernetes-notes
now 		  := $(shell date)

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help Makefile

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

rebuild:
	# submodule 不能删除
	# rm -rf build/
	@$(SPHINXBUILD) -M html "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

docker: help 
	docker build -t $(IMAGE) .
	# docker run -it -p 8000:8000 --rm -v "$(pwd)/docs":/home/python/docs sphinx-autobuild
	# docker run -it -p 8000:8000 --rm -v "$(pwd)/source":/home/python/docs  -v "$(pwd)/build/html":/home/python/docs/_build/html $IMAGE
	# docker run -it -p 8000:8000 --rm -v "$(pwd)/build/html":/home/python/docs/_build/html $IMAGE
	docker run -it -p 8000:8000 --rm $(IMAGE)  

submodule_commit:
	cd "$(BUILDDIR)/html" && make

auto_commit:  rebuild submodule_commit
	git add .
	# 需要注意的是，每行命令在一个单独的shell中执行。这些Shell之间没有继承关系。
	git commit -am "$(now)"
	git push