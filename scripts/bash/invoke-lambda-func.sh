#!/usr/bin/env bash
aws lambda invoke --payload $1 --function-name $2 --cli-binary-format raw-in-base64-out outfile.json 