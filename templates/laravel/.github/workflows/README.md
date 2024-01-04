# Spin GitHub Actions Workflow Checklist
> [!WARNING]  
> 🤠 Hey Partner, there's some  manual steps you need to take care of before you'll get success with these workflows.

# 🚨 WARNING: You must set the following secrets in GitHub:

- DEPLOYMENT_SSH_PRIVATE_KEY
- DEPLOYMENT_SSH_HOSTNAME
- DB_ROOT_PASSWORD
- DB_NAME
- DB_USERNAME
- DB_PASSWORD
- ENV_FILE_BASE64

Ensure these secrets match the environment you're deploying to.
https://github.com/<your-organization>/<your-repo>/settings/environments

