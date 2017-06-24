FROM       postgres:alpine
MAINTAINER Carlos Avila "cavila@mandelbrew.com"

# Prep env
ENV        DEBIAN_FRONTEND=noninteractive \
    	   POSTGRES_DATABASE='' \
           POSTGRES_HOST='' \
           POSTGRES_PORT='' \
           POSTGRES_USER='' \
           POSTGRES_PASSWORD='' \
           POSTGRES_EXTRA_OPTS='--clean --if-exists' \
           AWS_ACCESS_KEY_ID='' \
           AWS_SECRET_ACCESS_KEY='' \
           AWS_S3_BUCKET='' \
           AWS_DEFAULT_REGION='' \
           AWS_S3_PATH='' \
           AWS_S3_ENDPOINT='' \
           AWS_S3_S3V4='' \
           CRON_TASK_1='1 0 * * * sh /opt/docker/restore_postgres_from_s3.sh'

# Operating System
RUN        apk update \
           && apk add --no-cache \
               python3 \
               curl \
           && pip3 install --no-cache-dir --upgrade pip setuptools wheel \
           && pip3 install --no-cache-dir \
               awscli

# Application
WORKDIR	   /opt/docker

ADD        scripts/restore_postgres_from_s3.sh restore_postgres_from_s3.sh
RUN        chmod +x restore_postgres_from_s3.sh

ADD        scripts/docker-cmd.sh docker-cmd.sh
RUN        chmod +x docker-cmd.sh

CMD        ["./docker-cmd.sh"]