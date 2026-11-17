# Production nginx: serves the Nuxt build's static files itself (/_nuxt bundles, favicons, brand files)
# so the Node server only renders HTML and resizes images (SRS ARC-03 SSR, ARC-07 Nuxt Image).
# Built by docker-compose.prod.yml with the frontend image as the `frontend` build context, so
# `docker compose build` always builds the frontend first.
FROM nginx:1.27.5-alpine
COPY --from=frontend /app/.output/public /usr/share/nginx/nuxt
# Cache dir for resized images (the ipx_cache volume copies this owner on first mount).
RUN mkdir -p /var/cache/nginx/ipx && chown nginx:nginx /var/cache/nginx/ipx
# Reload every 6 h so a certificate renewed by the certbot service is picked up (SRS §9 HTTPS).
CMD ["/bin/sh", "-c", "while :; do sleep 6h; nginx -s reload; done & exec nginx -g 'daemon off;'"]
