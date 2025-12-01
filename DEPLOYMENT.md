# Deploying Smart Parking System to AWS Amplify

This guide covers how to deploy your Flutter Web application to AWS Amplify.

## Prerequisites

- An AWS Account.
- Your code pushed to a Git repository (GitHub, GitLab, or Bitbucket).

## 🔒 Security Warning: Public Repositories

**Since your repository is public, you cannot simply create a "private branch".** All branches in a public repository are visible to everyone.

To deploy securely without exposing your `amplifyconfiguration.dart`, choose one of the strategies below.

---

## Strategy 1: The "Private Mirror" (Recommended)

This creates a private copy of your repo specifically for deployment. This answers your need for a "private fork".

1.  **Create a new Private Repository** on GitHub (e.g., `smartparkingsystem-deploy`). Do not initialize it with README/gitignore.
2.  **Add the private remote** to your local project:
    ```bash
    git remote add deploy https://github.com/YOUR_USERNAME/smartparkingsystem-deploy.git
    ```
3.  **Push your code** to the private repo:
    ```bash
    git push deploy main
    ```
4.  **Commit the Config (Safe now)**:
    - Edit `.gitignore` to remove `lib/amplifyconfiguration.dart`.
    - Commit this change **ONLY** to the `deploy` remote (or a specific branch you push there).
    ```bash
    git add .gitignore lib/amplifyconfiguration.dart
    git commit -m "Add config for private deployment"
    git push deploy main
    ```
5.  **Deploy**: Connect AWS Amplify to this **private** repository (`smartparkingsystem-deploy`).

*To update later:* Pull changes from your public repo (`origin`), then push to your private repo (`deploy`).

---

## Strategy 2: Manual Zip Upload (No Git)

This avoids Git entirely for the deployment artifact.

1.  Build the web app locally:
    ```bash
    flutter build web
    ```
2.  Navigate to `build/web`.
3.  **Zip the contents** of the `web` folder (select all files inside `build/web` -> Right Click -> Compress/Zip).
4.  Go to [AWS Amplify Console](https://console.aws.amazon.com/amplify/home).
5.  Click **New App** -> **Host web app**.
6.  Select **Deploy without Git provider**.
7.  Upload your zip file.

---

## Strategy 3: Environment Variables (Advanced)

Keep the repo public but inject the configuration during the build.

1.  **Encode your config**: Convert your `amplifyconfiguration.dart` content into a single base64 string (to avoid special character issues).
2.  **Amplify Console**: Go to App settings -> **Environment variables**. Add `AMPLIFY_CONFIG_BASE64`.
3.  **Build Settings (`amplify.yml`)**:
    Add a command to decode and write the file before building.
    ```yaml
    frontend:
      phases:
        preBuild:
          commands:
            - flutter pub get
            - echo $AMPLIFY_CONFIG_BASE64 | base64 -d > lib/amplifyconfiguration.dart
    ```

---

## 🎓 AWS Learner Lab Specifics

If you are using an **AWS Academy Learner Lab** account, please note the following:

1.  **Region Restriction:** You MUST use `us-east-1` (N. Virginia) or `us-west-2` (Oregon). Other regions often fail.
2.  **Session Timeouts:** Your lab session (and thus your ability to manage the console) times out every 4 hours.
    *   *Good news:* Your deployed website **stays online** even when the session ends.
    *   *Good news:* Your resources (Cognito, Amplify App) persist between sessions.
3.  **Budget Cap:** You typically have a fixed budget (e.g., $100).
    *   Since Amplify hosting is free/cheap, this is fine.
    *   **Warning:** Be careful not to leave other expensive services running (like large EC2 instances or RDS databases) as they will drain your budget.
4.  **Account Expiry:** When your course ends, this AWS account and your website will be **deleted**. Do not use this for a permanent portfolio site unless you plan to migrate it later.

---

## 💰 Cost Estimates (Standard AWS Account)

For a typical small-to-medium website, AWS Amplify is often **free or very cheap**.

### 1. Amplify Hosting (Frontend)
*   **Free Tier (First 12 Months):**
    *   **Builds:** 1,000 build minutes/month (plenty for ~100-200 deployments).
    *   **Storage:** 5 GB stored.
    *   **Traffic:** 15 GB served/month.
*   **Pay-as-you-go (After 12 Months):**
    *   **Builds:** $0.01 per minute.
    *   **Storage:** $0.023 per GB/month.
    *   **Traffic:** $0.15 per GB served.

### 2. Amazon Cognito (Authentication)
*   **Free Tier (Always Free):**
    *   **50,000 Monthly Active Users (MAUs)** for direct sign-ins (email/password).
    *   This tier does **not** expire after 12 months.
*   **Pay-as-you-go:**
    *   $0.0055 per MAU after the first 50,000.

**Summary:** Unless you have thousands of daily users or huge video files, your monthly bill will likely be **$0.00**.

---

## Troubleshooting

- **White screen on load**: Check the browser console (F12). If you see 404 errors for `main.dart.js`, ensure your `<base href="...">` in `web/index.html` matches your Amplify URL path (usually `/` is fine).
