# Weight Tracker – Vercel deploy folder

```
weight-tracker-vercel/
├── api/notion.js            Serverless proxy to Notion (token stays secret)
├── public/                  Flutter web build goes here (placeholder for now)
├── vercel.json              Serves public/, SPA rewrite so refresh doesn't 404
├── flutter_changes/         Replacement Dart files for your Flutter project
├── build_and_deploy.sh      Mac/Linux: build + copy + deploy
└── build_and_deploy.bat     Windows: build + copy + deploy
```

## 1. Update your Flutter code (one time)
Copy the 3 files from `flutter_changes/lib/services/` over the ones in your
project's `lib/services/` (notion_base.dart, notion_service.dart, notion_writes.dart).
The Notion token is no longer in the app.

## 2. Install and log in to Vercel (one time)
    npm i -g vercel
    vercel login

## 3. First deploy (creates the project)
From this folder:
    vercel
Answer the prompts (framework: Other, keep defaults). Then add secrets:
    vercel env add NOTION_TOKEN        (choose Production)
    vercel env add NOTION_DATABASE_ID  (choose Production)
    vercel env add APP_KEY             (optional, any long random string)

## 4. Build the Flutter app and deploy
Mac/Linux:
    APP_KEY=your-long-random-string ./build_and_deploy.sh /path/to/flutter_project
Windows:
    set APP_KEY=your-long-random-string
    build_and_deploy.bat C:\path\to\flutter_project

Skip APP_KEY on both sides if you don't want a shared key. If you set it, the
value in Vercel and the build must match.

## Troubleshooting
- 404 on the home page: public/ has no index.html (you deployed the placeholder
  removal, or the build was not copied). Re-run step 4.
- /api/notion 404: api/notion.js must sit next to vercel.json when you run `vercel`.
- "Server not configured": add NOTION_TOKEN / NOTION_DATABASE_ID to the
  Production environment, then redeploy with `vercel --prod`.
- Blank page: open browser console (F12) and check for errors.

## Notes
- Accounts/logins are still stored per browser (SharedPreferences), so they do
  not sync across devices. APP_KEY is visible in the built JavaScript, so it
  only deters casual visitors. Use a real backend for real security.
- Notion integration must be shared with your database (••• → Connections).
