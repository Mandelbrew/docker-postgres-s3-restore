#!/usr/bin/env sh

set -e

# Sanity check

if [ -z "${AWS_ACCESS_KEY_ID}" ]; then
	echo "You need to set the AWS_ACCESS_KEY_ID environment variable."
	exit 1
fi

if [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
	echo "You need to set the AWS_SECRET_ACCESS_KEY environment variable."
	exit 1
fi

if [ -z "${AWS_S3_BUCKET}" ]; then
	echo "You need to set the AWS_S3_BUCKET environment variable."
	exit 1
fi

if [ -z "${AWS_DEFAULT_REGION}" ]; then
	echo "You need to set the AWS_DEFAULT_REGION environment variable."
	exit 1
fi

if [ -z "${AWS_S3_PATH}" ]; then
	echo "You need to set the AWS_S3_PATH environment variable."
	exit 1
fi

if [ -z "${AWS_S3_ENDPOINT}" ]; then
	AWS_ARGS=""
else
	AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
fi

if [ "${AWS_S3_S3V4}" = "yes" ]; then
    aws configure set default.s3.signature_version s3v4
fi

if [ -z "${POSTGRES_DATABASE}" ]; then
	echo "You need to set the POSTGRES_DATABASE environment variable."
	exit 1
fi

if [ -z "${POSTGRES_HOST}" ]; then
	echo "You need to set the POSTGRES_HOST environment variable."
	exit 1
fi

if [ -z "${POSTGRES_PORT}" ]; then
	echo "You need to set the POSTGRES_PORT environment variable."
	exit 1
fi

if [ -z "${POSTGRES_USER}" ]; then
	echo "You need to set the POSTGRES_USER environment variable."
	exit 1
fi

if [ -z "${POSTGRES_PASSWORD}" ]; then
	echo "You need to set the POSTGRES_PASSWORD environment variable."
	exit 1
fi

# Prep env

export PGPASSWORD=$POSTGRES_PASSWORD
POSTGRES_HOST_OPTS="-h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_USER} -d ${POSTGRES_DATABASE} ${POSTGRES_EXTRA_OPTS}"
TMP_DUMP_FILE=/opt/docker/dump.sql.gz
LATEST_BACKUP=$(aws s3 ls s3://${AWS_S3_BUCKET}${AWS_S3_PATH} | sort | tail -n1 | awk '{print $4}')

# Do it

echo "Fetching ${LATEST_BACKUP} from ${AWS_S3_BUCKET}"
aws s3 cp s3://${AWS_S3_BUCKET}${AWS_S3_PATH}${LATEST_BACKUP} ${TMP_DUMP_FILE}

echo "Decompressing ${LATEST_BACKUP}"
gzip -d ${TMP_DUMP_FILE}

echo "Restoring ${LATEST_BACKUP}"
pg_restore ${POSTGRES_HOST_OPTS} ${TMP_DUMP_FILE//.gz/}

echo "SQL backup restored successfully"