build-deploy:
	yarn build && yarn deploy

serve:
	npx http-server ./public

watch-serve:
	yarn watch & npx http-server ./public