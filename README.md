# Stock Opname

Static web application for stock-opname reconciliation. GitHub Actions publishes it to GitHub Pages whenever a commit is pushed to `main`. Supabase provides staff authentication and shared team data.

## Publish with GitHub Pages

1. Create a GitHub repository and add this project to it.
2. Make sure the deployment workflow and `index.html` are committed on the `main` branch.
3. In the repository, open **Settings → Pages** and set **Build and deployment → Source** to **GitHub Actions**. This one-time setting must be enabled by a repository administrator.
4. Push a commit to `main`, or run **Deploy to GitHub Pages** from the repository's **Actions** tab.
5. Once the workflow succeeds, open the Pages URL shown in the deployment job (normally `https://<account>.github.io/<repository>/`).

The workflow packages only `index.html` for publishing. The spreadsheet parser is loaded from jsDelivr, so users need an internet connection to use workbook import/export features.

## Supabase authentication and shared data

The browser app uses the Supabase project URL and publishable key in `index.html`. A publishable key is intended for browser use; never put a Supabase secret or `service_role` key in this repository.

1. In Supabase **Authentication → Settings**, disable public sign-ups.
2. In **Authentication → URL Configuration**, set **Site URL** to `https://projectme-maz.github.io/gjm/` and add that same address under **Redirect URLs**.
3. In **SQL Editor → New query**, paste the contents of [`supabase-setup.sql`](./supabase-setup.sql), and click **Run**. This creates the shared-state table and a private username-to-email mapping table.
4. Install the [Supabase CLI](https://supabase.com/docs/guides/cli), then open a terminal in this project folder and run:

   ```powershell
   npx supabase login
   npx supabase link --project-ref kdeculjdbmhhhnqaonzb
   npx supabase functions deploy login-with-username --project-ref kdeculjdbmhhhnqaonzb
   ```

   The function uses Supabase's built-in server-side credentials. Never put a secret or `service_role` key in browser code or commit one to GitHub.

5. In **Authentication → Users**, use **Invite user** to invite your own email. The user follows the invitation email to set a password on the app.
6. Add a username mapping in **SQL Editor**. Replace the example username and email with the invited account's values, using lowercase:

   ```sql
   insert into public.stock_opname_usernames (username, email)
   values ('admin', 'your-email@example.com');
   ```

   Repeat the invite and mapping steps for each staff member. Usernames must be 3–30 characters and may contain lowercase letters, numbers, dots, underscores, and hyphens.

7. Open the deployed GitHub Pages URL and log in with the username and password you set from the invitation email.
8. The first successful login creates the shared workspace record. If this browser has existing locally saved app data, that data is used to initialize the shared record. Back up important data before setup.

Authenticated staff share one workspace dataset. Changes are saved to Supabase and other open sessions check for updates every eight seconds. Data is no longer limited to the local browser after the shared record has been initialized.

The SQL keeps username-to-email mappings private from browser users, does not grant database access to anonymous visitors, and does not allow authenticated users to delete the shared record. Anyone you invite can read and edit the shared stock-opname data; invite only trusted staff.
