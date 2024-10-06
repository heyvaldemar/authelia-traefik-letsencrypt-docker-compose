# Authelia with Let's Encrypt Using Docker Compose

[![Deployment Verification](https://github.com/heyvaldemar/authelia-traefik-letsencrypt-docker-compose/actions/workflows/00-deployment-verification.yml/badge.svg)](https://github.com/heyvaldemar/authelia-traefik-letsencrypt-docker-compose/actions)

The badge displayed on my repository indicates the status of the deployment verification workflow as executed on the latest commit to the main branch.

**Passing**: This means the most recent commit has successfully passed all deployment checks, confirming that the Docker Compose setup functions correctly as designed.

📙 The complete installation guide is available on my [website](https://www.heyvaldemar.com/install-authelia-using-docker-compose/).

❗ Create secret for storing Authelia using the command:

`chmod +x generate-authelia-secrets.sh && ./generate-authelia-secrets.sh`

❗ Change variables in the `.env`, `config/configuration.yml`, and `config/users_database.yml` files to meet your requirements.

❗ Update the SMTP settings in `config/configuration.yml` to ensure Authelia functions properly. Authelia relies on these settings for sending email notifications for password resets, two-factor authentication setups, and more.

💡 Note that the `.env` file should be in the same directory as `authelia-traefik-letsencrypt-docker-compose.yml`.

Create networks for your services before deploying the configuration using the commands:

`docker network create traefik-network`

`docker network create authelia-network`

Deploy Authelia using Docker Compose:

`docker compose -f authelia-traefik-letsencrypt-docker-compose.yml -p authelia up -d`

# Enabling Authelia with Traefik

To integrate Authelia for authentication in your container services managed by Traefik, follow the steps below. This will ensure secure access by requiring authentication through Authelia.

## Step 1: Add Authelia Middleware

Add the following label to your container configuration to enable Authelia. Replace `your-router-name` with the name of your specific router:

`- "traefik.http.routers.your-router-name.middlewares=authelia@docker"`

### Example

If you are enabling Authelia on a service called "whoami", the label would look like this:

`- "traefik.http.routers.whoami.middlewares=authelia@docker"`

## Step 2: Adjust for Existing Middlewares

If your service already uses other middlewares, append `authelia@docker` to the existing list, separated by a comma:

`- "traefik.http.routers.your-router-name.middlewares=existing-middleware,authelia@docker"`

# Author

I’m Vladimir Mikhalev, the [Docker Captain](https://www.docker.com/captains/vladimir-mikhalev/), but my friends can call me Valdemar.

🌐 My [website](https://www.heyvaldemar.com/) with detailed IT guides\
🎬 Follow me on [YouTube](https://www.youtube.com/channel/UCf85kQ0u1sYTTTyKVpxrlyQ?sub_confirmation=1)\
🐦 Follow me on [Twitter](https://twitter.com/heyValdemar)\
🎨 Follow me on [Instagram](https://www.instagram.com/heyvaldemar/)\
🧵 Follow me on [Threads](https://www.threads.net/@heyvaldemar)\
🐘 Follow me on [Mastodon](https://mastodon.social/@heyvaldemar)\
🧊 Follow me on [Bluesky](https://bsky.app/profile/heyvaldemar.bsky.social)\
🎸 Follow me on [Facebook](https://www.facebook.com/heyValdemarFB/)\
🎥 Follow me on [TikTok](https://www.tiktok.com/@heyvaldemar)\
💻 Follow me on [LinkedIn](https://www.linkedin.com/in/heyvaldemar/)\
🐈 Follow me on [GitHub](https://github.com/heyvaldemar)

# Communication

👾 Chat with IT pros on [Discord](https://discord.gg/AJQGCCBcqf)\
📧 Reach me at ask@sre.gg

# Give Thanks

💎 Support on [GitHub](https://github.com/sponsors/heyValdemar)\
🏆 Support on [Patreon](https://www.patreon.com/heyValdemar)\
🥤 Support on [BuyMeaCoffee](https://www.buymeacoffee.com/heyValdemar)\
🍪 Support on [Ko-fi](https://ko-fi.com/heyValdemar)\
💖 Support on [PayPal](https://www.paypal.com/paypalme/heyValdemarCOM)
