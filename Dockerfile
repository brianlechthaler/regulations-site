#Start from latest compatible version of NodeJS.
#NB: The Debian Stretch Slim tag of the official NodeJS image was chosen to preserve compatibility with the rest of the Dockerfile while also keeping the image small.
FROM node:13.8.0-stretch-slim

#Set some environment variables for installing the Python3 pip dependency.
#PYTHON3= can be changed to any version of python availible from apt, though changing it may inadvertently break things.
ARG PYTHON3=3
ENV PIP_PACKAGE=python${PYTHON3}-pip \
    PIP_CMD=pip$PYTHON3 \
    PYTHON_CMD=python$PYTHON3

#Install necessary dependencies using apt-get, then python pip, then finally NodeJS NPM.
RUN apt-get update \
    && apt-get install -y $PIP_PACKAGE \
    && rm -rf /var/lib/apt/lists/*
RUN $PIP_CMD install --upgrade pip setuptools
RUN npm i -g npm
RUN npm install --quiet -g grunt-cli

#Copy necessary files from this repository into the container.
COPY ["manage.py", "package.json", "example-config.json", "setup.py", "frontendbuild.sh", "Gruntfile.js", ".babelrc", ".eslintignore", ".eslintrc", "/app/src/"]
COPY ["regulations", "/app/src/regulations"]
COPY ["fr_notices", "/app/src/fr_notices"]
COPY ["notice_comment", "/app/src/notice_comment"]
WORKDIR /app/src/
RUN ./frontendbuild.sh
RUN $PIP_CMD install --no-cache-dir -e .[notice_comment] \
    && $PYTHON_CMD manage.py migrate

#Start Python3 backend on port 8000.
ENV PYTHONUNBUFFERED="1"
EXPOSE 8000
CMD $PYTHON_CMD manage.py runserver 0.0.0.0:8000
