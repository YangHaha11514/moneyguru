#!/bin/bash

PYTHON=python3
ret=`$PYTHON -c "import sys; print(int(sys.version_info[:2] >= (3, 4)))"`
if [ $ret -ne 1 ]; then
    echo "Python 3.4+ required. Aborting."
    exit 1
fi

if [ -d "deps" ]; then
    # We have a collection of dependencies in our source package. We might as well use it instead
    # of downloading it from PyPI.
    PIPARGS="--no-index --find-links=deps"
fi

if [ ! -d "env" ]; then
    echo "No virtualenv. Creating one"
    # We need a "system-site-packages" env to have PyQt, but we also need to ensure a local pip
    # install. To achieve our latter goal, we start with a normal venv, which we later upgrade to
    # a system-site-packages once pip is installed.
    if ! $PYTHON -m venv env ; then
        # We're probably under braindead Ubuntu 14.04 which completely messed up ensurepip.
        # Work around it :(
        echo "Ubuntu 14.04's version of Python 3.4 is braindead stupid, but we work around it anyway..."
        $PYTHON -m venv --without-pip env
        ./env/bin/python get-pip.py $PIPARGS --force-reinstall
    fi
    if [ "$(uname)" != "Darwin" ]; then
        # We only need system site packages for PyQt, so under OS X, we don't enable it
        if ! $PYTHON -m venv env --upgrade --system-site-packages ; then
            # We're probably under v3.4.1 and experiencing http://bugs.python.org/issue21643
            # Work around it.
            echo "Oops, can't upgrade our venv. Trying to work around it."
            rm env/lib64
            $PYTHON -m venv env --upgrade --system-site-packages
        fi
    fi
fi

echo "Installing pip requirements"
if [ "$(uname)" == "Darwin" ]; then
    ./env/bin/pip install -r requirements-osx.txt
else
    ./env/bin/python -c "import PyQt4" >/dev/null 2>&1 || { echo >&2 "PyQt 4.8+ required. Install it and try again. Aborting"; exit 1; }
    ./env/bin/pip install $PIPARGS -r requirements.txt
fi

echo "Bootstrapping complete! You can now configure, build and run moneyGuru with:"
echo ". env/bin/activate && python configure.py && python build.py && python run.py"

