

help:                ## Available make commands
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's~:~~' | sed -e 's~##~~'

usage: help         

lambda-package:               ## Package AWS lambda function
	@rm -f ./lambdas/update-cloudflare-dns.zip
	@cd ./lambdas/update-cloudflare-dns/package && zip -rq ../../update-cloudflare-dns.zip . && cd - 1>/dev/null
	@cd ./lambdas/update-cloudflare-dns && zip -g ../update-cloudflare-dns.zip ./main.py && cd - 1>/dev/null
	@ls -lh ./lambdas/update-cloudflare-dns.zip

# AWS_PAGER redirects to stdout instead of "default editor" (vim in my case)
lambda-upload-zip:            ## Upload ZIP to AWS lambda function
	export AWS_PAGER="" && \
		aws lambda update-function-code --output json \
			--function-name docker-cats-update-cloudflare-dns \
			--zip-file fileb://lambdas/update-cloudflare-dns.zip

lambda-package-upload: lambda-package lambda-upload-zip