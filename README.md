# EduHub 2.0 — The Learning Pulse

A Netlify-ready React + Vite starter application connected to Supabase. It includes role-based entry screens, a responsive dashboard UI, class creation and enrollment, lessons, one-question short-answer activities, grades, announcements, and parent-link workflows.

## Important status note

This is a **starter implementation**, not yet a school-ready production system. The core screens and several workflows are implemented, but some requested features still need development and security review before real student data is used. In particular:
- Student class-code enrollment and parent-child code validation currently happen in the browser before database writes. For production, move these operations into secure Postgres RPC functions or server-side functions so users cannot bypass code validation.
- Quiz correct answers are currently readable to authorized class members because the starter schema stores them in the activities table. For real assessments, move answer keys into a teacher-only table or server-side grading function.
- Parent dashboards need dedicated queries for linked children's grades, deadlines, achievements, and class data.
- Messaging currently accepts a recipient user ID and needs a recipient search plus relationship checks.
- Automatic notifications, multiple-choice questions, uploads, full gradebook controls, reporting/export, intervention workflows, and realtime updates are not complete.
- Review all RLS policies and test with separate role accounts before using real student records.

## Requirements

- Node.js 20 or newer
- A Supabase project
- A GitHub account (recommended)
- A Netlify account

## 1. Create Supabase project

1. Open https://supabase.com/dashboard and create a project.
2. In Supabase SQL Editor, run `supabase/schema.sql`.
3. In Authentication settings, configure email confirmation and the allowed redirect URLs.
4. Find the project URL and publishable/anon key in the project API/Connect settings.

## 2. Configure environment

Copy `.env.example` to `.env.local` and set the real values:

```env
VITE_SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Never put a service-role key or database password in frontend code. Vite environment variables prefixed with `VITE_` are exposed to the browser.

## 3. Run locally

```bash
npm install
npm run dev
```

Open the local URL shown by Vite.

## 4. Build

```bash
npm run build
```

The production files are generated in `dist/`.

## 5. Deploy to Netlify

1. Push this project to a GitHub repository.
2. Open https://app.netlify.com/ and choose **Add new project → Import an existing project**.
3. Select the GitHub repository.
4. Build command: `npm run build`
5. Publish directory: `dist`
6. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` under the site's environment variables.
7. Deploy the site.
8. Open the actual production URL assigned by Netlify.

The included `netlify.toml` configures Vite build settings and a single-page-app route fallback.

## 6. Authentication redirects

After deployment, add your Netlify production URL to Supabase Authentication URL configuration and allowed redirect URLs. Use the actual URL, for example `https://your-site-name.netlify.app/**`.

## 7. Before sharing

- Create a teacher test account.
- Create a class and verify the code.
- Create a student test account and join the class.
- Publish a lesson and a test activity.
- Submit a quiz and verify the saved grade.
- Test a parent account with a valid link code.
- Verify parents cannot edit grades or access unrelated students.
- Refresh and log back in to confirm data persistence.
- Test on a second device or private browser window.

Do not use real student data until security policies and all workflows have been independently reviewed and tested.
