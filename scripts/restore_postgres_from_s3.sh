#!/usr/bin/env sh

set -ef
# set -x # Debug mode

# Sanity check
if [ -z "${POSTGRES_AWS_ACCESS_KEY_ID}" ]; then
    echo "You need to set the POSTGRES_AWS_ACCESS_KEY_ID environment variable."
    exit 1
else
    aws configure set aws_access_key_id ${POSTGRES_AWS_ACCESS_KEY_ID}
fi

if [ -z "${POSTGRES_AWS_SECRET_ACCESS_KEY}" ]; then
    echo "You need to set the POSTGRES_AWS_SECRET_ACCESS_KEY environment variable."
    exit 1
else
    aws configure set aws_secret_access_key ${POSTGRES_AWS_SECRET_ACCESS_KEY}
fi

if [ -z "${POSTGRES_AWS_S3_BUCKET}" ]; then
    echo "You need to set the POSTGRES_AWS_S3_BUCKET environment variable."
    exit 1
else
    aws configure set aws_s3_bucket ${POSTGRES_AWS_S3_BUCKET}
fi

if [ -z "${POSTGRES_AWS_DEFAULT_REGION}" ]; then
    echo "You need to set the POSTGRES_AWS_DEFAULT_REGION environment variable."
    exit 1
else
    aws configure set region ${POSTGRES_AWS_DEFAULT_REGION}
fi

if [ -z "${POSTGRES_AWS_S3_PATH}" ]; then
    echo "You need to set the POSTGRES_AWS_S3_PATH environment variable."
    exit 1
fi

if [ -z "${POSTGRES_AWS_S3_ENDPOINT}" ]; then
    AWS_EXTRA_OPTS=""
else
    AWS_EXTRA_OPTS="--endpoint-url ${POSTGRES_AWS_S3_ENDPOINT}"
fi

if [ "${POSTGRES_AWS_S3_S3V4}" = "yes" ]; then
    aws configure set default.s3.signature_version s3v4
fi

if [ -z "${POSTGRES_DB}" ]; then
    echo "You need to set the POSTGRES_DB environment variable."
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

# Prep environment
export PGPASSWORD=${POSTGRES_PASSWORD}
TMP_TARGET=/opt/docker/dump.sql.gz
LATEST_BACKUP=$(aws s3 ls s3://${POSTGRES_AWS_S3_BUCKET}${POSTGRES_AWS_S3_PATH} | sort | tail -n1 | awk '{print $4}')

# Execute restore
echo "Fetching ${LATEST_BACKUP} from ${POSTGRES_AWS_S3_BUCKET}"
aws \
    ${AWS_EXTRA_OPTS} \
    s3 cp s3://${POSTGRES_AWS_S3_BUCKET}${POSTGRES_AWS_S3_PATH}${LATEST_BACKUP} \
    ${TMP_TARGET} || exit 2

echo "Decompressing ${LATEST_BACKUP}"
gzip -df ${TMP_TARGET}

echo "Restoring ${LATEST_BACKUP}"
pg_restore \
    ${POSTGRES_EXTRA_OPTS} \
    -d ${POSTGRES_DB} \
    -h ${POSTGRES_HOST} \
    -p ${POSTGRES_PORT} \
    -U ${POSTGRES_USER} \
    ${TMP_TARGET//.gz/}

echo "SQL backup restored successfully"